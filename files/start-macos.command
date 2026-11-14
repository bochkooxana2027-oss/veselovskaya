#!/usr/bin/env bash
# Двойной клик в Finder запускает этот файл. Всю работу делает start-linux.sh.
HERE="$(cd "$(dirname "$0")" && pwd)"
exec bash "$HERE/start-linux.sh" "$@"
