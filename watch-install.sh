#!/bin/sh
# Installs a LaunchAgent that runs watch.sh [app] at login.
set -eu

dir=$(cd "$(dirname "$0")" && pwd)
app=${1:-/Applications/Vivaldi.app}
label=local.mac-window-no-buttons
plist="$HOME/Library/LaunchAgents/$label.plist"
log="$HOME/Library/Logs/mac-window-no-buttons.log"

launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
cat > "$plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>$label</string>
    <key>ProgramArguments</key>
    <array>
        <string>$dir/watch.sh</string>
        <string>$app</string>
    </array>
    <key>RunAtLoad</key><true/>
    <key>KeepAlive</key><true/>
    <key>StandardOutPath</key><string>$log</string>
    <key>StandardErrorPath</key><string>$log</string>
</dict>
</plist>
PLIST
launchctl bootstrap "gui/$(id -u)" "$plist"
echo "Installed $plist"
