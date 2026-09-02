#!/bin/sh
set -eu

if [ "$#" -ne 0 ]; then
    printf '%s\n' '{"message":"sbrositj.sh не принимает аргументы.","state":"unexpected_arguments"}'
    exit 64
fi

exec python3 -I -c "import os,subprocess,sys;p='Инструменты/fum-ocheredj-zadach-git-vetki/scripts/ocheredj-zadach-git-vetki.py';r=sys.argv[1];e={k:v for k,v in os.environ.items() if not k.upper().startswith('GIT_')};e['GIT_NO_REPLACE_OBJECTS']='1';e['GIT_OPTIONAL_LOCKS']='0';b=subprocess.check_output(['git','--no-replace-objects','-C',r,'show','HEAD:'+p],env=e,timeout=30);sys.argv=[p,*sys.argv[2:],'--repo-root',r];exec(compile(b,p,'exec'))" "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)" простой-сброс --json
