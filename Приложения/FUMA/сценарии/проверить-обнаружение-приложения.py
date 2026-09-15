"""Проверяет собранный MCP с подставным pgrep; приложение не запускается."""
import argparse
import json
import os
from pathlib import Path
import statistics
import subprocess
import sys
import tempfile
import time


def проверить(сервер):
    замеры = []
    with tempfile.TemporaryDirectory(prefix="fuma-discovery-") as каталог:
        корень = Path(каталог).resolve()
        pgrep = корень / "pgrep"
        pgrep.write_text(
            "#!" + sys.executable + "\n"
            "import os,sys\n"
            "from pathlib import Path\n"
            "Path(os.environ['FUM_FIXTURE_ARGS']).write_text(' '.join(sys.argv[1:]))\n"
            "if sys.argv[1:] != ['-x', 'FUMA']: sys.exit(77)\n"
            "print(os.environ['FUM_FIXTURE_PIDS'])\n"
        )
        pgrep.chmod(0o700)
        for найден in (True, False):
            for _ in range(5):
                среда = dict(os.environ, FUM_PGREP_EXECUTABLE=str(pgrep),
                    FUM_RUNTIME_ROOT=str(корень / "runtime"), FUM_MEMORY_ROOT=str(корень / "memory"),
                    FUM_DOCUMENTS_ROOT=str(корень / "documents"), FUM_APP_BUNDLE=str(корень / "FUMA.app"),
                    FUM_FIXTURE_ARGS=str(корень / "arguments"), FUM_FIXTURE_PIDS="12345\n23456" if найден else "")
                начало = time.perf_counter_ns()
                ответ = subprocess.run([str(сервер)], input=json.dumps({"jsonrpc": "2.0", "id": 1,
                    "method": "tools/call", "params": {"name": "status", "arguments": {}}}) + "\n",
                    text=True, capture_output=True, env=среда, timeout=10, check=True)
                длительность = time.perf_counter_ns() - начало
                приложение = json.loads(ответ.stdout)["result"]["structuredContent"]["app"]
                assert (корень / "arguments").read_text() == "-x FUMA"
                assert приложение["processName"] == "FUMA"
                assert приложение["isRunning"] is найден
                assert приложение["pids"] == (["12345", "23456"] if найден else [])
                assert приложение["bundlePath"] == str(корень / "FUMA.app")
                assert not any((корень / p).exists() for p in ("runtime", "memory", "documents", "FUMA.app"))
                замеры.append({"найден": найден, "наносекунды": длительность})
    return {"схема": "fum.проверка-имени-приложения.1", "результат": "успешно", "образцы": замеры,
            "медиана_наносекунды": statistics.median(p["наносекунды"] for p in замеры),
            "граница": "Полный запуск MCP, JSON-RPC status, подставной pgrep и завершение; не чистая стоимость поиска ОС и не сравнение ускорения."}


if __name__ == "__main__":
    аргументы = argparse.ArgumentParser(description=__doc__)
    аргументы.add_argument("--сервер", type=Path, required=True)
    print(json.dumps(проверить(аргументы.parse_args().сервер.resolve()), ensure_ascii=False, indent=2))
