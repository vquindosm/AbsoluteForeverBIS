"""Real normalized API facts; no credentials or network. Not a live WoW test."""
import copy,json,pathlib,sys,tempfile,unittest
ROOT=pathlib.Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT/'tools'/'data'))
from item_guide import catalog_ids,compile_guide,validate
class GuideTest(unittest.TestCase):
 @classmethod
 def setUpClass(cls):cls.data=json.loads((ROOT/'Catalog'/'item-guide.json').read_text())
 def test_every_existing_item_has_level_and_partial_coverage(self):
  d=validate(self.data)
  self.assertEqual({int(n) for n in d['items']},catalog_ids());self.assertEqual(len(d['items']),157)
  for r in d['items'].values():
   self.assertIsInstance(r['requiredLevel'],int);self.assertEqual(r['requirementsCoverage'],'partial')
  self.assertFalse(d['coverage']['liveClientValidated']);self.assertEqual(d['coverage']['missingItemIds'],[])
 def test_real_enchants_and_formula_costs(self):
  d=self.data;e=d['enhancements']['1249057'];vendors=e['learnedFrom']['sources']['vendors']
  self.assertEqual(e['effect'],'+6 Spell Power')
  self.assertEqual(vendors['alliance'][0]['name'],'Alynsia');self.assertEqual(vendors['horde'][0]['name'],'Beneris')
  cost=vendors['horde'][0]['costs'][0]
  self.assertEqual((cost['type'],cost['id'],cost['amount']),('currency',3402,120))
  self.assertEqual(len(d['enhancements']),17)
 def test_application_level_not_player_level(self):
  e=self.data['enhancements']['1254966']
  self.assertEqual(e['targetMinItemLevel'],35);self.assertEqual(e['applicationItemId'],252487)
  self.assertIn('items level 35 and above',e['effect']);self.assertIn('\u2063',e['effect'])
 def test_crafting_skill_not_wearing_requirement(self):
  d=self.data;r=d['recipes']['14153'][0]
  self.assertEqual(r['profession'],'Tailoring');self.assertEqual(r['learnedFrom']['sources']['learnAtSkill'],295)
  self.assertEqual(d['items']['14153']['requiredLevel'],57)
  self.assertNotIn('requiredProfession',d['items']['14153'])
 def test_unknown_arcanum_source_and_labeled_classic_drops(self):
  e=self.data['enhancements'];self.assertIsNone(e['24164']['learnedFrom'])
  self.assertIn('1% chance to hit',e['24164']['effect'])
  drops=e['22749']['learnedFrom']['sources']['drops']
  self.assertTrue(drops);self.assertFalse(any(r.get('seenInForever') is True for r in drops))
 def test_reference_numbers_are_not_current_item_ep(self):
  rows=self.data['recommendations']['Head']
  self.assertEqual(rows['22267']['score'],47);self.assertEqual(rows['18727']['behindPercent'],23)
  self.assertIn('22074',rows);self.assertNotIn('226909',rows) # same name, different identity
  self.assertEqual(self.data['profile']['activity'],'PvE')
  self.assertIn('may include raids',self.data['profile']['sources'])
 def test_utility_and_twohanded_choices_separate(self):
  e=self.data['enhancements'];self.assertEqual(self.data['slotEnhancements']['Back'],[25084,20014])
  self.assertEqual(e['25084']['recommendationType'],'utility')
  self.assertEqual(e['1248607']['effect'],'Spell Power +55')
 def test_compile_reproducible_and_credential_free(self):
  with tempfile.TemporaryDirectory() as tmp:
   p=pathlib.Path(tmp)/'out.lua';compile_guide(ROOT/'Catalog'/'item-guide.json',p)
   self.assertEqual(p.read_bytes(),(ROOT/'Data'/'ItemGuide.lua').read_bytes())
  text=json.dumps(self.data);self.assertNotIn('"client":',text);self.assertNotIn('api_key',text.lower())
  for src in self.data['provenance'].values():self.assertEqual(src['creditURL'],'https://foreverdb.net')
 def test_invalid_identity_source_and_level_refused(self):
  for field,value in [('id',1),('source','missing'),('requiredLevel',False)]:
   d=copy.deepcopy(self.data);d['items']['22267'][field]=value
   with self.subTest(field=field):
    with self.assertRaises(ValueError):validate(d)
  d=copy.deepcopy(self.data);d['slotEnhancements']['Head']=[9999999]
  with self.assertRaises(ValueError):validate(d)
if __name__=='__main__':unittest.main()
