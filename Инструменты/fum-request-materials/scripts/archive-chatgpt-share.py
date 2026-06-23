#!/usr/bin/env python3
"""Archive a ChatGPT share page for a FUM sources folder."""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import re
import shutil
import subprocess
import sys
import tempfile
from html.parser import HTMLParser
from pathlib import Path
from typing import Any
from urllib.parse import unquote, urlsplit


REDACTION = "[REDACTED: local request metadata]"
COOKIE_REDACTION = "set-cookie: [REDACTED: response cookie]\n"


class ScriptCollector(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=False)
        self.in_script = False
        self.current: list[str] = []
        self.scripts: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag == "script":
            self.in_script = True
            self.current = []

    def handle_endtag(self, tag: str) -> None:
        if tag == "script" and self.in_script:
            self.scripts.append("".join(self.current))
            self.in_script = False

    def handle_data(self, data: str) -> None:
        if self.in_script:
            self.current.append(data)


class VisibleTextCollector(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.skip = 0
        self.parts: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        if tag in {"script", "style", "template", "svg"}:
            self.skip += 1
        if tag in {"p", "div", "section", "article", "main", "li", "h1", "h2", "h3", "h4", "h5", "h6", "br", "tr"} and not self.skip:
            self.parts.append("\n")

    def handle_endtag(self, tag: str) -> None:
        if tag in {"script", "style", "template", "svg"} and self.skip:
            self.skip -= 1
        if tag in {"p", "div", "section", "article", "main", "li", "h1", "h2", "h3", "h4", "h5", "h6", "tr"} and not self.skip:
            self.parts.append("\n")

    def handle_data(self, data: str) -> None:
        if not self.skip:
            text = data.strip()
            if text:
                self.parts.append(text)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("url", help="ChatGPT share URL")
    parser.add_argument(
        "--request-file",
        required=True,
        type=Path,
        help="Path to the request Markdown file in Запросы/",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        help="Explicit sources directory. Overrides the URL-derived default.",
    )
    parser.add_argument(
        "--source-name",
        help=(
            "Optional descriptive source name. Kept for compatibility; "
            "stable URLs use an URL-derived default directory."
        ),
    )
    return parser.parse_args()


def source_name_slug(source_name: str) -> str:
    parts = re.findall(r"[0-9A-Za-zА-Яа-яЁё]+", source_name)
    return "-".join(parts) or "источник"


def source_path_segment(value: str) -> str:
    decoded = unquote(value).strip()
    parts = re.findall(r"[0-9A-Za-zА-Яа-яЁё._~-]+", decoded)
    segment = "-".join(parts).strip(".")
    if segment in {"", ".", ".."}:
        return "_"
    return segment[:120]


def hashed_url_component(prefix: str, value: str) -> str:
    digest = hashlib.sha256(value.encode("utf-8")).hexdigest()[:16]
    readable = source_path_segment(value)[:48].strip("-_")
    if readable:
        return f"_{prefix}-{readable}-{digest}"
    return f"_{prefix}-{digest}"


def request_base_dir(request_file: Path) -> Path:
    return request_file.parent.parent if request_file.parent.name == "Запросы" else request_file.parent


def url_output_dir(base_dir: Path, url: str) -> Path:
    parsed = urlsplit(url)
    if not parsed.scheme or not parsed.netloc:
        raise ValueError("URL must include scheme and host")

    host = parsed.hostname or parsed.netloc
    netloc = host.lower()
    try:
        port = parsed.port
    except ValueError:
        port = None
    if port is not None:
        netloc = f"{netloc}-{port}"

    parts = [
        "URL",
        source_path_segment(parsed.scheme.lower()),
        source_path_segment(netloc),
    ]
    path_parts = [source_path_segment(part) for part in parsed.path.split("/") if part]
    parts.extend(path_parts or ["_root"])
    if parsed.query:
        parts.append(hashed_url_component("query", parsed.query))
    if parsed.fragment:
        parts.append(hashed_url_component("fragment", parsed.fragment))
    return base_dir / "Источники" / Path(*parts)


def default_output_dir(
    request_file: Path,
    url: str,
    source_name: str | None = None,
) -> Path:
    base_dir = request_base_dir(request_file)
    try:
        return url_output_dir(base_dir, url)
    except ValueError:
        if source_name:
            return base_dir / "Источники" / f"{request_file.stem}_{source_name_slug(source_name)}"
        raise

def run_curl(url: str, html_path: Path, headers_path: Path) -> dict[str, str]:
    curl = shutil.which("curl")
    if not curl:
        raise RuntimeError("curl is required for reproducible header/body capture")

    write_out = (
        "url_effective=%{url_effective}\\n"
        "http_code=%{http_code}\\n"
        "content_type=%{content_type}\\n"
        "size_download=%{size_download}\\n"
        "time_total=%{time_total}\\n"
        "redirect_url=%{redirect_url}\\n"
    )
    proc = subprocess.run(
        [curl, "-L", url, "-D", str(headers_path), "-o", str(html_path), "-w", write_out],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    info: dict[str, str] = {}
    for line in proc.stdout.splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            info[key] = value
    return info


def redact_headers(raw: str) -> str:
    lines = []
    for line in raw.splitlines(keepends=True):
        if line.lower().startswith("set-cookie:"):
            lines.append(COOKIE_REDACTION)
        else:
            lines.append(line)
    return "".join(lines)


def trim_trailing_whitespace(text: str) -> str:
    lines = [line.rstrip() for line in text.splitlines()]
    while lines and lines[-1] == "":
        lines.pop()
    return "\n".join(lines) + "\n"


def redact_initial_state(value: Any) -> Any:
    sensitive_exact = {
        "cfConnectingIp",
        "cfIpCity",
        "cfIpLatitude",
        "cfIpLongitude",
        "cfIpRegion",
        "cfIpRegionCode",
        "cfIpCountry",
        "userContinent",
        "userCountry",
        "userRegion",
        "userRegionCode",
        "sessionId",
        "DeviceId",
        "WebAnonymousCookieID",
        "stableID",
        "ip",
        "userAgent",
        "user_agent",
        "region",
        "region_code",
        "country",
    }
    if isinstance(value, dict):
        redacted: dict[str, Any] = {}
        for key, item in value.items():
            if key == "statsigPayload" and isinstance(item, str):
                try:
                    statsig = json.loads(item)
                    redacted[key] = json.dumps(redact_initial_state(statsig), ensure_ascii=False)
                except json.JSONDecodeError:
                    redacted[key] = REDACTION
            elif key in sensitive_exact:
                redacted[key] = REDACTION
            elif key == "id" and isinstance(item, str) and item.startswith("ua-"):
                redacted[key] = REDACTION
            else:
                redacted[key] = redact_initial_state(item)
        return redacted
    if isinstance(value, list):
        return [redact_initial_state(item) for item in value]
    return value


def collect_scripts(html_text: str) -> list[str]:
    parser = ScriptCollector()
    parser.feed(html_text)
    return parser.scripts


def collect_visible_text(html_text: str) -> str:
    parser = VisibleTextCollector()
    parser.feed(html_text)
    joined = " ".join(parser.parts)
    return "\n".join(line.strip() for line in re.split(r"\n+", joined) if line.strip())


def sanitize_html(html_text: str, scripts: list[str]) -> tuple[str, Any | None]:
    initial_state = None
    for body in scripts:
        stripped = body.strip()
        if not stripped.startswith('{"authStatus"'):
            continue
        try:
            parsed = json.loads(stripped)
        except json.JSONDecodeError:
            continue
        initial_state = redact_initial_state(parsed)
        redacted_body = json.dumps(initial_state, ensure_ascii=False, separators=(",", ":"))
        html_text = html_text.replace(body, redacted_body, 1)
        break
    return html_text, initial_state


def extract_stream_parts(scripts: list[str]) -> list[str]:
    parts: list[str] = []
    pattern = re.compile(
        r"window\.__reactRouterContext\.streamController\.enqueue\((\"(?:[^\"\\]|\\.)*\")\);",
        re.S,
    )
    for body in scripts:
        for match in pattern.finditer(body):
            try:
                parts.append(json.loads(match.group(1)))
            except json.JSONDecodeError:
                parts.append(match.group(1))
    return parts


def decode_react_router_table(stream_text: str) -> Any:
    first = stream_text.split("\n\n--- stream part ---\n\n", 1)[0]
    table = json.loads(first)
    if not isinstance(table, list):
        raise ValueError("React Router stream root is not a table array")

    size = len(table)
    negative = {
        -1: "$NEGATIVE_ONE",
        -2: "$NEGATIVE_TWO",
        -3: "$NEGATIVE_THREE",
        -4: "$NEGATIVE_FOUR",
        -5: "$UNDEFINED",
    }
    memo: dict[int, Any] = {}
    resolving: set[int] = set()

    def resolve_ref(index: int) -> Any:
        if index < 0:
            return negative.get(index, f"$NEGATIVE:{index}")
        if index >= size:
            return index
        if index in memo:
            return memo[index]
        if index in resolving:
            return f"$CYCLE:{index}"
        resolving.add(index)
        value = decode(table[index])
        resolving.remove(index)
        memo[index] = value
        return value

    def decode(value: Any) -> Any:
        if isinstance(value, int):
            return resolve_ref(value)
        if isinstance(value, list):
            return [decode(item) for item in value]
        if isinstance(value, dict):
            out: dict[str, Any] = {}
            for key, item in value.items():
                if isinstance(key, str) and key.startswith("_") and key[1:].isdigit():
                    decoded_key = resolve_ref(int(key[1:]))
                else:
                    decoded_key = key
                if not isinstance(decoded_key, str):
                    decoded_key = json.dumps(decoded_key, ensure_ascii=False)
                out[decoded_key] = decode(item)
            return out
        return value

    return resolve_ref(0)


def extract_messages(decoded: Any) -> dict[str, Any]:
    route = (
        decoded.get("loaderData", {})
        .get("routes/share.$shareId.($action)", {})
    )
    server = route.get("serverResponse", {})
    data = server.get("data", {}) if isinstance(server, dict) else {}
    linear = data.get("linear_conversation", []) if isinstance(data, dict) else []

    messages: list[dict[str, Any]] = []
    for item in linear:
        node = item if isinstance(item, dict) else None
        if not isinstance(node, dict):
            continue
        msg = node.get("message")
        if not isinstance(msg, dict):
            continue
        author = msg.get("author") or {}
        content = msg.get("content") or {}
        parts = content.get("parts")
        if isinstance(parts, list):
            text = "\n".join(part for part in parts if isinstance(part, str)).strip()
        elif isinstance(parts, str):
            text = parts.strip()
        elif isinstance(content.get("text"), str):
            text = content["text"].strip()
        else:
            text = ""
        if not text:
            continue
        timestamp = msg.get("create_time")
        timestamp_utc = None
        if isinstance(timestamp, (int, float)):
            timestamp_utc = dt.datetime.fromtimestamp(timestamp, dt.timezone.utc).isoformat()
        messages.append(
            {
                "node_id": node.get("id"),
                "parent": node.get("parent"),
                "role": author.get("role") or author.get("name") or "unknown",
                "content_type": content.get("content_type"),
                "create_time": timestamp,
                "create_time_utc": timestamp_utc,
                "text": text,
            }
        )

    return {
        "title": data.get("title"),
        "conversation_id": data.get("conversation_id"),
        "backing_conversation_id": data.get("backing_conversation_id"),
        "create_time": data.get("create_time"),
        "update_time": data.get("update_time"),
        "message_count": len(messages),
        "messages": messages,
    }


def write_messages_markdown(path: Path, url: str, messages_data: dict[str, Any]) -> None:
    lines = [
        "# Извлеченный текст расшаренного диалога",
        "",
        f"Источник: {url}",
        f"Заголовок: {messages_data.get('title')}",
        f"Количество извлеченных сообщений: {messages_data.get('message_count')}",
        "",
    ]
    for index, message in enumerate(messages_data.get("messages", []), 1):
        lines.append(f"## Сообщение {index}: {message.get('role')}")
        if message.get("create_time_utc"):
            lines.append(f"Время UTC: {message['create_time_utc']}")
        lines.append("")
        lines.append(message.get("text", ""))
        lines.append("")
    path.write_text("\n".join(lines), encoding="utf-8")


def write_report(
    path: Path,
    url: str,
    info: dict[str, str],
    files: list[str],
    message_count: int,
    had_initial_state: bool,
    decoded_ok: bool,
) -> None:
    now = dt.datetime.now(dt.timezone.utc).isoformat()
    lines = [
        "# Отчет об извлечении прикрепляемого материала",
        "",
        f"- Источник: {url}",
        f"- Время извлечения UTC: {now}",
        f"- Effective URL: {info.get('url_effective', '')}",
        f"- HTTP-код: {info.get('http_code', '')}",
        f"- Content-Type: {info.get('content_type', '')}",
        f"- Размер загрузки: {info.get('size_download', '')} байт",
        f"- Начальное состояние страницы найдено: {'да' if had_initial_state else 'нет'}",
        f"- Распаковка диалога выполнена: {'да' if decoded_ok else 'нет'}",
        f"- Извлечено сообщений: {message_count}",
        "",
        "## Редакции перед сохранением",
        "",
        "- Значения `Set-Cookie` в HTTP-заголовках заменены на `[REDACTED: response cookie]`.",
        "- Локальные IP, геометаданные запроса, user-agent, device/session/statsig-идентификаторы в bootstrap-состоянии страницы заменены на `[REDACTED: local request metadata]`.",
        "- Текст диалога, поток React Router и распакованные сообщения не нормализовались и не переводились.",
        "",
        "## Сохраненные файлы",
        "",
    ]
    lines.extend(f"- `{name}`" for name in sorted(files))
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    args = parse_args()
    request_file = args.request_file
    output_dir = args.output_dir or default_output_dir(request_file, args.url, args.source_name)
    output_dir.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory(prefix="fum-chatgpt-share-") as tmp:
        tmpdir = Path(tmp)
        raw_html = tmpdir / "chatgpt-share.html"
        raw_headers = tmpdir / "chatgpt-share.headers.txt"
        info = run_curl(args.url, raw_html, raw_headers)
        html_text = raw_html.read_text(encoding="utf-8", errors="replace")
        headers_text = raw_headers.read_text(encoding="utf-8", errors="replace")

    original_scripts = collect_scripts(html_text)
    sanitized_html, initial_state = sanitize_html(html_text, original_scripts)
    scripts = collect_scripts(sanitized_html)

    (output_dir / "source-url.txt").write_text(args.url + "\n", encoding="utf-8")
    (output_dir / "chatgpt-share.headers.txt").write_text(
        trim_trailing_whitespace(redact_headers(headers_text)),
        encoding="utf-8",
    )
    (output_dir / "chatgpt-share.html").write_text(
        trim_trailing_whitespace(sanitized_html),
        encoding="utf-8",
    )
    (output_dir / "chatgpt-share.visible-text.txt").write_text(
        collect_visible_text(sanitized_html),
        encoding="utf-8",
    )

    if initial_state is not None:
        (output_dir / "chatgpt-share.initial-state.json").write_text(
            json.dumps(initial_state, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )

    for index, body in enumerate(scripts):
        if len(body) > 1000 or "streamController.enqueue" in body:
            (output_dir / f"chatgpt-share.script-{index:02d}.txt").write_text(
                body,
                encoding="utf-8",
            )

    stream_parts = extract_stream_parts(scripts)
    stream_text = "\n\n--- stream part ---\n\n".join(stream_parts)
    (output_dir / "chatgpt-share.react-router-stream.txt").write_text(
        stream_text,
        encoding="utf-8",
    )

    decoded_ok = False
    messages_data: dict[str, Any] = {"message_count": 0, "messages": []}
    if stream_parts:
        try:
            decoded = decode_react_router_table(stream_text)
            decoded_ok = True
            (output_dir / "chatgpt-share.decoded-data.json").write_text(
                json.dumps(decoded, ensure_ascii=False, indent=2),
                encoding="utf-8",
            )
            messages_data = extract_messages(decoded)
            messages_data["source_url"] = args.url
            (output_dir / "chatgpt-share.messages.json").write_text(
                json.dumps(messages_data, ensure_ascii=False, indent=2),
                encoding="utf-8",
            )
            write_messages_markdown(
                output_dir / "chatgpt-share.messages.md",
                args.url,
                messages_data,
            )
        except Exception as exc:  # noqa: BLE001 - preserve failure in report.
            (output_dir / "decode-error.txt").write_text(repr(exc) + "\n", encoding="utf-8")

    files = sorted({path.name for path in output_dir.iterdir() if path.is_file()} | {"extraction-report.md"})
    write_report(
        output_dir / "extraction-report.md",
        args.url,
        info,
        files,
        int(messages_data.get("message_count", 0)),
        initial_state is not None,
        decoded_ok,
    )
    print(f"saved {output_dir}")
    print(f"messages {messages_data.get('message_count', 0)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
