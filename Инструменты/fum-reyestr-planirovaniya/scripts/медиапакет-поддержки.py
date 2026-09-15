#!/usr/bin/env python3
import argparse,json,sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parent))
from медиапакет_поддержки import собрать
p=argparse.ArgumentParser();p.add_argument('--корень-репозитория',required=True);p.add_argument('--вход',required=True);a=p.parse_args()
try:
    with open(a.вход,encoding='utf-8') as f: d=json.load(f,object_pairs_hook=lambda x: {k:v for k,v in x})
    print(json.dumps(собрать(Path(a.корень_репозитория),d),ensure_ascii=False,indent=2))
except Exception as e:
    print(str(e),file=sys.stderr);sys.exit(2)
