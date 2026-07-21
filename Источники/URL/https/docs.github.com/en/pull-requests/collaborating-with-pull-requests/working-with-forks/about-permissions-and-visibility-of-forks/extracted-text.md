# Извлечённый текст

Источник: <https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/about-permissions-and-visibility-of-forks>

## Содержимое

About permissions and visibility of forks - GitHub Docs
Skip to main content
GitHub Docs
Version: Free, Pro, & Team
Search or ask Copilot
Search or ask Copilot
Select language: current language is English
Search or ask Copilot
Search or ask Copilot
Open menu
Collapse sidebar Expand sidebar
Scroll breadcrumbs left
Home
Pull requests
Collaborate with pull requests
Working with forks
Permissions and visibility
Scroll breadcrumbs right
Pull requests
Commit changes to your project
Create & edit commits
About commits
With multiple authors
On behalf of an organization
Changing a commit message
View & compare commits
Comparing commits
Commit views
Troubleshooting commits
Commit missing in local clone
Linked to wrong user
Commit blocked by push protection
Collaborate with pull requests
Getting started
Collaborative development
Help others review your changes
Manage and standardize pull requests
Working with forks
About forks
Fork a repository
Permissions and visibility
Configure a remote repository
Syncing a fork
Allow changes to a branch
Deleted or changes visibility
Detaching a fork
Code quality features
About status checks
Required status checks
Propose changes
About branches
Create & delete branches
About pull requests
Compare branches
Creating a pull request
Create a PR from a fork
Using query parameters to create a pull request
Change the state
Request a PR review
Update the head branch
Change the base branch
Commit to PR branch from fork
Address merge conflicts
About merge conflicts
Resolve merge conflicts
Resolve merge conflicts in Git
Review changes
About PR reviews
Review proposed changes
Filter files
Methods & functions
Comment on a PR
View a PR review
Review dependency changes
Incorporate feedback
Required reviews
Dismiss a PR review
Check out a PR locally
Incorporate changes
About pull request merges
Merging a pull request
Merge PR automatically
Merge PR with merge queue
Closing a pull request
Reverting a pull request
About permissions and visibility of forks
The permissions and visibility of forks depend on whether the upstream repository is public or private, and whether it is owned by an organization.
Copy as Markdown
In this article
About permissions for creating forks
About visibility of forks
About permissions of forks
About permissions for creating forks
You can fork any public repository:
To your personal account
To an organization where you have permission to create repositories
If you have access to a private repository and the owner permits forking, you can fork the repository:
To your personal account
To an organization on GitHub Team where you have permission to create repositories
You cannot fork a private repository to an organization using GitHub Free. For more information about GitHub Team and GitHub Free, see GitHub's plans .
If you fork a private repository that belongs to a personal account, external collaborators also get access to the fork.
If you fork a private repository that belongs to an organization, teams within the organization get access to the fork, but external collaborators do not.
You can add an external collaborator to a fork of a private repository owned by an organization if you are an organization owner, or if your organization allows repository administrators to invite external collaborators, and the external collaborator also has access to the upstream repository.
If you're a member of an enterprise with managed users, there are further restrictions on the repositories you can fork.  For more information, see About Enterprise Managed Users in the GitHub Enterprise Cloud documentation.
Organizations can allow or prevent the forking of any private repositories owned by the organization. For more information, see Managing the forking policy for your organization .
About visibility of forks
A fork is a new repository that shares code and visibility settings with the upstream repository. All forks of public repositories are public. You cannot change the visibility of a fork.
All repositories belong to a repository network. A repository network contains the upstream repository, the upstream repository's direct forks, and all forks of those forks. All forks in the repository network have the same visibility setting. For more information, see Understanding connections between repositories .
If you delete a repository or change the repository's visibility settings, you will affect the repository's forks. For more information, see What happens to forks when a repository is deleted or changes visibility?
If you delete a fork, any code contributions of that fork will still be accessible to the repository network.
About permissions of forks
Private forks inherit the permissions structure of the upstream repository. This helps owners of private repositories maintain control over their code. For example, if the upstream repository is private and gives read/write access to a team, then the same team will have read/write access to any forks of the private upstream repository. Only team permissions (not individual permissions) are inherited by private forks.
Note
When you change base permissions for an organization, permissions for private forks are not automatically updated. For more information, see Setting base permissions for an organization .
Public forks do not inherit the permissions structure of the upstream repository.
When you fork a public repository to your personal account, you can allow repository maintainers to push to your pull request branch. This includes giving them permission to make commits or delete the branch.
This speeds up collaboration by letting maintainers:
Make direct commits to your branch
Run tests locally before merging
You cannot give push permissions to a fork owned by an organization.
For more information, see Allowing changes to a pull request branch created from a fork .
About push rulesets for forked repositories
Push rules apply to the entire fork network for a repository, ensuring every entry point to the repository is protected. For example, if you fork a repository that has push rulesets enabled, the same push rulesets will also apply to your forked repository.
For a forked repository, the only people who have bypass permissions for a push rule are the people who have bypass permissions in the root repository.
For more information, see About rulesets .
Important security considerations
If you work with forks, or if you're the owner of a repository or organization that allows forking, it's important to be aware of the following security considerations.
Forks have their own permissions separate from the upstream repository.
The owners of a repository that has been forked have read permission to all forks in the repository's network.
Organization owners of a repository that has been forked have admin permission to forks created in personal user namespaces, including the ability to delete the fork and its branches.
Organization owners of a repository that has been forked have read permission to forks created in organizations, but do not have the ability to delete the fork or its branches.
Forks created in another organization will not be deleted when individual access is removed from the upstream repository.
Commits to any repository in a network can be accessed from any repository in the same network, including the upstream repository, even after a fork is deleted.
About forks within an organization
Forks within the same organization copy the collaborators and team settings of their upstream repositories. If a repository is owned by an organization:
That organization controls the permissions of its forks.
Any teams from the upstream permission structure that exist and are visible in the target organization or user namespace will have their permissions copied.
Admin permissions remain with the upstream owner, except when a user forks into a different organization.
If that repository is forked to a user namespace, the organization maintains admin permissions and any teams with access maintain access.
Help and support
Did you find what you needed?
Yes No
Privacy policy
Help us make these docs great!
All GitHub docs are open source. See something that's wrong or unclear? Submit a pull request.
Make a contribution
Learn how to contribute
Still need help?
Ask the GitHub community
Contact support
Legal
© 2026 GitHub, Inc.
Terms
Privacy
Status
Pricing
Expert services
Blog

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-07-21 13:27:18 MSK -->
<!-- content-sha256: sha256:3c3c37419c6c1815939c6fe2cd9547fb0781b3b0e60d7ed23c0deedbb39348f0 -->
<!-- FUM-MD-RECENCY:END -->
