"""Offline facts for item presentation and Affliction enchant recommendations.

Only the existing gear catalog, its crafting recipes and explicitly selected enhancements
are bundled. Original response strings/attribution marks are retained, account metadata is not.
Published guide scores are a separate reference; they never feed client EP calculations.
"""
import datetime, hashlib, html, json, pathlib, re
try:
 from .catalog import ROOT, atomic, lua, secret_check
except ImportError:
 from catalog import ROOT, atomic, lua, secret_check
BASE='https://foreverdb.net'
GUIDE=BASE+'/bis/warlock/affliction'
SLOTS={'Head':[24164,22844], 'Neck':[1249057], 'Shoulders':[29467],
 'Back':[25084,20014], 'Chest':[1254966,20028], 'Wrists':[1220624,1217189],
 'Hands':[25073,13948,1254966], 'Waist':[], 'Legs':[24164,1254966],
 'Feet':[1254966], 'Ring1':[], 'Ring2':[], 'Trinket1':[], 'Trinket2':[],
 'MainHand':[22749,23804], 'OffHand':[1219577,1219579], 'Ranged':[]}
EXTRA_ENCHANTS={1248607}
ENCHANTS={n for rows in SLOTS.values() for n in rows}|EXTRA_ENCHANTS
SPELL_ENCHANTS={24164,22844,29467}
SLOT_NAMES={'Shoulder':'Shoulders','Wrist':'Wrists','Finger':'Ring1','Trinket':'Trinket1',
 'Main hand':'MainHand','Off hand':'OffHand','Ranged or relic':'Ranged'}

def catalog_ids():
 return {int(n) for n in re.findall(r'^    \[(\d+)\] = ',(ROOT/'Data'/'Affliction.lua').read_text(),re.M)}

def normalize(folder, guide_html, output, imported_at=None):
 folder=pathlib.Path(folder).resolve()
 if folder==ROOT or ROOT in folder.parents:raise ValueError('Keep private envelopes outside the addon')
 timestamp=imported_at or datetime.datetime.now(datetime.timezone.utc).isoformat()
 datetime.datetime.fromisoformat(timestamp.replace('Z','+00:00'))
 data={'schemaVersion':1,'items':{},'enhancements':{},'recipes':{},'provenance':{},
       'slotEnhancements':SLOTS,'recommendations':{},'profile':{'class':'WARLOCK','spec':'Affliction',
       'level':60,'activity':'PvE','sources':'all; may include raids','url':GUIDE},'coverage':{}}
 def read(path,endpoint):
  raw=path.read_bytes();e=json.loads(raw)
  if not isinstance(e,dict) or not isinstance(e.get('meta'),dict) or not isinstance(e.get('data'),dict):raise ValueError('Unexpected envelope: '+endpoint)
  meta=e['meta'];build=meta.get('build');credit=meta.get('attribution')
  if not isinstance(build,str) or not isinstance(credit,str) or BASE not in credit:raise ValueError('Missing build/attribution')
  source=path.stem
  data['provenance'][source]={'sourceName':'ForeverDB.net','sourceURL':BASE+'/api/v1/'+endpoint,
   'sourceBuild':build,'importedAt':timestamp,'sha256':hashlib.sha256(raw).hexdigest(),
   'attribution':credit,'creditURL':BASE,'evidenceType':'published_forever_api',
   'verifiedStatus':'publisher_reported_not_locally_verified'}
  return e['data'],source,build
 missing=[]
 for itemid in sorted(catalog_ids()):
  path=folder/('items-'+str(itemid)+'.json')
  if not path.exists():missing.append(itemid);continue
  row,source,build=read(path,'items/'+str(itemid))
  if row.get('id')!=itemid or not isinstance(row.get('name'),str) or not isinstance(row.get('stats'),list):raise ValueError('Invalid item identity/stats')
  item={k:row.get(k) for k in ('id','name','qualityId','itemLevel','requiredLevel','inventoryTypeId',
   'inventoryType','icon','bonding','unique','stats','effects','betaEvent','speculation','speculationReasons','dataFromBuild','liveClient')}
  item.update({'source':source,'build':row.get('dataFromBuild') or build,'requirementsCoverage':'partial'})
  data['items'][str(itemid)]=item
 # These three professions cover all crafted items currently in the gear list.
 # Only recipes making one of those IDs or a selected enchant are retained.
 for path in sorted(folder.glob('professions-*.json')):
  endpoint=path.stem.replace('professions-','professions/',1).replace('_','?',1).replace('_','&')
  e=json.loads(path.read_bytes());body=e.get('data',{})
  selected=[r for r in body.get('recipes',[]) if r.get('spellId') in ENCHANTS or (r.get('makes') or {}).get('itemId') in catalog_ids()]
  if not selected:continue
  body,source,build=read(path,endpoint)
  for r in selected:
   spellid=r.get('spellId')
   if type(spellid) is not int:raise ValueError('Recipe missing numeric spell ID')
   recipe={k:r.get(k) for k in ('spellId','name','icon','skill','requiredLevel','makes','effect','reagents',
    'tools','needsNearby','learnedFrom','newInForever','speculation','speculationReasons')}
   recipe.update({'profession':body['name'],'source':source,'build':build})
   if spellid in ENCHANTS:
    data['enhancements'][str(spellid)]={**recipe,'kind':'Armor kit' if spellid==1254966 else 'Enchant',
      'recommendationType':'utility' if spellid in (25084,20014) else 'offensive_reference'}
   else:
    itemid=(r.get('makes') or {})['itemId']
    data['recipes'].setdefault(str(itemid),[]).append(recipe)
 for spellid in SPELL_ENCHANTS:
  body,source,build=read(folder/('spells-'+str(spellid)+'.json'),'spells/'+str(spellid))
  if body.get('id')!=spellid:raise ValueError('Enhancement identity mismatch')
  data['enhancements'][str(spellid)]={'spellId':spellid,'name':body['name'],'icon':body['icon'],
    'effect':body['description'],'requiredLevel':body.get('requiredLevel'),
    'kind':'Arcanum' if spellid!=29467 else 'Shoulder inscription','source':source,'build':build,
    'learnedFrom':None,'reagents':None}
 # The kit's applicability lives on its consumable's use effect, not the crafting
 # spell. Keep the original effect (including source marks) and its provenance.
 body,source,build=read(folder/'items-252487.json','items/252487')
 effects=body.get('effects') or []
 if len(effects)!=1 or not isinstance(effects[0].get('text'),str):raise ValueError('Kit effect needs review')
 kit=data['enhancements']['1254966'];kit['effect']=effects[0]['text'];kit['effectSource']=source
 match=re.search(r'items level (\d+) and above',kit['effect'])
 if not match:raise ValueError('Kit target requirement changed')
 kit['targetMinItemLevel']=int(match[1]);kit['applicationItemId']=252487
 compact={24164:'+18 daño/sanación con hechizos · +1% golpe con hechizos',
  22844:'+8 daño/sanación con hechizos',29467:'+15 daño con hechizos · +1% crítico con hechizos',
  1254966:'+6 poder con hechizos · +40 armadura'}
 for spellid,effect in compact.items():data['enhancements'][str(spellid)]['shortEffect']=effect
 # Numeric facts from the public reference only; do not copy its guide prose or code.
 raw=pathlib.Path(guide_html).read_bytes();page=raw.decode()
 if 'Best in slot gear for Affliction Warlock at level 60 (PvE)' not in page:raise ValueError('Guide context changed; review level, class and activity')
 source='affliction-pve-reference'
 data['provenance'][source]={'sourceName':'ForeverDB.net','sourceURL':GUIDE,'sourceBuild':'page-context',
  'importedAt':timestamp,'sha256':hashlib.sha256(raw).hexdigest(),'creditURL':BASE,
  'evidenceType':'published_guide_reference','verifiedStatus':'publisher_recommendation_not_client_EP'}
 repeats={}
 for label,row in re.findall(r'<li><b>(.*?)</b>:(.*?)</li>',page,re.S):
  repeats[label]=repeats.get(label,0)+1;slot=SLOT_NAMES.get(label,label)
  if label in ('Finger','Trinket'):slot=slot[:-1]+str(repeats[label])
  match=re.search(r'<a href="/item/(\d+)"[^>]*>.*?</a>, score ([\d.]+):',row,re.S)
  if not match:raise ValueError('Published reference format changed')
  itemid=match[1];data['recommendations'][slot]={itemid:{'score':float(match[2]),'position':1,'source':source}}
  tail=row.split('Next best:',1)[-1] if 'Next best:' in row else ''
  for pos,m in enumerate(re.finditer(r'<a href="/item/(\d+)"[^>]*>.*?</a> \((?:−|-)\s*(\d+)% vs best\)',tail,re.S),2):
   data['recommendations'][slot][m[1]]={'behindPercent':int(m[2]),'position':pos,'source':source}
 absent=sorted(ENCHANTS-{int(n) for n in data['enhancements']})
 if absent:raise ValueError('Missing selected enhancements: '+str(absent))
 if len(data['recommendations'])!=17:raise ValueError('Expected 17 published slot references')
 data['coverage']={'catalogItems':len(catalog_ids()),'itemsImported':len(data['items']),
  'missingItemIds':missing,'requirements':'partial; level is not a full acquisition requirement set',
  'craftingItems':len(data['recipes']),'enhancements':len(data['enhancements']),
  'liveClientValidated':False,'ranking':'published guide context only; no player EP or DPS'}
 validate(data);atomic(output,json.dumps(data,ensure_ascii=False,indent=2)+'\n');return data['coverage']

def validate(data):
 secret_check(data)
 if data.get('schemaVersion')!=1:raise ValueError('Unknown guide schema')
 sources=data.get('provenance',{})
 for group in ('items','enhancements'):
  for key,row in data[group].items():
   if type(row.get('id' if group=='items' else 'spellId')) is not int or str(row.get('id' if group=='items' else 'spellId'))!=key:raise ValueError('Identity mismatch')
   if row.get('source') not in sources:raise ValueError('Missing source')
   if row.get('requiredLevel') is not None and (type(row['requiredLevel']) is not int or row['requiredLevel']<0):raise ValueError('Invalid required level')
 for rows in data['slotEnhancements'].values():
  if any(str(i) not in data['enhancements'] for i in rows):raise ValueError('Orphan enhancement')
 for key,rows in data['recipes'].items():
  for row in rows:
   if row.get('source') not in sources or (row.get('makes') or {}).get('itemId')!=int(key):raise ValueError('Invalid crafting source/identity')
 return data

def compile_guide(input_path=ROOT/'Catalog'/'item-guide.json',lua_path=ROOT/'Data'/'ItemGuide.lua',report_path=None):
 data=validate(json.loads(pathlib.Path(input_path).read_text()))
 digest=hashlib.sha256(json.dumps(data,sort_keys=True,ensure_ascii=False).encode()).hexdigest()
 atomic(lua_path,'-- Generated offline; publisher reference, not player EP. SHA256 '+digest+'\nFWC.Data.itemGuide='+lua(data)+'\n')
 if report_path:atomic(report_path,json.dumps({'sha256':digest,**data['coverage']},indent=2)+'\n')
 return digest
