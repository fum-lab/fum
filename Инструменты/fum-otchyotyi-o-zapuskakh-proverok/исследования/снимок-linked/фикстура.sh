#!/bin/sh
set -eu
/usr/bin/git -c core.hooksPath=/dev/null init -q repo
printf 'original\n' >repo/fixture.txt
/usr/bin/git -C repo -c core.hooksPath=/dev/null add -- fixture.txt
/usr/bin/git -C repo -c core.hooksPath=/dev/null -c user.name=fixture -c user.email=fixture@invalid commit -q -m fixture
/usr/bin/git -C repo -c core.hooksPath=/dev/null worktree add -q -b fixture-linked ../work HEAD
printf 'changed\n' >work/fixture.txt
