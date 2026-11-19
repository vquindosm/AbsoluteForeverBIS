"""Minimal factual public-page import + authenticated API quarantine + offline compilation.
Run --help. Does not copy website code, guides or a bulk third-party database.
"""
import argparse,datetime,hashlib,html,json,os,pathlib,re,sys,urllib.request,urllib.error
sys.path.insert(0,str(pathlib.Path(__file__).resolve().parent/'data'))
from catalog import ROOT,atomic,compile_catalog,secret_check
BASE='https://foreverdb.net'
UA='ForeverCompanion-OfflineImporter/3.3.2 (+addon catalog research)'
class NoRedirect(urllib.request.HTTPRedirectHandler):
 def redirect_request(self,*args,**kwargs):return None

def fetch(url,key=None):
 if not url.startswith(BASE+'/'):raise ValueError('Only the reviewed ForeverDB host is supported')
 headers={'User-Agent':UA,'Accept':'application/json' if key else 'text/html'}
 if key:headers['X-API-Key']=key
 req=urllib.request.Request(url,headers=headers)
 try:
  with urllib.request.build_opener(NoRedirect()).open(req,timeout=30) as r:raw=r.read(4*1024*1024+1)
 except urllib.error.HTTPError as e:raise ValueError('HTTP '+str(e.code)+'; no credential or server body logged. Honor Retry-After before retrying.') from None
 if len(raw)>4*1024*1024:raise ValueError('Response too large for a single-record import')
 if key and key.encode() in raw:raise ValueError('Reflected credential refused')
 return raw

def field(value,source,known=True):return {'status':'KNOWN' if known else 'UNKNOWN','value':value if known else None,'provenance':[source]}
def text(raw):return html.unescape(re.sub('<[^>]+>',' ',raw.decode()))
def collect(out_dir):
 now=datetime.datetime.now(datetime.timezone.utc).isoformat();documents={};provenance={}
 for itemid in (272411,226404,18407,10019):
  url=BASE+'/item/'+str(itemid);raw=fetch(url);body=raw.decode()
  name=re.search(r'<h1[^>]*>(.*?)</h1>',body,re.S);build=re.search(r'client, build ([\d.]+), extracted',body)
  if not name or not build:raise ValueError('Public item format/build changed; review source, do not guess')
  source='fdb-item-'+str(itemid)
  provenance[source]={'sourceName':'ForeverDB.net','sourceURL':url,'sourceBuild':build[1],'importedAt':now,'evidenceType':'published_forever_client_page','verifiedStatus':'publisher_reported_not_locally_verified','redistributionBasis':'Minimal attributed factual transcription; no guides, site code or assets copied','sha256':hashlib.sha256(raw).hexdigest()}
  lists=re.findall(r'<li>(.*?)</li>',body,re.S);rows=[html.unescape(re.sub('<[^>]+>','',x)).strip() for x in lists]
  documents[itemid]={'name':html.unescape(re.sub('<[^>]+>','',name[1])),'rows':rows,'text':text(raw),'source':source,'build':build[1]}
 cloak=documents[272411];token=documents[226404]
 if cloak['name']!='Arcanoweave Cloak' or token['name']!='Tarnished Undermine Real':raise ValueError('Identity changed')
 offer=next((x for x in cloak['rows'] if x.startswith('Pix Xizzix,') and 'seen in WoW Forever' in x),None)
 m=re.fullmatch(r'Pix Xizzix, (.*?) \((.*?)\): (\d+) Tarnished Undermine Real \(seen in WoW Forever\)',offer or '')
 if not m:raise ValueError('Offer unavailable or format changed')
 src=cloak['source'];qty=int(m[3]);data={'schemaVersion':1,'provenance':provenance,'items':{},'vendors':{},'vendorOffers':{},'recipes':{},'quests':{},'acquisitions':{},'coverage':{}}
 # NPC ID/coordinates are deliberately UNKNOWN here: the item page doesn't publish them.
 # The stable vendor key is a source identity until a recorded NPC GUID verifies npcId.
 vendor_key='pix-xizzix';data['vendors'][vendor_key]={'vendorKey':vendor_key,'npcId':field(None,src,False),'name':field('Pix Xizzix',src),'faction':field(m[2],src),'zone':field(m[1],src),'coordinates':field(None,src,False),'inventory':['pix:272411'],'provenance':[src]}
 statnames={'Armor':('RESISTANCE0_NAME','armor'),'Intellect':('ITEM_MOD_INTELLECT_SHORT','points'),'Spirit':('ITEM_MOD_SPIRIT_SHORT','points'),'Stamina':('ITEM_MOD_STAMINA_SHORT','points'),'Spell Power':('ITEM_MOD_SPELL_POWER_SHORT','spell_power'),'Hit':(None,'unknown'),'Shadow Damage':('ITEM_MOD_DAMAGE_SHADOW_SHORT','spell_damage'),'Shadow Damage Done':('ITEM_MOD_DAMAGE_SHADOW_SHORT','spell_damage')}
 for itemid,doc in documents.items():
  stats={};source=doc['source']
  for row in doc['rows']:
   sm=re.fullmatch(r'\+?(\d+) (Armor|Intellect|Spirit|Stamina|Spell Power|Hit|Shadow Damage Done|Shadow Damage)',row)
   if sm:
    statkey,unit=statnames[sm[2]];stats[sm[2]]={'value':int(sm[1]),'statKey':statkey,'unit':unit,'provenance':[source]}
  level=next((int(re.search(r'\d+',r)[0]) for r in doc['rows'] if re.fullmatch(r'Requires level \d+',r)),None)
  slot=next((r[6:] for r in doc['rows'] if r.startswith('Slot: ')),None)
  data['items'][str(itemid)]={'itemId':itemid,'name':field(doc['name'],source),'quality':field(None,source,False),'slot':field(slot,source,slot is not None),'requiredLevel':field(level,source,level is not None),'stats':stats,'effects':field(None,source,False),'equipRestrictions':field(None,source,False),'buildVersion':doc['build'],'statsCoverage':'partial','sourceConfidence':'publisher_reported','provenance':[source]}
 data['vendorOffers']['pix:272411']={'offerId':'pix:272411','vendorId':vendor_key,'itemId':272411,'requiredReputationFaction':field(None,src,False),'requiredReputationRank':field(None,src,False),'goldCostCopper':field(None,src,False),'additionalCurrencies':field([{'kind':'item','itemId':226404,'name':token['name'],'quantity':qty,'provenance':[src,token['source']]}],src),'requiredItems':field(None,src,False),'stockLimit':field(None,src,False),'availabilityStatus':field('seen_in_forever',src),'questPrerequisites':field(None,src,False),'requirementsComplete':False,'provenance':[src]}
 data['acquisitions']['vendor:272411:pix']={'acquisitionId':'vendor:272411:pix','itemId':272411,'type':'Vendor','sourceId':'pix:272411','conditions':{'op':'ALL','children':[{'op':'QUANTITY','metric':'level','amount':data['items']['272411']['requiredLevel']['value']},{'op':'QUANTITY','metric':'item','itemId':226404,'amount':qty,'name':token['name'],'role':'purchase_cost'},{'op':'UNKNOWN','reason':'Gold, reputation, quest prerequisites and stock are not fully published; inspect the vendor.'}]},'confidence':'published_forever_observation_partial_requirements','provenance':[src]}
 professions=['Alchemy','Blacksmithing','Enchanting','Engineering','Leatherworking','Tailoring','Herbalism','Mining','Skinning','Cooking','First Aid','Fishing']
 data['coverage']={'professions':{p:{'imported':0,'status':'NOT_IMPORTED'} for p in professions},'quests':{'imported':0,'status':'NOT_IMPORTED'},'vendorSlice':{'offers':1,'requirementsComplete':False,'liveClientValidated':False},'stats':{'items':4,'status':'PARTIAL; units/effects/build must be checked'}}
 out=pathlib.Path(out_dir);atomic(out/'public-vendor-slice.json',json.dumps(data,ensure_ascii=False,indent=2)+'\n')
 return out/'public-vendor-slice.json'

def main():
 ap=argparse.ArgumentParser();sub=ap.add_subparsers(dest='command',required=True)
 p=sub.add_parser('public-slice');p.add_argument('--out-dir',default=str(ROOT/'Catalog'))
 p=sub.add_parser('fetch-api');p.add_argument('endpoint');p.add_argument('--out-dir',required=True)
 p=sub.add_parser('compile');p.add_argument('input');p.add_argument('--lua',default=str(ROOT/'Data'/'Foundation.lua'));p.add_argument('--sqlite',required=True);p.add_argument('--report',default=str(ROOT/'docs'/'DATA_COVERAGE.json'))
 args=ap.parse_args()
 if args.command=='public-slice':print('Imported minimal factual slice:',collect(args.out_dir))
 elif args.command=='fetch-api':
  if not re.fullmatch(r'(items|vendors|quests)/\d+|professions(?:/[a-z-]+)?|dungeons|merchants-favor|classes/[a-z]+',args.endpoint):raise ValueError('Endpoint not allowlisted; bulk import gated')
  key=os.environ.get('FOREVERDB_API_KEY')
  if not key:raise ValueError('Configure FOREVERDB_API_KEY outside the addon; do not paste or ship it')
  out=pathlib.Path(args.out_dir).resolve()
  if out==ROOT or ROOT in out.parents:raise ValueError('Quarantine API responses outside the distributable addon')
  data=json.loads(fetch(BASE+'/api/v1/'+args.endpoint,key));secret_check(data)
  if not isinstance(data,dict) or 'data' not in data or 'meta' not in data:raise ValueError('Unexpected response envelope')
  atomic(out/(args.endpoint.replace('/','-')+'.json'),json.dumps(data,ensure_ascii=False,indent=2)+'\n')
  print('Authenticated response quarantined. Review field mappings/confidence before compilation; key not stored.')
 else:print(json.dumps(compile_catalog(args.input,args.lua,args.sqlite,args.report),indent=2))
if __name__=='__main__':
 try:main()
 except (ValueError,OSError,json.JSONDecodeError) as e:sys.exit(str(e))
