#!/usr/bin/env bash
# «Веселовская» — запуск ассистента на этом компьютере.
# Первый запуск ставит зависимости в ~/.veselovskaya (около 30 МБ), потом стартует сразу.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
APP="${VESELOVSKAYA_HOME:-$HOME/.veselovskaya}"
PY="${PYTHON:-python3}"

if ! command -v "$PY" >/dev/null 2>&1; then
  echo "Python не найден."
  echo "Поставьте Python 3.10 или новее: https://www.python.org/downloads/"
  echo "Ubuntu/Debian: sudo apt install python3 python3-venv"
  exit 1
fi

if ! "$PY" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)'; then
  echo "Нужен Python 3.10 или новее, а найден: $("$PY" -V 2>&1)"
  exit 1
fi

mkdir -p "$APP"
if [ ! -f "$APP/veselovskaya.pyz" ] || [ "$HERE/veselovskaya.pyz" -nt "$APP/veselovskaya.pyz" ]; then
  cp -f "$HERE/veselovskaya.pyz" "$APP/veselovskaya.pyz"
fi

VPY="$APP/venv/bin/python"
if [ ! -x "$VPY" ]; then
  echo "Первый запуск: готовлю окружение (один раз, около минуты)…"
  if ! "$PY" -m venv "$APP/venv"; then
    echo "Не удалось создать окружение."
    echo "Ubuntu/Debian: sudo apt install python3-venv"
    exit 1
  fi
fi

if ! "$VPY" -c 'import fastapi, uvicorn' >/dev/null 2>&1; then
  echo "Ставлю зависимости (fastapi, uvicorn)…"
  "$VPY" -m pip install --quiet --upgrade pip >/dev/null 2>&1 || true
  if ! "$VPY" -m pip install --quiet "fastapi>=0.110" "uvicorn[standard]>=0.27" "pydantic>=2.5"; then
    echo "Не получилось скачать зависимости. Проверьте интернет и запустите снова."
    exit 1
  fi
fi

# пункт в меню приложений (Linux)
if [ "$(uname -s)" = "Linux" ]; then
  MENU="$HOME/.local/share/applications"
  mkdir -p "$MENU" 2>/dev/null || true
  if [ -d "$MENU" ] && [ -w "$MENU" ]; then
    cat > "$MENU/veselovskaya.desktop" <<DESK
[Desktop Entry]
Type=Application
Name=Веселовская
Comment=Ассистент: тексты, расчёты, дизайн, код, контент
Exec=bash "$HERE/start-linux.sh"
Icon=utilities-terminal
Terminal=true
Categories=Office;Utility;
DESK
  fi
fi

cd "$APP"
exec "$VPY" "$APP/veselovskaya.pyz" serve --open "$@"
