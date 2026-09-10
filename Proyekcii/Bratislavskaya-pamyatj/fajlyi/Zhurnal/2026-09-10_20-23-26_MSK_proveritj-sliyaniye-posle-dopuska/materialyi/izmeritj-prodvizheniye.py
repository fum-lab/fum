"""Парный профиль перехода на одной временной Git-фикстуре."""
import importlib.util
import argparse
import json
from pathlib import Path
import statistics
import time


def load(name, filename):
    path = Path(filename)
    if not path.is_absolute():
        path = Path(__file__).parent / path
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--только-до", action="store_true")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[3]
    tool = root / "Инструменты/fum-otchyotyi-o-zapuskakh-proverok"
    tests = load("promotion_tests", tool / "tests/test_продвижение_принятого_слияния.py")
    before = load("before", "продвижение-до-оптимизации.py")
    after = load("after", tool / "scripts/продвинуть_принятое_слияние.py")
    fixture = tests.Продвижение()
    fixture.setUp()
    rows = []
    try:
        for pair in range(7):
            variants = [("до", before), ("после", after)]
            if args.только_до:
                variants = variants[:1]
            if pair % 2:
                variants.reverse()
            results = []
            for name, module in variants:
                tests.module = module
                fixture.g("reset", "--hard", fixture.M)
                fixture.intent.unlink(missing_ok=True)
                count = [0]
                original = module.subprocess.Popen
                def counted(*args, **kwargs):
                    command = args[0] if args else kwargs.get("args", [])
                    if command and command[0] == "git":
                        count[0] += 1
                    return original(*args, **kwargs)
                module.subprocess.Popen = counted
                start = time.perf_counter_ns()
                cpu = time.process_time_ns()
                try:
                    result = fixture.run_transition()
                finally:
                    elapsed = time.perf_counter_ns() - start
                    cpu_elapsed = time.process_time_ns() - cpu
                    module.subprocess.Popen = original
                rows.append({"пара": pair, "вариант": name, "wall_ns": elapsed,
                             "cpu_родителя_ns": cpu_elapsed, "процессов_git": count[0]})
                result.pop("исполнитель_sha256")
                results.append(result)
            if len(results) == 2:
                assert results[0] == results[1]
    finally:
        fixture.doCleanups()
    summary = {}
    for name in ("до", "после"):
        selected = [r for r in rows if r["вариант"] == name]
        if not selected:
            continue
        summary[name] = {"медиана_wall_ns": int(statistics.median(r["wall_ns"] for r in selected)),
                         "процессов_git": sorted({r["процессов_git"] for r in selected})}
    print(json.dumps({"схема": "fum.профиль-перехода.1", "граница":
                      "Семь чередующихся пар на одной синтетической фикстуре; подготовка и reset исключены. "
                      "CPU дочерних процессов и память не измерены. Семантические результаты совпали; "
                      "различающийся хэш версии исполнителя исключён из сравнения. Это не профиль всего FUM.",
                      "измерения": rows, "итог": summary}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
