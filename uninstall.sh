#!/bin/sh
# Restore the unpatched Vivaldi saved by install.sh.
set -eu

app=/Applications/Vivaldi.app
backup="$HOME/Library/Application Support/mac-window-no-buttons/Vivaldi.app.orig"

if pgrep -xq Vivaldi; then
    echo "Quit Vivaldi first." >&2
    exit 1
fi
if [ ! -d "$backup" ]; then
    echo "No backup at $backup" >&2
    exit 1
fi

rm -rf "$app"
mv "$backup" "$app"
echo "Restored original Vivaldi."
