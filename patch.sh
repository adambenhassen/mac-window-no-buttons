#!/bin/sh
# Inject libNoWindowButtons.dylib into the app bundle given as $1.
# Patches the bundle in place; install.sh runs this on a clone.
set -eu

app=${1:?usage: patch.sh /path/to/App.app}
here=$(cd "$(dirname "$0")" && pwd)
dylib=libNoWindowButtons.dylib
exe="$app/Contents/MacOS/$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$app/Contents/Info.plist")"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

make -C "$here" >/dev/null

# Team-restricted entitlements only work with the vendor's own signature.
codesign -d --entitlements :- "$app" >"$tmp/ent.plist" 2>/dev/null
for key in com.apple.application-identifier \
    com.apple.developer.web-browser.public-key-credential \
    keychain-access-groups; do
    /usr/libexec/PlistBuddy -c "Delete :$key" "$tmp/ent.plist" 2>/dev/null || true
done

cp "$here/$dylib" "$app/Contents/Frameworks/$dylib"
cp "$exe" "$tmp/exe"
codesign --remove-signature "$tmp/exe"
/usr/bin/python3 -I "$here/proxy_dylib.py" "$tmp/exe" \
    /usr/lib/libSystem.B.dylib "@executable_path/../Frameworks/$dylib"
mv -f "$tmp/exe" "$exe"

# Ad-hoc signature without hardened runtime, so library validation is off.
codesign --force --sign - --entitlements "$tmp/ent.plist" "$app"
codesign --verify --strict "$app"
