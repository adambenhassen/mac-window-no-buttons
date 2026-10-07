#!/bin/sh
# Restore the unpatched app (default /Applications/Vivaldi.app) saved by install.sh.
set -eu

app=${1:-/Applications/Vivaldi.app}
app=${app%/}
name=$(basename "$app")
backup="$HOME/Library/Application Support/mac-window-no-buttons/$name.orig"

if pgrep -fq "^$app/Contents/MacOS/"; then
    echo "Quit $name first." >&2
    exit 1
fi
if [ ! -d "$backup" ]; then
    echo "No backup at $backup" >&2
    exit 1
fi

rm -rf "$app"
mv "$backup" "$app"
echo "Restored original $name."
