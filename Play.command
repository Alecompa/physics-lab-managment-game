#!/bin/zsh
set -eu
project_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
if [[ -x /Applications/Godot.app/Contents/MacOS/Godot ]]; then
  godot_bin=/Applications/Godot.app/Contents/MacOS/Godot
elif command -v godot >/dev/null 2>&1; then
  godot_bin="$(command -v godot)"
elif command -v godot4 >/dev/null 2>&1; then
  godot_bin="$(command -v godot4)"
else
  print "Godot 4 is required. Install Godot, then open project.godot."
  read -r "reply?Press Return to close."
  exit 1
fi
exec "$godot_bin" --path "$project_dir"
