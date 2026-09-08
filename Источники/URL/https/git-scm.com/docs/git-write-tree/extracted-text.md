# Извлечённый текст

Источник: <https://git-scm.com/docs/git-write-tree>

## Содержимое

Git - git-write-tree Documentation
About
Trademark
Learn
Book
Cheat Sheet
Videos
External Links
Tools
Command Line
GUIs
Hosting
Reference
Install
Community
Table of Contents
NAME
SYNOPSIS
DESCRIPTION
OPTIONS
GIT
English ▾
Localized versions of git-write-tree manual
English
Español
Français
Português (Brasil)
Русский
Svenska
українська мова
简体中文
Want to read in your language or fix typos?
You can help translate this page .
Topics ▾
Setup and Config
git
config
help
bugreport
Credential helpers
Getting and Creating Projects
init
clone
Basic Snapshotting
add
status
diff
commit
notes
restore
reset
rm
mv
Branching and Merging
branch
checkout
switch
merge
mergetool
log
stash
tag
worktree
Sharing and Updating Projects
fetch
pull
push
remote
submodule
Inspection and Comparison
show
log
diff
difftool
range-diff
shortlog
describe
Patching
apply
cherry-pick
diff
rebase
revert
Debugging
bisect
blame
grep
Email
am
apply
imap-send
format-patch
send-email
request-pull
External Systems
svn
fast-import
Server Admin
daemon
update-server-info
Guides
gitattributes
Command-line interface conventions
Everyday Git
Frequently Asked Questions (FAQ)
Glossary
Hooks
gitignore
gitmodules
Revisions
Submodules
Tutorial
Workflows
All guides...
Administration
clean
gc
fsck
reflog
filter-branch
instaweb
archive
bundle
Plumbing Commands
cat-file
check-ignore
checkout-index
commit-tree
count-objects
diff-index
for-each-ref
hash-object
ls-files
ls-tree
merge-base
read-tree
rev-list
rev-parse
show-ref
symbolic-ref
update-index
update-ref
verify-pack
write-tree
Latest version
▾ git-write-tree last updated in 2.50.0
Changes in the git-write-tree manual
2.50.1 → 2.55.0 no changes
2.50.0 2025-06-16
2.1.4 → 2.49.1 no changes
2.0.5 2014-12-17
Check your version of git by running
git --version
NAME
git-write-tree - Create a tree object from the current index
SYNOPSIS
git write-tree [ --missing-ok ] [ --prefix= <prefix> / ]
DESCRIPTION
Creates a tree object using the current index. The name of the new
tree object is printed to standard output.
The index must be in a fully merged state.
Conceptually, git write-tree sync()s the current index contents
into a set of tree files.
In order to have that match what is actually in your directory right
now, you need to have done a git update-index phase before you did the git write-tree .
OPTIONS
--missing-ok
Normally git write-tree ensures that the objects referenced by the
directory exist in the object database.  This option disables this
check.
--prefix= <prefix> /
Writes a tree object that represents a subdirectory <prefix> .  This can be used to write the tree object
for a subproject that is in the named subdirectory.
GIT
Part of the git[1] suite
write-tree
About this site
Patches, suggestions, and comments are welcome.
Git is a member of Software Freedom Conservancy

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-08 13:49:48 MSK -->
<!-- content-sha256: sha256:9b6ee72e40994de8f021622805f841e95454894d617429212bb985b89add71df -->
<!-- FUM-MD-RECENCY:END -->
