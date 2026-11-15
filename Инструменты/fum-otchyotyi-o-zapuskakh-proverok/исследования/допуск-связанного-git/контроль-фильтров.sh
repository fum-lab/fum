#!/bin/sh
set -eu
case "$PWD" in *[!A-Za-z0-9/._-]*) printf 'HOLD fixture path\n' >&2; exit 2;; esac
test -x ./admission
for mode in local-control include-control nested-control; do
 mkdir "$mode"
 /usr/bin/git -c core.hooksPath=/dev/null -c init.templateDir="$PWD/template" init -q -b base "$mode/repo"
 printf 'original\n' >"$mode/repo/fixture.txt"
 /usr/bin/git -C "$mode/repo" -c core.hooksPath=/dev/null add -- fixture.txt
 if test "$mode" = nested-control; then
  mkdir "$mode/repo/nested"
  printf 'original\n' >"$mode/repo/nested/fixture.txt"
  /usr/bin/git -C "$mode/repo" -c core.hooksPath=/dev/null add -- nested/fixture.txt
 fi
 /usr/bin/git -C "$mode/repo" -c core.hooksPath=/dev/null -c user.name=fixture -c user.email=fixture@invalid commit -q -m fixture
 /usr/bin/git -C "$mode/repo" -c core.hooksPath=/dev/null worktree add -q -b fixture-linked ../work HEAD
 /usr/bin/git -C "$mode/repo" config extensions.worktreeConfig true
 /usr/bin/git -C "$mode/work" config --worktree fixture.marker benign
 if test "$mode" = nested-control; then
  printf 'changed\n' >"$mode/work/nested/fixture.txt"
  printf 'fixture.txt filter=hostile\n' >"$mode/work/nested/.gitattributes"
 else
  printf 'changed\n' >"$mode/work/fixture.txt"
  printf 'fixture.txt filter=hostile\n' >"$mode/work/.gitattributes"
  mkdir "$mode/work/nested"
 fi
 cat >"$mode-trap.sh" <<TRAP
#!/bin/sh
printf x >> "$PWD/$mode.marker"
exec /bin/cat
TRAP
 chmod 700 "$mode-trap.sh"
 if test "$mode" = include-control; then
  printf '[filter "hostile"]\n clean = %s/%s-trap.sh\n' "$PWD" "$mode" >"$mode-include.conf"
  printf '\n[include]\n path = %s/%s-include.conf\n' "$PWD" "$mode" >>"$mode/repo/.git/config"
 else
  printf '\n[filter "hostile"]\n clean = %s/%s-trap.sh\n' "$PWD" "$mode" >>"$mode/repo/.git/config"
 fi
 set +e
 /usr/bin/git -C "$PWD/$mode/work" --no-pager -c core.fsmonitor=false --work-tree="$PWD/$mode/work" diff --binary --no-ext-diff --no-textconv --ignore-submodules=dirty -- . >"$mode-control.stdout" 2>"$mode-control.stderr"
 control=$?
 set -e
 printf '%s\n' "$control" >"$mode-control.exit"
 test "$control" -eq 0
 test ! -s "$mode-control.stderr"
 test -s "$mode.marker"
 cp "$mode.marker" "$mode.before"
 set +e
 ./admission "$PWD/$mode" "$mode" >"$mode-admission.stdout" 2>"$mode-admission.stderr"
 admitted=$?
 set -e
 printf '%s\n' "$admitted" >"$mode-admission.exit"
 test "$admitted" -eq 2
 test ! -s "$mode-admission.stderr"
 /usr/bin/grep -Fx "REJECT $mode consumer=0" "$mode-admission.stdout" >/dev/null
 cmp -s "$mode.before" "$mode.marker"
 printf 'PASS %s filter-reachable admission-reject marker-unchanged\n' "$mode"
done
