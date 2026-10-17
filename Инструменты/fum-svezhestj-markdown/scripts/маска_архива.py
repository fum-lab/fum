"""Дословный ChatGPT-архив имеет собственную границу внутри Markdown."""
import re


КАТАЛОГ = ('Источники', 'URL', 'https', 'chatgpt.com', 'share')
МАРКЕР = re.compile(r'^<!-- FUM-CHATGPT-SHARE-VERBATIM:(BEGIN|END) -->$', re.MULTILINE)


def маскировать(текст, путь, корень):
    if путь is None or корень is None:
        return текст
    try:
        части = путь.relative_to(корень).parts
    except ValueError:
        return текст
    if len(части) != len(КАТАЛОГ) + 2 or части[:len(КАТАЛОГ)] != КАТАЛОГ or путь.suffix.lower() != '.md':
        return текст
    границы = list(МАРКЕР.finditer(текст))
    if len(границы) != 2 or [э.group(1) for э in границы] != ['BEGIN', 'END']:
        return текст
    начало, конец = границы
    перед = [строка for строка in текст[:начало.start()].split('\n') if строка.strip()]
    if not перед or перед[-1] != '## Диалог':
        return текст
    область = текст[начало.start():конец.end()]
    маска = re.sub(r'[^\r\n]', ' ', область)
    return текст[:начало.start()] + маска + текст[конец.end():]
