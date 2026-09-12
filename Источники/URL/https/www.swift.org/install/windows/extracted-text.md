# Извлечённый текст

Источник: <https://www.swift.org/install/windows/>

## Содержимое

Install Swift - Windows | Swift.org
Docs
Community
Packages
Blog
Install (6.3.3)
Docs
Community
Packages
Blog
Install (6.3.3)
Install Swift
Linux macOS Windows
1. Install Swift via WinGet
Install Swift via the Windows Package Manager (also known as WinGet).
First, install Windows platform dependencies: winget install --id Microsoft.VisualStudio.2022.Community --exact --force --custom "--add Microsoft.VisualStudio.Component.Windows11SDK.22621 --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.VC.Tools.ARM64" --source winget
Next, install Swift and other dependencies:
winget install --id Swift.Toolchain -e --source winget
Additional details included in Instructions
2. Select an Editor
Visual Studio Code
Visual Studio Code is a cross-platform and extensible editor that supports Swift through the Swift extension, which provides intelligent editor functionality as well as debugging and test support.
Install Swift extension
Documentation
Other editors
Any editor that supports the Language Server Protocol (LSP) can use SourceKit-LSP to provide intelligent editor functionality for Swift.
Learn more
3. Build a Command-line Tool
Let’s write a small application with your new Swift development environment.
Create a directory: mkdir MyCLI Change the directory: cd MyCLI Create a new project: swift package init --name MyCLI --type executable Run the program with swift run MyCLI You can continue to expand the program with additional features. Check out the getting started guide for command line tools.
Build a Command-line Tool Guide
Alternative install options
Manual Installation
Download the Swift installer (.exe)
Download (x86_64)
Download (arm64)
Instructions
Container
Official container images are available for compiling and running Swift on a variety of distributions.
6.3.3-windowsservercore-ltsc2022
Previous Releases
Previous releases of Swift are available for installation on Windows using the manual installer, as documented here .
Previous Releases
Release Date Toolchain Docker
Swift 6.3.2 May 11, 2026 x86_64 arm64 6.3.2-windowsservercore-ltsc2022
Swift 6.3.1 April 16, 2026 x86_64 arm64 6.3.1-windowsservercore-ltsc2022
Swift 6.3 March 24, 2026 x86_64 arm64 6.3-windowsservercore-ltsc2022
Swift 6.2.4 February 26, 2026 x86_64 arm64 6.2.4-windowsservercore-ltsc2022
Swift 6.2.3 December 12, 2025 x86_64 arm64 6.2.3-windowsservercore-ltsc2022
Swift 6.2.2 December 8, 2025 x86_64 arm64 6.2.2-windowsservercore-ltsc2022
Swift 6.2.1 November 3, 2025 x86_64 arm64 6.2.1-windowsservercore-ltsc2022
Swift 6.2 September 15, 2025 x86_64 arm64 6.2-windowsservercore-ltsc2022
Swift 6.1.3 September 5, 2025 x86_64 arm64 6.1.3-windowsservercore-ltsc2022
Swift 6.1.2 May 28, 2025 x86_64 arm64 6.1.2-windowsservercore-ltsc2022
Swift 6.1.1 May 23, 2025 x86_64 arm64 6.1.1-windowsservercore-ltsc2022
Swift 6.1 March 31, 2025 x86_64 arm64 6.1-windowsservercore-ltsc2022
Swift 6.0.3 December 11, 2024 x86_64 arm64 6.0.3-windowsservercore-ltsc2022
Swift 6.0.2 October 28, 2024 x86_64 arm64 6.0.2-windowsservercore-ltsc2022
Swift 6.0.1 September 24, 2024 x86_64 arm64 6.0.1-windowsservercore-ltsc2022
Swift 6.0 September 16, 2024 x86_64 arm64 6.0-windowsservercore-ltsc2022
Swift 5.10.1 June 5, 2024 x86_64 5.10.1-windowsservercore-ltsc2022
Swift 5.10 March 5, 2024 x86_64 5.10-windowsservercore-ltsc2022
Swift 5.9.2 December 11, 2023 x86_64 5.9.2-windowsservercore-ltsc2022
Swift 5.9.1 October 19, 2023 x86_64 5.9.1-windowsservercore-ltsc2022
Swift 5.9 1 September 18, 2023 x86_64 Signature (x86_64) Unavailable
Swift 5.8.1 1 June 1, 2023 x86_64 Signature (x86_64) Unavailable
Swift 5.8 1 March 30, 2023 x86_64 Signature (x86_64) Unavailable
Swift 5.7.3 1 January 18, 2023 x86_64 Signature (x86_64) Unavailable
Swift 5.7.2 1 December 13, 2022 x86_64 Signature (x86_64) Unavailable
Swift 5.7.1 1 November 1, 2022 x86_64 Signature (x86_64) Unavailable
Swift 5.7 1 September 12, 2022 x86_64 Signature (x86_64) Unavailable
Swift 5.6.3 1 September 2, 2022 x86_64 Signature (x86_64) Unavailable
Swift 5.6.2 1 June 15, 2022 x86_64 Signature (x86_64) Unavailable
Swift 5.6.1 1 April 8, 2022 x86_64 Signature (x86_64) Unavailable
Swift 5.6 1 March 14, 2022 x86_64 Signature (x86_64) Unavailable
Swift 5.5.3 1 February 9, 2022 x86_64 Signature (x86_64) Unavailable
Swift 5.5.2 1 December 13, 2021 x86_64 Signature (x86_64) Unavailable
Swift 5.5.1 1 October 25, 2021 x86_64 Signature (x86_64) Unavailable
Swift 5.5 1 September 20, 2021 x86_64 Signature (x86_64) Unavailable
Swift 5.4.3 1 September 9, 2021 x86_64 Signature (x86_64) Unavailable
Swift 5.4.2 1 June 28, 2021 x86_64 Signature (x86_64) Unavailable
Swift 5.4.1 1 May 25, 2021 x86_64 Signature (x86_64) Unavailable
Swift 5.4 1 April 26, 2021 x86_64 Signature (x86_64) Unavailable
Swift 5.3.3 1 December 14, 2020 x86_64 Signature (x86_64) Unavailable
Swift 5.3.2 1 December 14, 2020 x86_64 Signature (x86_64) Unavailable
Swift 5.3.1 1 November 12, 2020 x86_64 Signature (x86_64) Unavailable
Swift 5.3 1 September 16, 2020 x86_64 Signature (x86_64) Unavailable
1 Swift   toolchain is provided by Saleem Abdulrasool . Saleem is the platform champion for the Windows port of Swift and this is an official build from the Swift project.
Development Snapshots
Swift snapshots are prebuilt binaries that are automatically created from the branch. These snapshots are not official releases. They have gone through automated unit testing, but they have not gone through the full testing that is performed for official releases.
Instructions
main
May 20, 2026
Package installers (.exe)
Download (x86_64)
Download (arm64)
release/6.4.x
September 1, 2026
Package installers (.exe)
Download (x86_64)
Download (arm64)
Previous Snapshots (main)
Download
May 18, 2026
May 12, 2026
May 7, 2026
May 4, 2026
April 30, 2026
April 27, 2026
April 24, 2026
April 22, 2026
April 17, 2026
March 16, 2026
Previous Snapshots (release/6.4.x)
Download
August 28, 2026
August 26, 2026
August 25, 2026
August 14, 2026
August 1, 2026
August 1, 2026
August 1, 2026
July 23, 2026
July 23, 2026
July 23, 2026
Docs
Community
Packages
Blog
Install
Tools
Xcode
Visual Studio Code
Emacs
Neovim
Cursor
Other Editors
Community
Overview
Swift Evolution
Diversity
Mentorship
Contributing
Governance
Code of Conduct
License
Security
Color scheme preference Light Dark Auto
Copyright © 2026 Apple Inc. All rights reserved.
Swift and the Swift logo are trademarks of Apple Inc.
Privacy Policy
Cookies
API

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 03:39:53 MSK -->
<!-- content-sha256: sha256:bf0cdb364f20fba043c2668eaeac040fd7d9f645de5510919f7a38c3a5bb6bb1 -->
<!-- FUM-MD-RECENCY:END -->
