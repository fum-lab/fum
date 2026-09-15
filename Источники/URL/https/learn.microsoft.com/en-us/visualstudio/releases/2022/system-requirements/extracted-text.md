# Извлечённый текст

Источник: <https://learn.microsoft.com/en-us/visualstudio/releases/2022/system-requirements>

## Содержимое

Visual Studio 2022 System Requirements | Microsoft Learn
Skip to main content Skip to Ask Learn chat experience
This browser is no longer supported.
Upgrade to Microsoft Edge to take advantage of the latest features, security updates, and technical support.
Download Microsoft Edge More info about Internet Explorer and Microsoft Edge
Table of contents Exit editor mode
Ask Learn Ask Learn
Reading mode Table of contents Read in English Add Add to Plans Copy Markdown Print
Note
Access to this page requires authorization. You can try signing in or changing directories .
Access to this page requires authorization. You can try changing directories .
Visual Studio 2022 Product Family System Requirements
Feedback
Summarize this article for me
In this article
Overview
This page contains the minimum system requirements for the Visual Studio 2022 family of products. For information on compatibility, see Visual Studio 2022 Platform Targeting and Compatibility . If you need help with improving performance, see Visual Studio performance tips and tricks .
For additional information, see also What's New in Visual Studio 2022 or the Visual Studio 2022 release notes .
Tip
For older versions of Visual Studio, see the system requirements for Visual Studio 2019 , Visual Studio 2017 , Visual Studio 2015 , or Visual Studio 2013 .
How are we doing?
We would love to hear from you! For issues, let us know through the Report a Problem option in the upper right-hand.
corner of either the installer or the Visual Studio IDE itself. The icon is located in the upper right-hand corner.
You can track your issues in the Visual Studio Developer Community , where you can ask questions, find answers and submit product suggestions.
You can get free installation help through our Live Chat support .
Visual Studio 2022 System Requirements
The following products support the minimum system requirements below:
Visual Studio Enterprise 2022
Visual Studio Professional 2022
Visual Studio Community 2022
Supported Operating Systems
Visual Studio 2022 is supported on the following 64-bit operating systems:
Windows 11 supported OS versions: Home, Pro, Pro Education, Pro for Workstations, Enterprise, and Education
Supported Windows 11 OS versions can be found here: Windows 11 Enterprise and Education Support
Windows 11 ARM64
Windows Server 2025: Standard, Datacenter: Azure Edition, and Datacenter.
Windows Server 2022: Standard and Datacenter.
Windows Server 2019: Standard and Datacenter.
Windows Server 2016: Standard and Datacenter.
Each supported operating system has its own lifecycle independent of the Visual Studio support lifecycle. The Visual Studio team applies each of those lifecycle schedules to inform adding and removing support for operating system versions. An operating system may reach end of support before the Visual Studio release, at which point Visual Studio will no longer consider that operating system version supported. If an operating system is in the Extended Security Updates (ESU) phase then it is supported only with ESU patches installed.
The following environments are not supported to run Visual Studio:
32-bit and ARM32 operating systems. ARM64 Windows 10.
Windows 11 Home in S mode , Windows Enterprise IoT , Windows 10 IoT Core , Windows 10 Enterprise LTSC edition , Windows 10 S , and Windows 10 Team Edition . You may use Visual Studio 2022 to build apps that run on these editions of Windows.
Server IoT and Minimal Server Interface options for Windows Server.
Administrator protection mode . The following development scenarios require running Visual Studio as an administrator .
Windows containers, except for the Visual Studio Build Tools.
Virtual machine environments that are not persistent, or do not have a full Windows operating system.
Application virtualization solutions, such as Microsoft App-V or MSIX for Windows, or third-party app virtualization technologies.
Multiple simultaneous users using the software on the same machine, including shared virtual desktop infrastructure machines or a pooled Windows Virtual Desktop hostpool.
FSLogix roaming profiles.
The following workloads and components are not supported by Visual Studio running on ARM64 operating systems:
Azure development, with the exception of the Container development tools, which are supported.
Data storage and processing, with the exception of the SQL Server Data Tools, which are supported.
Data science and analytical applications.
Python development.
Mobile development with C++.
Office/SharePoint development.
Hardware
For guidance on improving performance, see Optimize Visual Studio performance .
ARM64 or x64 processor; Quad-core or better recommended. ARM 32 processors are not supported.
Minimum of 4 GB of RAM. Many factors impact resources used; we recommend 16 GB RAM for typical professional solutions.
Windows 365 : Minimum 2 vCPU and 8 GB RAM. 4 vCPU and 16 GB of RAM recommended.
Hard disk space: Minimum of 850 MB up to 210 GB of available space, depending on features installed; typical installations require 20-50 GB of free space. We recommend installing Windows and Visual Studio on a solid-state drive (SSD) to increase performance.
Video card that supports a minimum display resolution of WXGA (1366 by 768); Visual Studio will work best at a resolution of 1920 by 1080 or higher.
Minimum resolution assumes zoom, DPI settings, and text scaling are set at 100%. If not set to 100%, minimum resolution should be scaled accordingly. For example, if you set the Windows display ‘Scale and layout’ setting on your Surface Book, which has a 3000x2000 physical display, to 200%, then Visual Studio would see a logical screen resolution of 1500x1000, meeting the minimum 1366x768 requirement.
Additional Requirements and Guidance
Administrator rights are required to install or update Visual Studio.
Refer to the Visual Studio Administrator Guide for additional considerations and guidance for how to install, deploy, update, and configure Visual Studio across an organization.
.NET Framework 4.7.2 or above is required to install Visual Studio. (.NET Framework 4.5.2 or above is required to install Visual Studio version 17.8 and earlier.) Visual Studio requires .NET Framework 4.8 to run. If .NET Framework 4.8 isn't already installed, it will be installed during setup.
Universal Windows app development, including designing, editing, and debugging, requires Windows 10. Windows Server 2019 and Windows Server 2016 can be used to build Universal Windows apps from the command line.
The WebView2 runtime is required to install Visual Studio. If it isn't already installed, it will be installed during setup. The Visual Studio installation will fail if WebView2 can't be installed successfully (either because of installation error or Group Policy install or update restrictions).
Team Foundation Server 2019 Office Integration requires Office 2016, Office 2013, or Office 2010.
Smart App Control, which is a Windows feature, is not recommended to be enabled on development machines. Any setting other than "off" might negatively impact Visual Studio performance.
The integrated Windows Terminal is supported per the minimum OS requirements for Windows Terminal , currently Windows 10 20H1. Windows Server 2016 is not supported. On OS not supported for the integrated Windows Terminal, use the Terminal that ships with that version of Windows.
Supported Languages
Visual Studio is available in English, Chinese (Simplified), Chinese (Traditional), Czech, French, German, Italian, Japanese, Korean, Polish, Portuguese (Brazil), Russian, Spanish, and Turkish. You can select the language of Visual Studio during installation. The Visual Studio Installer is available in the same fourteen languages, and will match the language of Windows, if available.
Note
Visual Studio Team Foundation Server Office Integration 2019 is available in the ten languages supported by Visual Studio Team Foundation Server 2019.
Remote Tools and IntelliTrace Standalone Collector for Visual Studio 2022 System Requirements
The Remote Tools and IntelliTrace Standalone Collector support the same system requirements as Visual Studio with the following changes:
Also supported on Windows 7, Windows Server 2008 R2 SP1, Windows 8.1, Windows Server 2012, Windows Server 2012 R2, Windows 10 on ARM, and Windows 10 Enterprise LTSC.
If x86 or AMD64/x64, requires a 1.6 GHz or faster processor.
Requires 1 GB of RAM (1.5 GB if running on a virtual machine).
Requires 1 GB of available hard disk space.
Requires 1024 by 768 or higher display resolution.
For the best experience, use the most recent update of these diagnostic tools for your version of Visual Studio.
Microsoft Visual Studio Build Tools 2022 System Requirements
The Build Tools support the same system requirements as Visual Studio with the following changes:
Also installs on the Server Core option for Windows Server Core 2022, Windows Server 2025, Windows Server 2019, and Windows Server 2016.
Also installs into a Windows container .
Requires 2.3 GB to 60 GB of available hard disk space, depending on installed features.
Microsoft Visual C++ 2015-2022 Redistributable System Requirements
To download the Visual C++ 2015-2022 Redistributable, see visualstudio.microsoft.com/downloads . The Visual C++ 2015-2022 Redistributable supports the same system requirements as Visual Studio with the following changes:
Also installs on all editions of Windows 11, Windows 10, Windows Server 2025, Windows Server 2022, Windows Server 2019, and Windows Server 2016; Windows Server 2012 R2; Windows Server 2012; Windows Server 2008 R2 SP1, and Arm64 editions of Windows.
Also installs on Windows 7 SP1 and Windows Server 2008 R2 SP1 to support applications built using the Visual C++ 2017, and Visual C++ 2015 tools.
Requires 1 GB of RAM (1.5 GB if running on a virtual machine).
Requires 50 MB of available hard disk space.
Microsoft Visual Studio Test Agent 2022 System Requirements
Visual Studio Test Agent supports the same system requirements as Visual Studio with the following changes:
Requires a 2.6 GHz or faster processor; quad-core or better recommended.
Requires 10 GB of hard disk space.
Microsoft Visual Studio Test Controller 2022 System Requirements
Visual Studio Test Controller supports the same system requirements as Visual Studio with the following changes:
Requires a 2.6 GHz or faster processor; quad-core or better recommended.
Requires 10 GB of hard disk space.
Additional resources
Last updated on 2026-04-01
In this article
en-us
Your Privacy Choices
Theme
Light
Dark
High contrast
AI Disclaimer
Previous Versions
Blog
Contribute
Privacy
Consumer Health Privacy
Terms of Use
Trademarks
© Microsoft 2026

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 21:13:52 MSK -->
<!-- content-sha256: sha256:072b15e09007beda5b4f9b8b0ffe126bc8ab33e2b6c9c2311514258add15ba31 -->
<!-- FUM-MD-RECENCY:END -->
