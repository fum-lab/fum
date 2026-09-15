"""Локальная детерминированная подготовка черновиков поддержки."""
import hashlib, json, re
from pathlib import Path

СХЕМА = "fum.вход-медиапакета.1"

def _текст(x): return isinstance(x, str) and bool(x.strip())
def _sha(x): return hashlib.sha256(x.encode()).hexdigest()
def _проверить(корень, d):
    if set(d) != {"схема","лицензия","результат","ограничения","цель","следующий_шаг","отчёт"} or d["схема"] != СХЕМА: raise ValueError("неверная схема")
    if d["лицензия"] != "CC0-1.0" or not isinstance(d["ограничения"],list) or not d["ограничения"] or not all(_текст(x) for x in d["ограничения"]) or any("полностью готов" in x.lower() for x in d["ограничения"]): raise ValueError("границы CC0")
    r=d["результат"]
    if set(r)!={"коммит","путь","sha256","цитата"} or not re.fullmatch(r"[0-9a-f]{40}",r["коммит"]): raise ValueError("OID")
    p=Path(r["путь"])
    if p.is_absolute() or ".." in p.parts or not _текст(r["путь"]) or not re.fullmatch(r"[0-9a-f]{64}",r["sha256"]) or not _текст(r["цитата"]): raise ValueError("источник")
    src=корень/p
    if not src.exists() or src.is_symlink() or not src.is_file(): raise ValueError("путь источника")
    import subprocess
    try: actual=subprocess.check_output(["git","show",r["коммит"]+":"+r["путь"]],cwd=корень,stderr=subprocess.DEVNULL).decode()
    except Exception as e: raise ValueError("нет Git-источника") from e
    if _sha(actual) != r["sha256"]: raise ValueError("источник изменён")
    try: blob=subprocess.check_output(["git","cat-file","-e",r["коммит"]+":"+r["путь"]],cwd=корень,stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError as e: raise ValueError("нет Git-источника") from e
    if subprocess.check_output(["git","cat-file","-t",r["коммит"]],cwd=корень).decode().strip() != "commit": raise ValueError("OID не commit")
    mode=subprocess.check_output(["git","ls-tree",r["коммит"],"--",r["путь"]],cwd=корень).decode()
    if mode.startswith("120000 "): raise ValueError("символьный Git-источник")
    if r["цитата"] not in actual: raise ValueError("цитата")
    if not _текст(d["цель"]) or not _текст(d["следующий_шаг"]): raise ValueError("текст")
    o=d["отчёт"]
    fields={"период","получатель","начальный_остаток","поступления","комиссии","возвраты","расходы","источник"}
    if set(o)!=fields: raise ValueError("отчёт")
    money=["начальный_остаток","поступления","комиссии","возвраты","расходы"]
    for k in money:
        if o[k] is not None and (type(o[k]) is not int or o[k]<=0 or o[k]>10**12): raise ValueError("сумма")
    if any(o[k] is not None for k in money) and o["источник"] is None: raise ValueError("сумма без источника")
    if o["источник"] is not None:
        if any(o["источник"].get(k) != r[k] for k in ("коммит","путь","sha256")): raise ValueError("источник отчёта")
        quote=o["источник"].get("цитата", "")
        if any(o[k] is not None and f"{o[k]/100:.2f}".replace(".", ",") not in quote for k in money): raise ValueError("сумма без свидетельства")
    return src

def собрать(корень, данные):
    корень=Path(корень); src=_проверить(корень,данные)
    canonical=json.dumps(данные,ensure_ascii=False,sort_keys=True,separators=(",",":"))
    money={"начальный_остаток","поступления","комиссии","возвраты","расходы"}
    unknown=lambda key,x: "неизвестно" if x is None else (f"{x/100:.2f} ₽" if key in money else str(x))
    o=данные["отчёт"]; total=None
    if all(o[k] is not None for k in ["начальный_остаток","поступления","комиссии","возвраты","расходы"]): total=o["начальный_остаток"]+o["поступления"]-o["комиссии"]-o["возвраты"]-o["расходы"]
    base=f"Проверенный результат: {данные['результат']['цитата']}\nЛицензия: CC0. Ограничения: {'; '.join(данные['ограничения'])}\nЦель поддержки: {данные['цель']}\nСледующий шаг: {данные['следующий_шаг']}\nСтатус: черновик; публикация и получение средств не подтверждены."
    report="Отчёт о поддержке (черновик)\n"+"\n".join(f"{k.capitalize()}: {unknown(k,o[k])}" for k in ["период","получатель","начальный_остаток","поступления","комиссии","возвраты","расходы"])+f"\nКонечный остаток: {'неизвестно' if total is None else f'{total/100:.2f} ₽'}\nИсточник: {данные['результат']['коммит']}:{данные['результат']['путь']}"
    return {"схема":"fum.выход-медиапакета.1","вход_sha256":_sha(canonical),"источник":данные["результат"],"черновики":{"Telegram":"Черновик Telegram\n\n"+base,"MAX":"Черновик MAX\n\n"+base,"отчёт":report},"конечный_остаток_копейки":total}
