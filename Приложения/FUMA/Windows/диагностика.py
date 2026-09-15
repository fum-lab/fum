"""Чтение минимального Windows-профиля через уже работающую Parallels VM."""
import argparse
import base64
import json
import subprocess
import time


ЗАПРОСЫ = {
    'архитектура': '[System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString() | ConvertTo-Json -Compress',
    'версия_ОС': '(Get-CimInstance Win32_OperatingSystem).Version | ConvertTo-Json -Compress',
    'инструменты': '@(Get-Command swift,git,python,winget -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name) | ConvertTo-Json -Compress',
    'активация': 'Get-CimInstance SoftwareLicensingProduct -Filter "ApplicationID=\'55c92734-d682-4d71-983e-d6ec3f16059f\' AND PartialProductKey IS NOT NULL" | Select-Object -ExpandProperty LicenseStatus | ConvertTo-Json -Compress',
    'SDK': "Test-Path (Join-Path ([Environment]::GetFolderPath('ProgramFilesX86')) 'Windows Kits/10') | ConvertTo-Json -Compress",
    'GPU': 'Get-CimInstance Win32_VideoController | Select-Object Name,DriverVersion | ConvertTo-Json -Compress',
    'Vulkan_loader': "Test-Path (Join-Path $env:WINDIR 'System32/vulkan-1.dll') | ConvertTo-Json -Compress",
}


def команда(машина, запрос):
    # EncodedCommand — внешний контракт PowerShell: prlctl снимает обычные кавычки.
    код = base64.b64encode(запрос.encode('utf-16le')).decode('ascii')
    return ['prlctl', 'exec', машина, 'powershell.exe', '-NoProfile', '-NonInteractive', '-EncodedCommand', код]


def собрать(машина, исполнитель=subprocess.run):
    результаты = {}
    for имя, запрос in ЗАПРОСЫ.items():
        начало = time.perf_counter_ns()
        try:
            ответ = исполнитель(команда(машина, запрос), capture_output=True, timeout=30)
            текст = ответ.stdout.decode('utf-8-sig').strip()
            значение = json.loads(текст) if текст else None
            результаты[имя] = {'значение': значение, 'код': ответ.returncode, 'ошибка': None}
        except (OSError, UnicodeError, ValueError, subprocess.TimeoutExpired) as ошибка:
            результаты[имя] = {'значение': None, 'код': None, 'ошибка': type(ошибка).__name__}
        результаты[имя]['длительность_нс'] = time.perf_counter_ns() - начало
    return {'схема': 'fum.windows.диагностика.1', 'наблюдения': результаты, 'сборка_подтверждена': False, 'права_лицензии_подтверждены': False}


if __name__ == '__main__':
    парсер = argparse.ArgumentParser(description=__doc__)
    парсер.add_argument('--машина', required=True)
    параметры = парсер.parse_args()
    print(json.dumps(собрать(параметры.машина), ensure_ascii=False, indent=2))
