@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"

set "APP=%LOCALAPPDATA%\Veselovskaya"
set "PYCMD="

where py >nul 2>nul && set "PYCMD=py -3"
if not defined PYCMD (
  where python >nul 2>nul && set "PYCMD=python"
)
if not defined PYCMD (
  echo.
  echo Python не найден.
  echo Поставьте Python 3.10 или новее: https://www.python.org/downloads/
  echo При установке отметьте галочку "Add python.exe to PATH".
  echo.
  pause
  exit /b 1
)

%PYCMD% -c "import sys; sys.exit(0 if sys.version_info >= (3,10) else 1)"
if errorlevel 1 (
  echo Нужен Python 3.10 или новее.
  pause
  exit /b 1
)

if not exist "%APP%" mkdir "%APP%"
copy /y "veselovskaya.pyz" "%APP%\veselovskaya.pyz" >nul

if not exist "%APP%\venv\Scripts\python.exe" (
  echo Первый запуск: готовлю окружение, это один раз и около минуты...
  %PYCMD% -m venv "%APP%\venv"
  if errorlevel 1 (
    echo Не удалось создать окружение.
    echo Переустановите Python и отметьте "Add python.exe to PATH".
    pause
    exit /b 1
  )
)

"%APP%\venv\Scripts\python.exe" -c "import fastapi, uvicorn" >nul 2>nul
if errorlevel 1 (
  echo Ставлю зависимости...
  "%APP%\venv\Scripts\python.exe" -m pip install --quiet --upgrade pip >nul 2>nul
  "%APP%\venv\Scripts\python.exe" -m pip install --quiet fastapi uvicorn pydantic
  if errorlevel 1 (
    echo Не получилось скачать зависимости. Проверьте интернет и запустите снова.
    pause
    exit /b 1
  )
)

if not exist "%APP%\shortcut.made" (
  powershell -NoProfile -Command "$d=[Environment]::GetFolderPath('Desktop'); if ($d) { $s=(New-Object -ComObject WScript.Shell).CreateShortcut((Join-Path $d 'Veselovskaya.lnk')); $s.TargetPath='%~f0'; $s.WorkingDirectory='%~dp0'; $s.Save() }" >nul 2>nul
  echo ok> "%APP%\shortcut.made"
)

echo.
echo Запускаю. Браузер откроется сам.
echo Это окно закрывать не нужно - в нём работает ассистент.
echo.
"%APP%\venv\Scripts\python.exe" "%APP%\veselovskaya.pyz" serve --open
pause
