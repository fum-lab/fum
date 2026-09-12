# Извлечённый текст

Источник: <https://www.swift.org/install/windows/manual/>

## Содержимое

Manual Installation | Swift.org
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
Manual Installation
Install Windows platform dependencies
Swift depends on a number of developer tools when running on Windows, including the C++ toolchain and the Windows SDK. On Windows, typically these components are installed with Visual Studio .
The following Visual Studio components should be installed:
Name Component ID
MSVC v143 - VS 2022 C++ x64/x86 build tools (Latest) 1 Microsoft.VisualStudio.Component.VC.Tools.x86.x64
MSVC v143 - VS 2022 C++ ARM64/ARM64EC build tools (Latest) 1 Microsoft.VisualStudio.Component.VC.Tools.ARM64
Windows 11 SDK (10.0.22000.0) 2 Microsoft.VisualStudio.Component.Windows11SDK.22000
You should also install the following dependencies:
Python 3.10. x 3
Git for Windows
Enable Developer Mode
Developer Mode enables debugging and other settings that are necessary for Swift development. Please see Microsoft’s documentation for instructions about how to enable developer mode.
Install Swift
After the above dependencies have been installed, download and run the installer for the latest Swift stable release (6.3.3 ).
Alternatively, you may prefer to install a development snapshot for access to features that are actively under development.
By default, the Swift binaries are installed to %LocalAppData%\Programs\Swift .
At minimum, Swift requires the build tools that match your machine architecture. Installing other architectures is recommended in order to cross-compile Swift binaries to run on different machine architectures. ↩ ↩ 2
You may install a newer SDK instead. ↩
You may install the latest .x patch release, but ensure you use the specified major.minor version of Python for optimal compatibility. ↩
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
<!-- content-sha256: sha256:122d822ecc4e05bdd20ffbb738cc155ae748c4056e13d3ae89bd720388d22f2a -->
<!-- FUM-MD-RECENCY:END -->
