"""Build an installable ZIP with only the addon directory at its root.
Run: python3 tools/build_zip.py /path/to/ForeverCompanion-3.0.0-preview.zip
"""
import pathlib, re, sys, zipfile
root=pathlib.Path(__file__).resolve().parents[1]
dest=pathlib.Path(sys.argv[1]).resolve()
assert root not in dest.parents, 'Choose a destination outside the addon directory'
# Compile only the reviewed local snapshot; never fetch network data during release.
from data.catalog import compile_catalog
compile_catalog(root/'Catalog'/'api-vendor-slice.json',root/'Data'/'Foundation.lua',root/'Catalog'/'foundation.sqlite',root/'docs'/'DATA_COVERAGE.json')
files=[]
for file in sorted(root.rglob('*')):
 if not file.is_file() or '.git' in file.parts or '__pycache__' in file.parts:continue
 if any(p in ('private-api','SavedVariables') for p in file.relative_to(root).parts) or file.name.startswith(('.env','credentials','token')) or file.suffix=='.key':
  raise ValueError('Private file must stay outside the addon: '+str(file.relative_to(root)))
 if re.search(rb'fdb_[A-Za-z0-9_-]{16,}',file.read_bytes()):
  raise ValueError('Possible credential; packaging refused: '+str(file.relative_to(root)))
 files.append(file)
dest.parent.mkdir(parents=True,exist_ok=True)
with zipfile.ZipFile(dest,'w',zipfile.ZIP_DEFLATED) as z:
 for file in files:z.write(file,pathlib.Path(root.name)/file.relative_to(root))
with zipfile.ZipFile(dest) as z:
 assert z.testzip() is None
 prefix=root.name+'/'
 toc=z.read(prefix+'ForeverWarlockCompanion.toc').decode()
 for line in toc.splitlines():
  if line.endswith('.lua'): assert prefix+line.replace('\\','/') in z.namelist(),line
print(str(dest),dest.stat().st_size,'bytes')
