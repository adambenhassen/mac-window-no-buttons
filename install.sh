#!/bin/sh
# Patch an app (default /Applications/Vivaldi.app). The unpatched app is kept
# as a backup. Run again after every update of the app.
set -eu

app=${1:-/Applications/Vivaldi.app}
app=${app%/}
here=$(cd "$(dirname "$0")" && pwd)
state="$HOME/Library/Application Support/mac-window-no-buttons"
name=$(basename "$app")
staged="$state/$name.staged"
backup="$state/$name.orig"

if pgrep -fq "^$app/Contents/MacOS/"; then
    echo "Quit $name first." >&2
    exit 1
fi

mkdir -p "$state"
rm -rf "$staged"
cp -Rc "$app" "$staged"
"$here/patch.sh" "$staged"

# Only an unpatched app replaces the backup, so re-running keeps the original.
if otool -L "$app/Contents/MacOS/"* 2>/dev/null | grep -q libNoWindowButtons; then
    rm -rf "$app"
else
    rm -rf "$backup"
    mv "$app" "$backup"
fi
mv "$staged" "$app"
echo "Installed. Original kept at $backup"
