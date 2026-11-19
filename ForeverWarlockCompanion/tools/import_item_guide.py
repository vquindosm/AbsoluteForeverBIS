"""Normalize reviewed, privately fetched ForeverDB records or compile them offline."""
import argparse,json,os,pathlib,sys,time
sys.path.insert(0,str(pathlib.Path(__file__).resolve().parent/'data'))
from item_guide import ROOT,normalize,compile_guide,catalog_ids
from catalog import secret_check
def fetch_records(folder,only_missing=False):
 from import_foundation import fetch,BASE
 folder=pathlib.Path(folder).resolve()
 if folder==ROOT or ROOT in folder.parents:raise ValueError('Keep private responses outside the addon')
 key=os.environ.get('FOREVERDB_API_KEY')
 if not key:raise ValueError('Configure FOREVERDB_API_KEY outside the addon; never ship the key')
 folder.mkdir(parents=True,exist_ok=True,mode=0o700)
 endpoints=['items/'+str(i) for i in sorted(catalog_ids())]
 endpoints+=['spells/'+str(i) for i in (24164,22844,29467)]+['items/252487']
 endpoints+=['professions/enchanting?limit=100'+('&offset='+str(n) if n else '') for n in (0,100,200)]
 endpoints+=['professions/tailoring?limit=100'+('&offset='+str(n) if n else '') for n in (0,100,200,300,400)]
 endpoints+=['professions/leatherworking?q=Mystic+Rugged+Armor+Kit','professions/leatherworking?q=Hide+of+the+Wild',
             'professions/engineering?q=Spellpower+Goggles+Xtreme+Plus','professions/blacksmithing?q=Sageblade']
 for endpoint in endpoints:
  path=folder/(endpoint.replace('/','-').replace('?','_').replace('&','_')+'.json')
  if only_missing and path.exists():continue
  raw=fetch(BASE+'/api/v1/'+endpoint,key);envelope=json.loads(raw);secret_check(envelope)
  if not isinstance(envelope,dict) or not isinstance(envelope.get('meta'),dict) or not isinstance(envelope.get('data'),dict):raise ValueError('Unexpected API envelope; review before retrying')
  # Preserve exact response bytes/source marks in private quarantine.
  path.write_bytes(raw);path.chmod(0o600);print('Fetched '+endpoint,flush=True);time.sleep(2.1)
 page=folder/'affliction-bis.html';page.write_bytes(fetch(BASE+'/bis/warlock/affliction'));page.chmod(0o600)
 print('Fetched bounded gear/enchant records. Review sources and builds before normalize; not a full profession import.')
def main():
 p=argparse.ArgumentParser();s=p.add_subparsers(dest='command',required=True)
 n=s.add_parser('normalize');n.add_argument('--input-dir',required=True);n.add_argument('--guide-html',required=True);n.add_argument('--imported-at');n.add_argument('--output',default=str(ROOT/'Catalog'/'item-guide.json'))
 f=s.add_parser('fetch');f.add_argument('--out-dir',required=True);f.add_argument('--only-missing',action='store_true')
 c=s.add_parser('compile');c.add_argument('--input',default=str(ROOT/'Catalog'/'item-guide.json'));c.add_argument('--lua',default=str(ROOT/'Data'/'ItemGuide.lua'));c.add_argument('--report',default=str(ROOT/'docs'/'ITEM_GUIDE_COVERAGE.json'))
 a=p.parse_args()
 if a.command=='fetch':fetch_records(a.out_dir,a.only_missing)
 elif a.command=='normalize':print(json.dumps(normalize(a.input_dir,a.guide_html,a.output,a.imported_at),indent=2))
 else:print(compile_guide(a.input,a.lua,a.report))
if __name__=='__main__':
 try:main()
 except (ValueError,OSError,KeyError) as e:sys.exit(str(e))
