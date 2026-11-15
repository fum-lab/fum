#!/bin/sh
set -eu
for variant in plain attributes worktree symlink include; do
 mkdir "$variant"
 /usr/bin/git -c core.hooksPath=/dev/null init -q "$variant/repo"
 printf 'original\n' >"$variant/repo/fixture.txt"
 /usr/bin/git -C "$variant/repo" -c core.hooksPath=/dev/null add -- fixture.txt
 /usr/bin/git -C "$variant/repo" -c core.hooksPath=/dev/null -c user.name=fixture -c user.email=fixture@invalid commit -q -m fixture
 /usr/bin/git -C "$variant/repo" -c core.hooksPath=/dev/null worktree add -q -b fixture-linked ../work HEAD
 done
printf '* filter=hostile\n' >attributes/work/.gitattributes
printf '[filter "hostile"]\n clean = /usr/bin/false\n' >worktree/repo/.git/worktrees/work/config.worktree
rm symlink/work/.git
ln -s /etc/passwd symlink/work/.git
printf '\n[include]\n path = /tmp/untrusted\n' >>include/repo/.git/config
