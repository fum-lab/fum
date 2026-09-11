import importlib.util,sys
from pathlib import Path
root=Path.cwd()
script=root/'Инструменты/fum-proverka-mashinno-lokaljnyikh-putej/scripts/proveritj-mashinno-lokaljnyiye-puti.py'
sys.path.insert(0,str(script.parent))
spec=importlib.util.spec_from_file_location('scanner',script);m=importlib.util.module_from_spec(spec);sys.modules[spec.name]=m;spec.loader.exec_module(m)
result=m.scan_repository(root,script.parent.parent/'policy.json')
for finding in result.findings:
 if finding.category.startswith('error.'): print(finding)
print('Код сканера:',result.exit_code)
raise SystemExit(result.exit_code)
