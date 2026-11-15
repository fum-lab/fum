#!/bin/sh
set -eu
for variant in positive local include nested info unknown swap symlink inaccessible inaccessible-empty fifo; do
 mkdir "$variant"
 /usr/bin/git -c core.hooksPath=/dev/null -c init.templateDir=$PWD/template init -q -b base "$variant/repo"
 printf 'original\n' >"$variant/repo/fixture.txt"
 /usr/bin/git -C "$variant/repo" -c core.hooksPath=/dev/null add -- fixture.txt
 /usr/bin/git -C "$variant/repo" -c core.hooksPath=/dev/null -c user.name=fixture -c user.email=fixture@invalid commit -q -m fixture
 /usr/bin/git -C "$variant/repo" -c core.hooksPath=/dev/null worktree add -q -b fixture-linked ../work HEAD
 /usr/bin/git -C "$variant/repo" config extensions.worktreeConfig true
 /usr/bin/git -C "$variant/work" config --worktree fixture.marker benign
 /usr/bin/git --git-dir="$PWD/$variant/repo/.git/worktrees/work" --work-tree="$PWD/$variant/work" -c core.fsmonitor=false read-tree --empty
 /usr/bin/git --git-dir="$PWD/$variant/repo/.git/worktrees/work" --work-tree="$PWD/$variant/work" -c core.fsmonitor=false update-index --add --cacheinfo '100644,4b48deed3a433909bfd6b6ab3d4b91348b6af464,fixture.txt'
 printf 'changed\n' >"$variant/work/fixture.txt"
 mkdir "$variant/work/nested"
 mkdir -p "$variant/repo/.git/info" "$variant/repo/.git/objects/info"
done
printf '\n[filter "hostile"]\n clean = /usr/bin/false\n' >>local/repo/.git/config
printf '\n[include]\n path = /tmp/untrusted\n' >>include/repo/.git/config
printf '* filter=hostile\n' >nested/work/nested/.gitattributes
printf '* filter=hostile\n' >info/repo/.git/info/attributes
printf unknown >unknown/repo/.git/objects/info/unexpected
rm symlink/work/.git
ln -s /etc/passwd symlink/work/.git
printf hidden >inaccessible/repo/.git/objects/info/hidden
chmod 000 inaccessible/repo/.git/objects/info
test -z "$(ls -A inaccessible-empty/repo/.git/objects/info)"
printf empty-before-chmod >inaccessible-empty.prepared
chmod 000 inaccessible-empty/repo/.git/objects/info
rm fifo/work/.git
mkfifo fifo/work/.git
