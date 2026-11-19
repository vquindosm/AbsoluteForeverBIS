"""Offline catalog compiler. No network or credentials are used by compile()."""
import hashlib,json,math,pathlib,re,sqlite3,tempfile,os
ROOT=pathlib.Path(__file__).resolve().parents[2]
COLLECTIONS={'items':'itemId','vendors':'vendorKey','vendorOffers':'offerId','recipes':'spellId','quests':'questId','acquisitions':'acquisitionId'}
PROVENANCE=('sourceName','sourceURL','sourceBuild','importedAt','evidenceType','verifiedStatus')
def load(path): return json.loads(pathlib.Path(path).read_text())
def secret_check(data):
 text=json.dumps(data,ensure_ascii=False)
 if re.search(r'fdb_[A-Za-z0-9_-]{16,}',text):raise ValueError('Possible credential in catalog')
 def walk(v):
  if isinstance(v,dict):
   for k,x in v.items():
    if k.lower().replace('_','') in ('apikey','authorization','password','secret','accesstoken'):raise ValueError('Credential field forbidden')
    walk(x)
  elif isinstance(v,list):
   for x in v:walk(x)
  elif isinstance(v,float) and not math.isfinite(v):raise ValueError('Non-finite number')
 walk(data)
def validate(data):
 secret_check(data)
 try:
  import jsonschema
 except ImportError:raise ValueError('Install build dependencies: python3 -m pip install -r tools/data/requirements.txt') from None
 try:jsonschema.Draft202012Validator(load(ROOT/'Catalog'/'schema.json')).validate(data)
 except jsonschema.ValidationError as e:raise ValueError('Schema validation: '+e.message) from None
 if data.get('schemaVersion')!=1:raise ValueError('Unsupported schemaVersion')
 sources=data.get('provenance',{})
 for key,source in sources.items():
  if any(k not in source for k in PROVENANCE):raise ValueError('Incomplete provenance: '+key)
  if not source['sourceURL'].startswith('https://'):raise ValueError('Source URL must use HTTPS')
  if not source.get('redistributionBasis'):raise ValueError('Redistribution must be reviewed')
 def field(v):
  if isinstance(v,dict):
   if isinstance(v.get('provenance'),list) and (not v['provenance'] or any(p not in sources for p in v['provenance'])):raise ValueError('Unknown provenance reference')
   if 'status' in v and 'value' in v:
    if v['status'] not in ('KNOWN','UNKNOWN','LEGACY','APPROXIMATE'):raise ValueError('Invalid field status')
    if v['status']=='KNOWN' and v.get('value') is None:raise ValueError('Known null is forbidden')
    if v['status']=='UNKNOWN' and v.get('value') is not None:raise ValueError('Unknown field has invented value')
    if not v.get('provenance') or any(p not in sources for p in v['provenance']):raise ValueError('Missing field provenance')
   for x in v.values():field(x)
  elif isinstance(v,list):
   for x in v:field(x)
 field(data)
 for collection,idkey in COLLECTIONS.items():
  rows=data.get(collection,{})
  if not isinstance(rows,dict):raise ValueError('Collections must be indexed maps')
  for key,row in rows.items():
   if str(row.get(idkey))!=key:raise ValueError('Identity mismatch in '+collection)
   if not row.get('provenance') or any(p not in sources for p in row['provenance']):raise ValueError('Entity provenance required')
 for row in data['vendorOffers'].values():
  if str(row['vendorId']) not in data['vendors'] or str(row['itemId']) not in data['items']:raise ValueError('Orphan vendor offer')
  for name in ('goldCostCopper','additionalCurrencies','requiredItems','requiredReputationFaction','requiredReputationRank','stockLimit','availabilityStatus'):
   if name not in row:raise ValueError('Missing explicit offer field: '+name)
  if row.get('requirementsComplete') and any(row[name]['status']!='KNOWN' for name in ('goldCostCopper','additionalCurrencies','requiredItems','requiredReputationFaction','requiredReputationRank','stockLimit')):raise ValueError('Complete coverage contradicts unknown fields')
  price=row['goldCostCopper']
  if price['status']=='KNOWN' and (type(price['value']) is not int or price['value']<0):raise ValueError('Price must be copper integer')
  for cost in row['additionalCurrencies'].get('value') or []:
   if type(cost.get('quantity')) is not int or cost['quantity']<=0:raise ValueError('Invalid currency quantity')
   if cost.get('kind') not in ('item','currency'):raise ValueError('Currency identity kind required')
   if type(cost.get('itemId') if cost['kind']=='item' else cost.get('currencyId')) is not int:raise ValueError('Cost identity missing')
 for row in data['acquisitions'].values():
  if str(row['itemId']) not in data['items']:raise ValueError('Orphan acquisition item')
  if row['type']=='Vendor' and row['sourceId'] not in data['vendorOffers']:raise ValueError('Orphan acquisition offer')
 return data

def lua(value):
 if value is None:return 'nil'
 if value is True:return 'true'
 if value is False:return 'false'
 if isinstance(value,(int,float)):return str(value)
 if isinstance(value,str):
  return '"'+value.replace('\\','\\\\').replace('"','\\"').replace('\n','\\n').replace('\r','\\r').replace('\t','\\t')+'"'
 if isinstance(value,list):return '{'+','.join(lua(v) for v in value)+'}'
 if isinstance(value,dict):
  parts=[]
  for k,v in sorted(value.items()):
   key=int(k) if k.isdecimal() and str(int(k))==k else k
   parts.append('['+lua(key)+']='+lua(v))
  return '{'+','.join(parts)+'}'
 raise ValueError('Unsupported value')
def atomic(path,content):
 path=pathlib.Path(path);path.parent.mkdir(parents=True,exist_ok=True)
 fd,name=tempfile.mkstemp(dir=path.parent)
 try:
  with os.fdopen(fd,'w') as f:f.write(content)
  os.replace(name,path)
 finally:
  if os.path.exists(name):os.unlink(name)
def compile_catalog(input_path,lua_path,sqlite_path,report_path):
 data=validate(load(input_path));encoded=json.dumps(data,sort_keys=True,ensure_ascii=False,separators=(',',':')).encode();digest=hashlib.sha256(encoded).hexdigest()
 output='-- Generated offline; do not edit. SHA256 '+digest+'\nFWC.Data.foundation='+lua(data)+'\n'
 sqlite_path=pathlib.Path(sqlite_path);sqlite_path.parent.mkdir(parents=True,exist_ok=True)
 tmp=sqlite_path.with_suffix('.tmp');tmp.unlink(missing_ok=True)
 with sqlite3.connect(tmp) as db:
  db.execute('PRAGMA foreign_keys=ON');db.execute('CREATE TABLE provenance (id TEXT PRIMARY KEY, record TEXT NOT NULL)')
  db.executemany('INSERT INTO provenance VALUES (?,?)',[(k,json.dumps(v,sort_keys=True)) for k,v in data['provenance'].items()])
  for name in COLLECTIONS:
   if name=='vendorOffers':
    db.execute('CREATE TABLE vendorOffers (id TEXT PRIMARY KEY,vendorId TEXT NOT NULL REFERENCES vendors(id),itemId TEXT NOT NULL REFERENCES items(id),record TEXT NOT NULL)')
    db.executemany('INSERT INTO vendorOffers VALUES (?,?,?,?)',[(k,str(v['vendorId']),str(v['itemId']),json.dumps(v,sort_keys=True)) for k,v in data[name].items()])
   elif name=='acquisitions':
    db.execute('CREATE TABLE acquisitions (id TEXT PRIMARY KEY,itemId TEXT NOT NULL REFERENCES items(id),type TEXT NOT NULL,sourceId TEXT,record TEXT NOT NULL)')
    db.executemany('INSERT INTO acquisitions VALUES (?,?,?,?,?)',[(k,str(v['itemId']),v['type'],str(v['sourceId']),json.dumps(v,sort_keys=True)) for k,v in data[name].items()])
   else:
    db.execute('CREATE TABLE '+name+' (id TEXT PRIMARY KEY, record TEXT NOT NULL)')
    db.executemany('INSERT INTO '+name+' VALUES (?,?)',[(k,json.dumps(v,sort_keys=True)) for k,v in data[name].items()])
  db.execute('CREATE TABLE manifest (schemaVersion INTEGER,sha256 TEXT)');db.execute('INSERT INTO manifest VALUES (?,?)',(1,digest))
 os.replace(tmp,sqlite_path)
 report={'schemaVersion':1,'sha256':digest,'scope':'single vendor slice; no mass import','entities':{k:len(data[k]) for k in COLLECTIONS},'coverage':data['coverage']}
 atomic(lua_path,output);atomic(report_path,json.dumps(report,ensure_ascii=False,indent=2)+'\n')
 return report
