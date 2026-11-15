#!/bin/sh
set -eu
mkdir home tmp
/usr/bin/git -c core.hooksPath=/dev/null init -q source-repo
printf 'original\n' >source-repo/fixture.txt
/usr/bin/git -C source-repo -c core.hooksPath=/dev/null add -- fixture.txt
/usr/bin/git -C source-repo -c core.hooksPath=/dev/null -c user.name=fixture -c user.email=fixture@invalid commit -q -m fixture
/usr/bin/git -C source-repo -c core.hooksPath=/dev/null worktree add -q -b fixture-linked ../source-work HEAD
mkdir copied
/bin/cp -R source-repo source-work copied/
printf 'changed\n' >copied/source-work/fixture.txt
printf 'fixture.txt filter=trap\n' >copied/source-work/.gitattributes
cat >trap.sh <<'TRAP'
#!/bin/sh
printf hit > "$MARKER_PATH"
exec /bin/cat
TRAP
chmod 700 trap.sh
printf '\n[filter "trap"]\n clean = %s/trap.sh\n' "$PWD" >>source-repo/.git/config
set +e
MARKER_PATH="$PWD/control.DATA" /usr/bin/git -C "$PWD/copied/source-work" -c core.fsmonitor=false diff --binary --no-ext-diff --no-textconv --ignore-submodules=dirty -- . >control.stdout 2>control.stderr
control=$?
MARKER_PATH="$PWD/protected.DATA" /usr/bin/git --git-dir="$PWD/copied/source-repo/.git/worktrees/source-work" --work-tree="$PWD/copied/source-work" -c core.fsmonitor=false diff --binary --no-ext-diff --no-textconv --ignore-submodules=dirty -- . >protected.stdout 2>protected.stderr
protected=$?
set -e
printf '%s\n' "$control" >control.exit
printf '%s\n' "$protected" >protected.exit
if test "${CASE_NEGATIVE:-}" = marker; then rm control.DATA; fi
if test "${CASE_NEGATIVE:-}" = exit; then control=17; fi
test "$control" -eq 0
test "$protected" -eq 0
test -f control.DATA
test "$(cat control.DATA)" = hit
test ! -e protected.DATA
test ! -s control.stderr
test ! -s protected.stderr
cmp -s control.stdout protected.stdout
printf 'PASS synthetic path evidence; equal bytes do not prove equivalence\n'
