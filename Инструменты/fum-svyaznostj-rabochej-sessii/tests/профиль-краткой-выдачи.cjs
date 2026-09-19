"use strict";
const фс = require("node:fs");
const пути = require("node:path");
const ос = require("node:os");
const процессы = require("node:child_process");
const крипто = require("node:crypto");
const утверждать = require("node:assert/strict");
const {прочитать_кратко} = require("../scripts/адаптер_ответа.cjs");

async function выполнить() {
    const временный = фс.realpathSync(фс.mkdtempSync(пути.join(ос.tmpdir(), "fum-профиль-")));
    try {
        const корень = пути.resolve(__dirname, "../../..");
        const задача = "00000000-0000-0000-0000-000000000165";
        const вход = {schemaVersion: 1, thread: {id: задача, kind: "codex", status: {type: "active"}},
            page: {order: "newest_first", limit: 1, nextCursor: "ещё", hasMore: true},
            turns: [{id: "ход", status: "inProgress", error: null, startedAt: 100, completedAt: null, durationMs: null, items: []}]};
        const данные = JSON.stringify({content: [{type: "text", text: JSON.stringify(вход)}], isError: false}) + "\n";
        const снимок = пути.join(временный, "снимок.json");
        фс.writeFileSync(снимок, данные);
        const sha256 = крипто.createHash("sha256").update(данные).digest("hex");
        const запись = {состояние: "принят", корень, задача, снимок, sha256};
        let команды = 0;
        const среда = {загрузить: () => запись, сохранить: () => {}, инструменты: {
            exec_command: async параметры => {
                команды++;
                try {return {exit_code: 0, output: процессы.execFileSync("sh", ["-c", параметры.cmd], {cwd: параметры.workdir, encoding: "utf8", stdio: ["pipe", "pipe", "pipe"]})};}
                catch (ошибка) {return {exit_code: ошибка.status ?? 1, output: String(ошибка.stderr)}}
            },
            mcp__codex_app__read_thread: async () => {throw new Error("API запрещён");},
            apply_patch: async () => {throw new Error("Запись запрещена");}
        }};
        const замеры = [];
        for (let пара = 0; пара < 3; пара++) {
            for (const формат of пара % 2 ? ["краткий", "подробный"] : ["подробный", "краткий"]) {
                const до = команды;
                const начало = process.hrtime.bigint();
                const результат = await прочитать_кратко(среда, {корень, задача, снимок, ключ_кэша: "профиль", режим: "сохранённый", формат_выдачи: формат});
                const выход = JSON.stringify(результат) + "\n";
                const длительность = Number(process.hrtime.bigint() - начало);
                утверждать.equal(результат.ответ, null);
                утверждать.equal(команды - до, 1);
                утверждать.equal(результат.схема, формат === "краткий" ? "fum.краткий-ответ-задачи.1" : "fum.срез-ответа-задачи.1");
                замеры.push({пара, формат, длительность_ns: длительность, байтов: Buffer.byteLength(выход), sha256: крипто.createHash("sha256").update(выход).digest("hex")});
            }
        }
        утверждать.equal(фс.readFileSync(снимок, "utf8"), данные);
        for (let пара = 0; пара < 3; пара++) утверждать.ok(замеры.find(x => x.пара === пара && x.формат === "краткий").байтов < замеры.find(x => x.пара === пара && x.формат === "подробный").байтов);
        const результат = {схема: "fum.профиль-краткой-выдачи.1", node: process.version, вход_sha256: sha256, вход_байтов: Buffer.byteLength(данные), команды, api: 0, вход_неизменен: true, замеры,
            граница: "Сохранённая открытая пустая страница; весь адаптер, subprocess, SHA и JSON+LF. Подготовка и очистка вне таймера; кэш ОС не сбрасывался. Токены, живой API и новый режим получения не измерены."};
        фс.writeFileSync(process.argv[2], JSON.stringify(результат, null, 2) + "\n", {flag: "wx"});
        console.log(JSON.stringify({команды, подробный_байтов: замеры.find(x=>x.формат==="подробный").байтов, краткий_байтов: замеры.find(x=>x.формат==="краткий").байтов}));
    } finally {фс.rmSync(временный, {recursive: true, force: true});}
}
выполнить().catch(ошибка => {console.error(ошибка);process.exitCode=2;});
