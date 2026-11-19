"""Build an installable ZIP with only the addon directory at its root.
Run: python3 tools/build_zip.py /path/to/ForeverCompanion-3.0.0-preview.zip
"""
import pathlib, sys, zipfile
root=pathlib.Path(__file__).resolve().parents[1]
dest=pathlib.Path(sys.argv[1]).resolve()
assert root not in dest.parents, 'Choose a destination outside the addon directory'
# Compile only the reviewed local snapshot; never fetch network data during release.
if (root/'Catalog'/'public-vendor-slice.json').is_file():
 from data.catalog import compile_catalog
 compile_catalog(root/'Catalog'/'public-vendor-slice.json',root/'Data'/'Foundation.lua',root/'Catalog'/'foundation.sqlite',root/'docs'/'DATA_COVERAGE.json')
dest.parent.mkdir(parents=True,exist_ok=True)
with zipfile.ZipFile(dest,'w',zipfile.ZIP_DEFLATED) as z:
 for file in sorted(root.rglob('*')):
  if file.is_file() and '.git' not in file.parts and '__pycache__' not in file.parts:
   z.write(file,pathlib.Path(root.name)/file.relative_to(root))
with zipfile.ZipFile(dest) as z:
 assert z.testzip() is None
 prefix=root.name+'/'
 toc=z.read(prefix+'ForeverWarlockCompanion.toc').decode()
 for line in toc.splitlines():
  if line.endswith('.lua'): assert prefix+line.replace('\\','/') in z.namelist(),line
print(str(dest),dest.stat().st_size,'bytes')
