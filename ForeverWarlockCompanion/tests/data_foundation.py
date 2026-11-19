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
   self.assertEqual(a.read_bytes(),b.read_bytes());self.assertEqual(a.read_bytes(),(ROOT/'Data'/'Foundation.lua').read_bytes())
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
if __name__=='__main__':unittest.main()
