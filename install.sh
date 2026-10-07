#!/bin/sh
# Patch /Applications/Vivaldi.app. The unpatched app is kept as a backup.
# Run again after every Vivaldi update.
set -eu

app=/Applications/Vivaldi.app
here=$(cd "$(dirname "$0")" && pwd)
state="$HOME/Library/Application Support/mac-window-no-buttons"
staged="$state/Vivaldi.app.staged"
backup="$state/Vivaldi.app.orig"

if pgrep -xq Vivaldi; then
    echo "Quit Vivaldi first." >&2
    exit 1
fi

mkdir -p "$state"
rm -rf "$staged"
cp -Rc "$app" "$staged"
"$here/patch.sh" "$staged"

# Only an unpatched app replaces the backup, so re-running keeps the original.
if otool -L "$app/Contents/MacOS/Vivaldi" | grep -q libNoWindowButtons; then
    rm -rf "$app"
else
    rm -rf "$backup"
    mv "$app" "$backup"
fi
mv "$staged" "$app"
echo "Installed. Original kept at $backup"
