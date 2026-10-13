(async function () {
  const команда = "__КОМАНДА__";
  const корень = "__КОРЕНЬ__";
  const начало = "__exec_мс__";
  const предел = "__ожиданий__";
  const ожидание = "__ожидание_мс__";
  const токены = "__токенов__";
  const события = [];
  let ответ = await tools.exec_command({
    cmd: команда, workdir: корень, shell: "/bin/sh", login: false,
    max_output_tokens: Number(токены), yield_time_ms: Number(начало)
  });
  события.push(ответ);
  const сеанс = ответ.session_id;
  for (let номер = 0; номер < Number(предел) && Number.isInteger(сеанс) && ответ.session_id === сеанс; номер += 1) {
    ответ = await tools.write_stdin({
      session_id: сеанс, chars: "",
      max_output_tokens: Number(токены), yield_time_ms: Number(ожидание)
    });
    события.push(ответ);
  }
  text({схема: "fum.нативные-события-подготовки.1", события: события});
});
