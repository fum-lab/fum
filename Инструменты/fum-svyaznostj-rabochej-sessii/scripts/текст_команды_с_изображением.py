"""Текстовая проекция известного каркаса; исходные части остаются непрозрачными."""
import re


def текстовая_часть(часть):
    return type(часть) is dict and set(часть) == {'type', 'text'} and часть['type'] == 'input_text' and type(часть['text']) is str


def известное_изображение(часть):
    if type(часть) is not dict or set(часть) not in (
            {'type', 'image_url'}, {'type', 'image_url', 'detail'}):
        return False
    if часть['type'] != 'input_image' or ('detail' in часть and часть['detail'] not in ('auto', 'low', 'high', 'original')):
        return False
    адрес = часть['image_url']
    if type(адрес) is not str:
        return False
    заголовок, разделитель, тело = адрес.partition(',')
    # Это проверка синтаксиса, без декодирования, сети или утверждения о пикселях.
    return bool(разделитель and заголовок in {
        'data:image/png;base64', 'data:image/jpeg;base64',
        'data:image/gif;base64', 'data:image/webp;base64'}
        and тело and len(тело) % 4 == 0 and re.fullmatch(r'[A-Za-z0-9+/]+={0,2}', тело))


def извлечь_текст(содержимое, требовать):
    требовать(type(содержимое) is list and bool(содержимое)
        and текстовая_часть(содержимое[0]), 'неподдержанный первичный текст')
    if len(содержимое) == 1:
        return содержимое[0]['text']
    требовать(len(содержимое) >= 4 and (len(содержимое) - 1) % 3 == 0,
        'неподдержанный каркас текста с изображением')
    тексты = [содержимое[0]['text']]
    for номер in range(1, len(содержимое), 3):
        открытие, изображение, закрытие = содержимое[номер:номер + 3]
        требовать(текстовая_часть(открытие) and re.fullmatch(
            r'<image name=\[Image #[1-9][0-9]*\] path="[^"\r\n]+">', открытие['text'])
            and известное_изображение(изображение) and текстовая_часть(закрытие)
            and закрытие['text'] == '</image>', 'неподдержанный каркас текста с изображением')
        тексты.extend((открытие['text'], закрытие['text']))
    return '\n'.join(тексты)
