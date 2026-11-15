#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
tmp=$(/usr/bin/mktemp -d /private/tmp/fum-git-state-test-XXXXXX)
mkdir "$tmp/repo" "$tmp/control" "$tmp/cwd" "$tmp/state" "$tmp/config"
cat > "$tmp/helper" <<'EOF'
#!/bin/sh
state=${XDG_STATE_HOME:-.local/state}
mkdir -p "$state/gh"
pwd > "$state/gh/cwd"
printf 'marker\n' > "$state/gh/device-id"
printf 'username=synthetic\npassword=synthetic\n'
EOF
chmod 700 "$tmp/helper"
env -i PATH=/usr/bin:/bin git -C "$tmp/repo" init --quiet
env -i PATH=/usr/bin:/bin git -C "$tmp/control" init --quiet
printf 'protocol=https\nhost=fixture.invalid\n\n' | env -i PATH=/usr/bin:/bin GIT_TERMINAL_PROMPT=0 git -C "$tmp/control" -c credential.helper= -c "credential.helper=$tmp/helper" credential fill > "$tmp/control-out"
test -f "$tmp/control/.local/state/gh/device-id"
xcrun swiftc -swift-version 6 -strict-concurrency=complete -D FUM_SYNTHETIC "$root/Sources/main.swift" -o "$tmp/launcher"
printf 'protocol=https\nhost=fixture.invalid\n\n' | env -i FUM_TEST_HELPER="$tmp/helper" "$tmp/launcher" "$tmp/repo" "$tmp/cwd" "$tmp/state" "$tmp/config" credential fill > "$tmp/test-out"
test -f "$tmp/state/gh/device-id"
test ! -e "$tmp/repo/.local"
test "$(cat "$tmp/state/gh/cwd")" -ef "$tmp/cwd"
printf 'fixture: %s\n' "$tmp"
