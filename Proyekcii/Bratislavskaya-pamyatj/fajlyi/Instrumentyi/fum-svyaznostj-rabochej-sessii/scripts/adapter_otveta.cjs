"use strict";

// Общая обёртка ввода и кэша. Предметная проекция остаётся в вызываемом CLI.
async function прочитать_кратко(среда, параметры) {
    let стадия = "параметры";
    const отказ = () => ({схема: "fum.отказ-среза-ответа.1", код: 2, причина: стадия,
        завершение_задачи_доказано: false});
    const кавычки = значение => "'" + String(значение).split("'").join("'\\''") + "'";
    try {
        const {корень, задача, режим, снимок, ключ_кэша, максимум_байтов = 16000} = параметры;
        if (![корень, задача, снимок, ключ_кэша].every(значение => typeof значение === "string" && значение.length > 0 && !/[\x00-\x1f]/.test(значение)) ||
            !["новый", "сохранённый"].includes(режим) || !Number.isInteger(максимум_байтов) ||
            максимум_байтов < 100 || максимум_байтов > 16000) return отказ();
        const инструменты = среда.инструменты;
        async function команда(аргументы) {
            let результат = await инструменты.exec_command({cmd: аргументы.map(кавычки).join(" "),
                workdir: корень, max_output_tokens: 16000, yield_time_ms: 1000});
            let вывод = результат.output || "";
            while (результат.session_id) {
                результат = await инструменты.write_stdin({session_id: результат.session_id,
                    chars: "", max_output_tokens: 16000, yield_time_ms: 1000});
                вывод += результат.output || "";
                if (вывод.length > 2097152) throw new Error("Предел вывода");
            }
            if (результат.exit_code !== 0) throw new Error("Отказ команды");
            return JSON.parse(вывод);
        }
        const ключ = "fum.сохранённый-ответ.1:" + ключ_кэша;
        let запись;
        if (режим === "новый") {
            среда.сохранить(ключ, {состояние: "не принят"});
            стадия = "путь снимка";
            await команда(["python3", "-B", "-c", [
                "from pathlib import Path", "import sys,json",
                "корень=Path(sys.argv[1]); снимок=Path(sys.argv[2])",
                "условия=[корень.is_absolute() and корень.resolve()==корень,",
                "снимок.is_absolute() and not снимок.exists() and not снимок.is_symlink(),",
                "снимок.parent.is_dir() and снимок.parent.resolve()==снимок.parent,",
                "снимок != корень and корень not in снимок.parents,",
                "all(not ((родитель/'.git').exists() or (родитель/'.git').is_symlink()) for родитель in снимок.parents)]",
                "if not all(условия): raise ValueError('Недопустимый путь снимка')",
                "print(json.dumps({'допуск':True}))"
            ].join("\n"), корень, снимок]);
            стадия = "нативный запрос";
            const ответ = await инструменты.mcp__codex_app__read_thread({threadId: задача,
                turnLimit: 1, includeOutputs: false, maxOutputCharsPerItem: 1500});
            const сериализация = JSON.stringify(ответ);
            if (typeof сериализация !== "string") throw new Error("Нет ответа");
            стадия = "сохранение полного снимка";
            const записьФайла = await инструменты.apply_patch("*** Begin Patch\n*** Add File: " + снимок +
                "\n+" + сериализация + "\n*** End Patch\n");
            if (записьФайла?.isError) throw new Error("Отказ записи");
            стадия = "хэш снимка";
            const хэш = await команда(["python3", "-B", "-c", [
                "import hashlib,json,sys", "with open(sys.argv[1],'rb') as поток: данные=поток.read(134217729)",
                "if len(данные)>134217728: raise ValueError('Превышен предел снимка')",
                "print(json.dumps({'sha256':hashlib.sha256(данные).hexdigest()}))"
            ].join("\n"), снимок]);
            запись = {состояние: "принят", корень, задача, снимок, sha256: хэш.sha256};
        } else {
            стадия = "привязка сохранённого снимка";
            запись = среда.загрузить(ключ);
            if (!запись || запись.состояние !== "принят" || запись.корень !== корень ||
                запись.задача !== задача || запись.снимок !== снимок) return отказ();
        }
        стадия = "проверка и проекция снимка";
        const результат = await команда(["python3", "-B", [корень, "Инструменты/fum-svyaznostj-rabochej-sessii/scripts/показать-ответ-задачи.py"].join("/"),
            "--снимок", снимок, "--sha256", запись.sha256, "--задача", задача,
            "--максимум-байтов", максимум_байтов, "--путь-в-результате"]);
        среда.сохранить(ключ, запись);
        return результат;
    } catch (_) { return отказ(); }
}
if (typeof module !== "undefined") module.exports = {прочитать_кратко};
