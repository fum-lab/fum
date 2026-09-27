# Извлечённый текст

Источник: <https://github.com/Roman-Kerimov/Keyboard>

## Содержимое

GitHub - Roman-Kerimov/Keyboard: You can support this project with bitcoins ₿: bc1qdwhpf590tx007qz8fet4an44rut9p42hteplng · GitHub
Skip to content
Navigation Menu
Sign in
Appearance settings
Platform
AI CODE CREATION
GitHub Copilot Write better code with AI
GitHub Copilot app Direct agents from issue to merge
MCP Registry Integrate external tools
DEVELOPER WORKFLOWS
Actions Automate any workflow
Codespaces Instant dev environments
Issues Plan and track work
Code Review Manage code changes
Code Quality Enforce quality at merge
APPLICATION SECURITY
GitHub Advanced Security Find and fix vulnerabilities
Code security Secure your code as you build
Secret protection Stop leaks before they start
EXPLORE
Why GitHub
Documentation
Blog
Changelog
Marketplace
View all features
Solutions
BY COMPANY SIZE
Enterprises
Small and medium teams
Startups
Nonprofits
BY USE CASE
App Modernization
DevSecOps
DevOps
CI/CD
View all use cases
BY INDUSTRY
Healthcare
Financial services
Manufacturing
Government
View all industries
View all solutions
Resources
EXPLORE BY TOPIC
AI
Software Development
DevOps
Security
View all topics
EXPLORE BY TYPE
Customer stories
Events & webinars
Ebooks & reports
Business insights
GitHub Skills
SUPPORT & SERVICES
Documentation
Customer support
Community forum
Trust center
Partners
View all resources
Open Source
COMMUNITY
GitHub Sponsors Fund open source developers
PROGRAMS
Security Lab
Maintainer Community
GitHub Stars
Archive Program
REPOSITORIES
Topics
Trending
Collections
Enterprise
ENTERPRISE SOLUTIONS
Enterprise platform AI-powered developer platform
AVAILABLE ADD-ONS
GitHub Advanced Security Enterprise-grade security features
Copilot for Business Enterprise-grade AI features
Premium Support Enterprise-grade 24/7 support
Pricing
Search /
Sign in
Sign up
Appearance settings
You signed in with another tab or window. Reload to refresh your session. You signed out in another tab or window. Reload to refresh your session. You switched accounts on another tab or window. Reload to refresh your session. Dismiss alert
Roman-Kerimov / Keyboard Public
Notifications You must be signed in to change notification settings
Fork 0
Star 1
Code
Issues 16
Pull requests 0
Discussions
Actions
Projects
Security and quality 0
Insights
Additional navigation options
Code
Issues
Pull requests
Discussions
Actions
Projects
Security and quality
Insights
main
Branches Tags
Go to file
Code
Open more actions menu
Latest commit
History
1,350 Commits
1,350 Commits
Folders and files
Name Name
Last commit message
Last commit date
BuildUnicodeData
BuildUnicodeData
BuildUnicodeDataDebug
BuildUnicodeDataDebug
CLDR @ f800890
CLDR @ f800890
Emoji
Emoji
Keyboard.xcodeproj
Keyboard.xcodeproj
KeyboardExtensionModule
KeyboardExtensionModule
KeyboardGuide
KeyboardGuide
KeyboardModule
KeyboardModule
Keyboard_iOS
Keyboard_iOS
Keyboard_iOSExtension
Keyboard_iOSExtension
Keyboard_iOSTests
Keyboard_iOSTests
Keyboard_macOS
Keyboard_macOS
Keyboard_macOSTests
Keyboard_macOSTests
SyncPackageRevisions
SyncPackageRevisions
UCD
UCD
UnicodeData
UnicodeData
UnicodeDataTests
UnicodeDataTests
Unihan
Unihan
.gitignore
.gitignore
.gitmodules
.gitmodules
BuildEnvironment
BuildEnvironment
LICENSE
LICENSE
README.md
README.md
View all files
Repository files navigation
README
CC0-1.0 license
More items
Keyboard
Keyboard without modes.
The layout with enlarged buttons allows for more accurate and faster typing.
Use swipes to input capital letters and additional symbols, diacritical marks, as well as combine letters into ligatures.
Russian language can be typed using Russian Latin alphabet and converted by entering the language code at the end of the paragraph.
The built-in calculator enables calculations in any text field.
Installation
https://testflight.apple.com/join/ARg06zl2
Some Use Cases
In the Shift mode, which converts buttons to uppercase, simply touch the button and swipe upwards:
a↑ — will give A
b↑ — will give B
Instead of the 123 key, which switches the buttons to another mode, simply swipe downwards to obtain numbers or additional characters:
(in the case of QWERTY)
t↓ — will give 5
u↓ — will give %
If there are more than one symbol shown below, to access the second one, you need to do the following:
d↓ — will give × — first symbol
d↓→ — will give ⋅ — second symbol
d↓→↓ — will give ∗ — third symbol
Other languages with Latin Script
Instead of switching to a layout, for example, for the German language, which also converts buttons to a new mode, you need to do the following:
(Type 'a', then touch 'e' and swipe diagonally upwards-left)
ae↖︎ — will give ä
oe↖︎ — will give ö
ue↖︎ — will give ü
This will work with any other letters as well.
ye↖︎ — will give ÿ and so on.
To type 'ß', do the following:
ss← — will give ß
For umlauts, use 'v' instead of 'e':
s↖︎ — will give š
For cedillas, use 's':
cs↙︎ — will give ç
For acute accents, use 'a':
oa↖︎ — will give ó
For grave accents, use 'g':
ug↖︎ — will give ù
For breves, use 'u':
au↖︎ — will give ă
For ligatures, do the following:
ae← — will give æ
For MFA symbols, do the following:
sh← — will give ʃ
zh← — will give ʒ
gh← — will give ɣ
To choose alternative forms of letters, rotations, or reflections, use the sequence of swipes →↓←
w→ — will give ʍ
v→ — will give ʌ
m→ — will give ɯ
k→ — will give ʞ
a→ — will give ə
a→↓ — will give ɐ
and so on.
For languages with non-Latin scripts
For typing in Cyrillic, instead of switching keyboard layouts, we write a paragraph of text, and at the end, we add the language code followed by a space. Then, you can press the blue autocomplete button:
Длинный абзац текста. ru — will give Длинный абзац текста .
Search by Unicode characters
Instead of switching to the system keyboard layout, emojis work through emoji search and other Unicode characters.
Through the search, you can also type flags and currency symbols using country codes:
ru — will give 🇷🇺, ₽
ua — will give 🇺🇦, ₴
Calculator
Oh, and there's a calculator available everywhere:
2+2×2 — will immediately replace this expression with the result 6
2+2×2= — will add the result after the equal sign without replacing the expression.
About
You can support this project with bitcoins ₿: bc1qdwhpf590tx007qz8fet4an44rut9p42hteplng
Resources
Readme
CC0-1.0 license
Activity
Stars
1 star
Watchers
1 watching
Forks
0 forks
Report repository
Releases
Packages
Contributors
Languages
Footer
© 2026 GitHub, Inc.
Footer navigation
Terms
Privacy
Security
Status
Community
Docs
Contact
Manage cookies
Do not share my personal information
You can’t perform that action at this time.

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-23 03:56:03 MSK -->
<!-- content-sha256: sha256:569cf0da346e669025dc3b278b0c25d2418eb34bb2a83e142fe4e71f5917a3be -->
<!-- FUM-MD-RECENCY:END -->
