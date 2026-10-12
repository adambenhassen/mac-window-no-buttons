#!/bin/zsh
# Hides the window buttons of an unmodified app (default /Applications/Vivaldi.app)
# by injecting inject.lldb into each new instance. The app keeps its vendor
# signature, so passkeys and other restricted entitlements keep working.
# Needs SIP disabled (task_for_pid) and Xcode's LLDB.
set -u

dir=${0:A:h}
app=${1:-/Applications/Vivaldi.app}
app=${app%/}
exe="$app/Contents/MacOS/$(/usr/bin/defaults read "$app/Contents/Info" CFBundleExecutable)"
typeset -A done_pids

# Seconds since the process started (ps etime: [[dd-]hh:]mm:ss).
age() {
    local t=${$(/bin/ps -o etime= -p $1)// /} d=0 h=0
    [[ $t == *-* ]] && { d=${t%%-*}; t=${t#*-}; }
    local -a p=(${(s.:.)t})
    (( ${#p} == 3 )) && h=${p[1]#0}
    print $(( d * 86400 + h * 3600 + ${p[-2]#0} * 60 + ${p[-1]#0} ))
}

while :; do
    typeset -A alive=()
    for pid in $(/usr/bin/pgrep -f "^$exe( |\$)"); do
        alive[$pid]=1
        [[ -n ${done_pids[$pid]:-} ]] && continue
        # Pausing Vivaldi while it restores its session makes it close every
        # window and quit. Attach before that starts, or once it has settled.
        a=$(age $pid)
        (( a >= 2 && a < 30 )) && continue
        out=$(/usr/bin/xcrun lldb -b -p $pid -s "$dir/inject.lldb" 2>&1)
        if [[ $out == *nobuttons-ok* ]]; then
            done_pids[$pid]=1
            echo "$(date '+%F %T') pid $pid: buttons hidden"
        else
            # Another debugger (NoBorder) may hold the process; retry next pass.
            echo "$(date '+%F %T') pid $pid: inject failed: $(print -r -- $out | grep -m1 -i error)"
        fi
    done
    for pid in ${(k)done_pids}; do
        [[ -n ${alive[$pid]:-} ]] || unset "done_pids[$pid]"
    done
    /bin/sleep 0.3
done
