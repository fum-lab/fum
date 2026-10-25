"""Три новых процесса проверки нормы; измерение не активирует писателя."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import stat
import statistics
import subprocess
import sys
import time

def главная():
    а=argparse.ArgumentParser();а.add_argument('--корень',type=Path,required=True);а.add_argument('--выход',type=Path,required=True)
    п=а.parse_args();р=п.корень
    if not р.is_absolute() or р.resolve()!=р: raise ValueError('нужен физический абсолютный корень')
    в=п.выход
    if (not в.is_absolute() or в.parent.resolve()!=в.parent or в.parent.stat().st_mode&0o777!=0o700
            or os.path.lexists(в) or в.is_relative_to(р)): raise ValueError('новый приватный выход вне checkout')
    к=Path(__file__).resolve().parents[1]
    пути=['AGENTS.md','Правила/агентов/Git-и-рабочая-сессия.md','Правила/агентов/инвентарь-правил.json']
    пути += [ф.relative_to(р).as_posix() for ф in sorted((к/'scripts').glob('*.py'))]
    def снимок():
        д={}
        for имя in пути:
            ф=р/имя
            if ф.is_symlink() or not stat.S_ISREG(ф.lstat().st_mode): raise ValueError('нефизический вход')
            д[имя]={'sha256':hashlib.sha256(ф.read_bytes()).hexdigest(),'режим':stat.S_IMODE(ф.lstat().st_mode)}
        return д
    до=снимок();серии=[]
    for _ in range(3):
        assert снимок()==до
        н=time.monotonic_ns()
        пр=subprocess.run([sys.executable,'-B',str(к/'scripts/проверить-декомпозицию-правил.py'),'--корень-репозитория',str(р),'проверить'],cwd=р,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
        д=time.monotonic_ns()-н
        серии.append({'монотонные_нс':д,'код':пр.returncode,'stdout_байты':len(пр.stdout),'stdout_sha256':hashlib.sha256(пр.stdout).hexdigest(),'stderr_байты':len(пр.stderr),'stderr_sha256':hashlib.sha256(пр.stderr).hexdigest()})
        assert снимок()==до
        if пр.returncode: raise ValueError('профиль отказал; результат процесса '+str(серии[-1]))
    итог={'схема':'fum.профиль-нормативного-допуска-состояния.1','исходники':до,'серии':серии,
        'медиана_нс':statistics.median(с['монотонные_нс'] for с in серии),
        'граница':'Три новых процесса полного нормативного валидатора. Чтение и сверка входов вне таймера; кэш ОС не сбрасывается. Это стоимость статического допуска, не запуска или восстановления узла.'}
    б=(json.dumps(итог,ensure_ascii=False,sort_keys=True,indent=2)+'\n').encode()
    with os.fdopen(os.open(в,os.O_WRONLY|os.O_CREAT|os.O_EXCL|os.O_NOFOLLOW,0o600),'wb') as ф:ф.write(б);ф.flush();os.fsync(ф.fileno())
    print(json.dumps({'серий':3,'медиана_нс':итог['медиана_нс'],'sha256':hashlib.sha256(б).hexdigest()},ensure_ascii=False))
if __name__=='__main__':главная()
