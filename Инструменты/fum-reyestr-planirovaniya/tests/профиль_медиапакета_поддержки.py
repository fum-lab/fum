"""Воспроизводимый профиль детерминированного локального пакета."""
import argparse, hashlib, json, platform, sys, time
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"scripts"))
from медиапакет_поддержки import собрать
p=argparse.ArgumentParser();p.add_argument("--корень",required=True);p.add_argument("--вход",required=True);p.add_argument("--выход",required=True);p.add_argument("--повторы",type=int,default=10);a=p.parse_args()
root=Path(a.корень).resolve(); raw=Path(a.вход).read_bytes(); data=json.loads(raw); durations=[]; hashes=[]
for _ in range(a.повторы):
    start=time.perf_counter_ns(); result=собрать(root,data); durations.append(time.perf_counter_ns()-start); hashes.append(hashlib.sha256(json.dumps(result,ensure_ascii=False,sort_keys=True).encode()).hexdigest())
if len(set(hashes))!=1: raise SystemExit("недетерминированный результат")
out={"схема":"fum.профиль-медиапакета.1","python":platform.python_version(),"повторы":a.повторы,"вход_sha256":hashlib.sha256(raw).hexdigest(),"исходник_sha256":hashlib.sha256((root/"Инструменты/fum-reyestr-planirovaniya/scripts/медиапакет_поддержки.py").read_bytes()).hexdigest(),"длительности_наносекунды":durations,"результат_sha256":hashes[0]}
Path(a.выход).write_text(json.dumps(out,ensure_ascii=False,indent=2)+"\n")
