#!/bin/sh
set -eu
test -x ./admission
./admission --test-uid >uid.stdout 2>uid.stderr
printf '%s\n' "$?" >uid.exit
test ! -s uid.stderr
/usr/bin/grep -Fx 'PASS synthetic uid predicate' uid.stdout >/dev/null
./admission --test-owned-stop >owned-stop.stdout 2>owned-stop.stderr
printf '%s\n' "$?" >owned-stop.exit
test ! -s owned-stop.stderr
/usr/bin/grep -Fx 'PASS owned child SIGKILL collected' owned-stop.stdout >/dev/null
./admission --test-reaped-child >reaped-child.stdout 2>reaped-child.stderr
printf '%s\n' "$?" >reaped-child.exit
test ! -s reaped-child.stderr
/usr/bin/grep -Fx 'PASS reaped child no signal' reaped-child.stdout >/dev/null
test -x ./ignored
set +e
./ignored "$PWD/admission" >ignored.stdout 2>ignored.stderr
ignored_status=$?
set -e
printf '%s\n' "$ignored_status" >ignored.exit
test "$ignored_status" -eq 2
test ! -s ignored.stderr
/usr/bin/grep -Fx 'REJECT sigchld consumer=0' ignored.stdout >/dev/null
for mode in positive local include nested info unknown swap symlink inaccessible inaccessible-empty fifo; do
 set +e
 ./admission "$PWD/$mode" "$mode" >"$mode.stdout" 2>"$mode.stderr"
 status=$?
 set -e
 printf '%s\n' "$status" >"$mode.exit"
 if test "$mode" = positive; then
  test "$status" -eq 0
  /usr/bin/grep -Fx 'PASS diff consumer=1' "$mode.stdout" >/dev/null
 else
  test "$status" -eq 2
  if test "$mode" = swap; then
   /usr/bin/grep -Fx "REJECT swap drift consumer=0" "$mode.stdout" >/dev/null
  else
   /usr/bin/grep -Fx "REJECT $mode consumer=0" "$mode.stdout" >/dev/null
  fi
  if /usr/bin/grep -F 'consumer=1' "$mode.stdout" >/dev/null; then exit 1; fi
 fi
 test ! -s "$mode.stderr"
done
printf 'PASS admission scenarios\n'
