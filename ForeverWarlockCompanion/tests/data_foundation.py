"""Offline real-record tests; no network, credentials or live game are required."""
import copy,json,pathlib,sqlite3,subprocess,sys,tempfile,unittest
ROOT=pathlib.Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'tools'/'data'))
from catalog import load,validate,compile_catalog,lua,secret_check
class CatalogTest(unittest.TestCase):
 @classmethod
 def setUpClass(cls):cls.data=load(ROOT/'Catalog'/'public-vendor-slice.json')
 def test_real_slice(self):
  d=validate(self.data);o=d['vendorOffers']['pix:272411']
  self.assertEqual(d['items']['272411']['name']['value'],'Arcanoweave Cloak')
  self.assertEqual(o['additionalCurrencies']['value'][0]['quantity'],75)
  self.assertEqual(o['additionalCurrencies']['value'][0]['itemId'],226404)
  self.assertEqual(o['goldCostCopper'],{'status':'UNKNOWN','value':None,'provenance':['fdb-item-272411']})
 def test_gloves_records(self):
  d=self.data['items'];self.assertEqual(d['18407']['stats']['Shadow Damage Done']['value'],33)
  self.assertEqual(d['10019']['stats']['Spell Power']['value'],18)
 def test_units_not_guessed(self):
  hit=self.data['items']['272411']['stats']['Hit'];self.assertEqual(hit['unit'],'unknown');self.assertIsNone(hit['statKey']);self.assertEqual(hit['value'],10)
 def test_fake_numeric_identity_refused(self):
  d=copy.deepcopy(self.data);d['vendors']['pix-xizzix']['npcId']={'status':'KNOWN','value':'pix-xizzix','provenance':['fdb-item-272411']}
  with self.assertRaises(ValueError):validate(d)
 def test_identity_not_invented(self):
  v=self.data['vendors']['pix-xizzix'];self.assertEqual(v['npcId']['status'],'UNKNOWN');self.assertIsNone(v['npcId']['value'])
 def test_unknown_not_zero(self):
  d=copy.deepcopy(self.data);d['vendorOffers']['pix:272411']['goldCostCopper']['value']=0
  with self.assertRaises(ValueError):validate(d)
 def test_orphan(self):
  d=copy.deepcopy(self.data);d['vendorOffers']['pix:272411']['vendorId']='not-real'
  with self.assertRaises(ValueError):validate(d)
 def test_complete_claim_refused(self):
  d=copy.deepcopy(self.data);d['vendorOffers']['pix:272411']['requirementsComplete']=True
  with self.assertRaises(ValueError):validate(d)
 def test_no_provenance(self):
  d=copy.deepcopy(self.data);d['provenance']['fdb-item-272411'].pop('sourceBuild')
  with self.assertRaises(ValueError):validate(d)
 def test_unknown_currency_identity(self):
  d=copy.deepcopy(self.data);d['vendorOffers']['pix:272411']['additionalCurrencies']['value'][0].pop('itemId')
  with self.assertRaises(ValueError):validate(d)
 def test_no_credential(self):
  with self.assertRaises(ValueError):secret_check({'X':'fdb_'+'a'*20})
  with self.assertRaises(ValueError):secret_check({'api_key':'test-only-placeholder'})
 def test_no_nan(self):
  with self.assertRaises(ValueError):secret_check({'x':float('nan')})
 def test_compile_reproducible_and_relational(self):
  with tempfile.TemporaryDirectory() as tmp:
   tmp=pathlib.Path(tmp);a=tmp/'one.lua';b=tmp/'two.lua';db=tmp/'catalog.sqlite';report=tmp/'coverage.json'
   source=ROOT/'Catalog'/'public-vendor-slice.json';compile_catalog(source,a,db,report);compile_catalog(source,b,db,report)
   self.assertEqual(a.read_bytes(),b.read_bytes());self.assertEqual(a.read_bytes(),(ROOT/'tests'/'fixtures'/'public_foundation.lua').read_bytes())
   with sqlite3.connect(db) as sql:
    rows=sql.execute("SELECT json_extract(i.record,'$.name.value'),json_extract(o.record,'$.goldCostCopper.value') FROM items i JOIN vendorOffers o ON i.id=o.itemId").fetchall()
    self.assertEqual(rows,[('Arcanoweave Cloak',None)]);self.assertEqual(sql.execute('PRAGMA foreign_key_check').fetchall(),[])
   self.assertFalse(json.loads(report.read_text())['coverage']['vendorSlice']['liveClientValidated'])
 def test_mass_import_not_claimed(self):
  c=self.data['coverage'];self.assertEqual(len(c['professions']),12);self.assertTrue(all(p['imported']==0 for p in c['professions'].values()));self.assertFalse(c['vendorSlice']['requirementsComplete'])
 def test_no_faction_reputation_inference(self):
  o=self.data['vendorOffers']['pix:272411'];self.assertEqual(o['requiredReputationFaction']['status'],'UNKNOWN')
 def test_lua_escaping(self):self.assertEqual(lua('a"b\nc'), '"a\\"b\\nc"')
 def test_missing_key_is_safe(self):
  import os
  env=dict(os.environ);env.pop('FOREVERDB_API_KEY',None)
  r=subprocess.run([sys.executable,str(ROOT/'tools'/'import_foundation.py'),'fetch-api','items/272411','--out-dir','/tmp/fwc-api-quarantine'],env=env,capture_output=True,text=True)
  self.assertNotEqual(r.returncode,0);self.assertIn('Configure FOREVERDB_API_KEY',r.stderr)
class AuthenticatedCatalogTest(unittest.TestCase):
 @classmethod
 def setUpClass(cls):cls.data=load(ROOT/'Catalog'/'api-vendor-slice.json')
 def test_real_authenticated_offer(self):
  d=validate(self.data);o=d['vendorOffers']['pix:272411'];v=d['vendors']['pix-xizzix']
  self.assertEqual(o['additionalCurrencies']['value'][0]['currencyId'],3469)
  self.assertEqual(o['additionalCurrencies']['value'][0]['kind'],'currency')
  self.assertEqual(o['additionalCurrencies']['value'][0]['quantity'],75)
  self.assertEqual(o['goldCostCopper']['value'],0)
  self.assertEqual(o['requiredItems']['value'],[])
  self.assertEqual(v['npcId']['value'],227853)
  self.assertEqual(v['coordinates']['value'],{'x':28.5,'y':75.8,'mapId':1434})
  self.assertEqual(o['stockLimit']['value'],'unlimited_published')
  self.assertEqual(o['requiredReputationFaction']['status'],'UNKNOWN')
  self.assertEqual(o['questPrerequisites']['status'],'UNKNOWN')
  self.assertFalse(o['requirementsComplete'])
 def test_stats_and_attribution(self):
  d=self.data
  self.assertEqual(d['items']['18407']['stats']['Shadow Damage Done']['value'],33)
  self.assertEqual(d['items']['10019']['stats']['Spell Power']['value'],18)
  hit=d['items']['272411']['stats']['Hit']
  self.assertEqual(hit['statId'],31);self.assertEqual(hit['unit'],'unknown');self.assertIsNone(hit['statKey'])
  self.assertNotIn('Armor',d['items']['272411']['stats']) # omitted by API, never filled with 0
  for p in d['provenance'].values():
   self.assertEqual(p['evidenceType'],'published_forever_api')
   self.assertIn('https://foreverdb.net',p['attribution'])
   self.assertEqual(p['creditURL'],'https://foreverdb.net')
   self.assertEqual(len(p['sha256']),64)
 def test_runtime_reproducible(self):
  with tempfile.TemporaryDirectory() as tmp:
   p=pathlib.Path(tmp);compile_catalog(ROOT/'Catalog'/'api-vendor-slice.json',p/'out.lua',p/'out.sqlite',p/'out.json')
   self.assertEqual((p/'out.lua').read_bytes(),(ROOT/'Data'/'Foundation.lua').read_bytes())
   self.assertEqual((p/'out.sqlite').read_bytes(),(ROOT/'Catalog'/'foundation.sqlite').read_bytes())
 def test_package_refuses_private_files_and_credentials(self):
  import shutil
  with tempfile.TemporaryDirectory() as tmp:
   p=pathlib.Path(tmp);addon=p/'addon'
   shutil.copytree(ROOT/'tools',addon/'tools',ignore=shutil.ignore_patterns('__pycache__'))
   shutil.copytree(ROOT/'Catalog',addon/'Catalog')
   dest=p/'release.zip';dest.write_bytes(b'previous release remains intact')
   for name,content in [('.env.test','test only'),('accidental.txt','fdb_'+'x'*20)]:
    with self.subTest(name=name):
     private=addon/name;private.write_text(content)
     r=subprocess.run([sys.executable,str(addon/'tools'/'build_zip.py'),str(dest)],capture_output=True,text=True)
     self.assertNotEqual(r.returncode,0)
     self.assertIn('outside the addon' if name.startswith('.') else 'packaging refused',r.stderr)
     self.assertEqual(dest.read_bytes(),b'previous release remains intact');private.unlink()
 # These envelopes reconstruct the documented/observed shape for adapter controls.
 # They are synthetic test inputs, not verbatim private API responses or credentials.
 def envelopes(self):
  meta={'build':'1.60.1.70959','attribution':'Data\u200b from ForeverDB.net https://foreverdb.net',
        'attributionRequired':False,'client':'private-account-control'}
  rows={}
  for key,item in self.data['items'].items():
   rows['items-'+key]={'meta':copy.deepcopy(meta),'data':{
    'id':int(key),'name':item['name']['value'],'qualityId':item['quality']['value'],
    'requiredLevel':item['requiredLevel']['value'],'inventoryType':item['slot']['value'],
    'betaEvent':False,'speculation':False,'effects':[], 'sellPrice':999999,
    'stats':[{'statId':s['statId'],'stat':name,'value':s['value']} for name,s in item['stats'].items()]}}
  rows['vendors-227853']={'meta':copy.deepcopy(meta),'data':{
   'id':227853,'name':'Pix Xizzix','seenInForever':True,'side':'Horde','zone':'Stranglethorn Vale',
   'mapId':1434,'x':28.5,'y':75.8,'reputationFaction':{'id':999,'name':'discount-only control'},
   'sells':[{'itemId':272411,'classicData':False,'seenInForever':True,'stack':1,'price':0,
             'limited':False,'limitedStockCount':None,
             'costs':[{'type':'currency','id':3469,'name':'Tarnished Undermine Real','amount':75}]}]}}
  return rows
 def adapt(self,rows):
  from foreverdb_api import normalize
  with tempfile.TemporaryDirectory() as tmp:
   p=pathlib.Path(tmp)
   for name,row in rows.items():(p/(name+'.json')).write_text(json.dumps(row))
   normalize(p,p/'out.json','2026-11-19T18:58:20+00:00')
   return load(p/'out.json')
 def test_adapter_preserves_marks_and_ignores_account_and_sell_price(self):
  d=self.adapt(self.envelopes())
  self.assertEqual(d['vendorOffers']['pix:272411']['goldCostCopper']['value'],0)
  self.assertEqual(d['vendorOffers']['pix:272411']['requiredReputationFaction']['status'],'UNKNOWN')
  self.assertNotIn('private-account-control',json.dumps(d))
  self.assertIn('\u200b',d['provenance']['fdb-api-items-272411']['attribution'])
 def test_adapter_rejects_drift(self):
  changes=[('costs',None),('stack',2),('price',None),('classicData',True)]
  for key,value in changes:
   with self.subTest(key=key):
    rows=self.envelopes();rows['vendors-227853']['data']['sells'][0][key]=value
    with self.assertRaises(ValueError):self.adapt(rows)
  rows=self.envelopes();rows['items-272411']['meta']['build']='1.60.1.99999'
  with self.assertRaises(ValueError):self.adapt(rows)
 def test_unreviewed_stat_id_label_pair_has_no_normalized_key(self):
  rows=self.envelopes();rows['items-272411']['data']['stats'][0]['statId']=9999
  d=self.adapt(rows);s=next(iter(d['items']['272411']['stats'].values()))
  self.assertEqual(s['unit'],'unknown');self.assertIsNone(s['statKey'])
if __name__=='__main__':unittest.main()
