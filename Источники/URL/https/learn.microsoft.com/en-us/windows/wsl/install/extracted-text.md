# Извлечённый текст

Источник: <https://learn.microsoft.com/en-us/windows/wsl/install>

## Содержимое

Install WSL | Microsoft Learn
Skip to main content Skip to Ask Learn chat experience
This browser is no longer supported.
Upgrade to Microsoft Edge to take advantage of the latest features, security updates, and technical support.
Download Microsoft Edge More info about Internet Explorer and Microsoft Edge
Table of contents Exit editor mode
Ask Learn Ask Learn
Reading mode Table of contents Read in English Add Add to Plans Edit Copy Markdown Print
Note
Access to this page requires authorization. You can try signing in or changing directories .
Access to this page requires authorization. You can try changing directories .
How to install Linux on Windows with WSL
Feedback
Summarize this article for me
In this article
Developers can access the power of both Windows and Linux at the same time on a Windows machine. The Windows Subsystem for Linux (WSL) lets developers install a Linux distribution (such as Ubuntu, OpenSUSE, Kali, Debian, Arch Linux, etc) and use Linux applications, utilities, and Bash command-line tools directly on Windows, unmodified, without the overhead of a traditional virtual machine or dualboot setup.
Prerequisites
You must be running Windows 10 version 2004 and higher (Build 19041 and higher) or Windows 11 to use the commands below. If you are on earlier versions please see the manual install page .
Install WSL command
You can now install everything you need to run WSL with a single command. Open PowerShell in administrator mode by right-clicking and selecting "Run as administrator", enter the wsl --install command, then restart your machine.
wsl --install
This command will enable the features necessary to run WSL and install the Ubuntu distribution of Linux. ( This default distribution can be changed ).
If you're running an older build, or just prefer not to use the install command and would like step-by-step directions, see WSL manual installation steps for older versions .
The first time you launch a newly installed Linux distribution, a console window will open and you'll be asked to wait for files to de-compress and be stored on your machine. All future launches should take less than a second.
Note
The above command only works if WSL is not installed at all. If you run wsl --install and see the WSL help text, please try running wsl --list --online to see a list of available distros and run wsl --install -d <DistroName> to install a distro.
If the install process hangs at 0.0%, run wsl --install --web-download -d <DistroName> to first download the distribution prior to installing.
To uninstall WSL, see Uninstall legacy version of WSL or unregister or uninstall a Linux distribution .
Change the default Linux distribution installed
By default, the installed Linux distribution will be Ubuntu. This can be changed using the -d flag.
To change the distribution installed, enter:
wsl.exe --install -d [Distro]
Replace [Distro] with the name of the distribution you would like to install.
To see a list of available Linux distributions available for download through the online store, enter:
wsl.exe --list --online
If you run into an issue during the install process, check the installation section of the troubleshooting guide .
To install a Linux distribution that is not listed as available, you can import any Linux distribution using a TAR file. Or in some cases you can install using an .appx file. You can also create your own custom Linux distribution to use with WSL.
Set up your Linux user info
Once you have installed WSL, you will need to create a user account and password for your newly installed Linux distribution. See the Best practices for setting up a WSL development environment guide to learn more.
Set up and best practices
We recommend following our Best practices for setting up a WSL development environment guide for a step-by-step walk-through of how to set up a user name and password for your installed Linux distribution(s), using basic WSL commands, installing and customizing Windows Terminal, set up for Git version control, code editing and debugging using the VS Code remote server, good practices for file storage, setting up a database, mounting an external drive, setting up GPU acceleration, and more.
Check which version of WSL you are running
You can list your installed Linux distributions and check the version of WSL each is set to by entering the command:
wsl.exe --list --verbose
To set the default version to WSL 1 or WSL 2 when a new Linux distribution is installed, use the command:
wsl.exe --set-default-version <1|2>
To set the default Linux distribution used with the wsl command, enter:
wsl.exe --set-default <Distro>
Replacing <Distro> with the name of the Linux distribution you would like to use.
For example, from PowerShell, enter: wsl -s Debian to set the default distribution to Debian.
Now running wsl npm init from Powershell will run the npm init command in Debian.
To run a specific wsl distribution from within PowerShell without changing your default distribution, use the command:
wsl.exe --distribution <DistroName>
Replacing <DistroName> with the name of the distribution you want to use.
Learn more in the guide to Basic commands for WSL .
Upgrade version from WSL 1 to WSL 2
New Linux installations, installed using the wsl --install command, will be set to WSL 2 by default.
To see whether your Linux distribution is set to WSL 1 or WSL 2, use the command: wsl -l -v .
Upgrading from WSL 1 to WSL 2 or downgrading from WSL 2 to WSL 1 can be done using the following command:
wsl.exe --set-version <Distro> <1|2>
Replacing <Distro> with the name of the Linux distribution that you want to update.
For example, wsl --set-version Ubuntu 2 will set your Ubuntu distribution to use WSL 2.
If you manually installed WSL prior to the wsl --install command being available, you may also need to enable the virtual machine optional component used by WSL 2 and install the kernel package if you haven't already done so.
To learn more, see the Command reference for WSL for a list of WSL commands, Comparing WSL 1 and WSL 2 for guidance on which to use for your work scenario, or Best practices for setting up a WSL development environment for general guidance on setting up a good development workflow with WSL.
Ways to run multiple Linux distributions with WSL
WSL supports running as many different Linux distributions as you would like to install. This can include choosing distributions from the Microsoft Store , importing a custom distribution , or building your own custom distribution .
There are several ways to run your Linux distributions once installed:
From Windows Terminal (Recommended) Using Windows Terminal supports as many command lines as you would like to install and enables you to open them in multiple tabs or window panes and quickly switch between multiple Linux distributions or other command lines (PowerShell, Command Prompt, Azure CLI, etc). You can fully customize your terminal with unique color schemes, font styles, sizes, background images, and custom keyboard shortcuts. Learn more.
You can directly open your Linux distribution by visiting the Windows Start menu and typing the name of your installed distributions. For example: "Ubuntu". This will open Ubuntu in its own console window.
From PowerShell, you can enter the name of your installed distribution. For example: ubuntu
From PowerShell, you can open your default Linux distribution inside your current command line, by entering: wsl.exe .
From PowerShell, you can use your default Linux distribution inside your current command line, without entering a new one, by entering: wsl [command] . Replacing [command] with a WSL command, such as: wsl -l -v to list installed distributions or wsl pwd to see where the current directory path is mounted in wsl. From PowerShell, the command Get-Date will provide the date from the Windows file system and wsl date will provide the date from the Linux file system.
The method you select should depend on what you're doing. If you've opened a WSL command line within a PowerShell window and want to exit, enter the command: exit .
Want to try the latest WSL preview features?
Try the most recent features or updates to WSL by joining the Windows Insiders Program . Once you have joined Windows Insiders, you can choose the channel you would like to receive preview builds from inside the Windows settings menu to automatically receive any WSL updates or preview features associated with that build. You can choose from:
Canary Channel:
Ideal for highly technical users.
Preview the latest platform changes early in the development cycle.
These builds can be unstable and are released with limited to no documentation.
Dev Channel:
Ideal for enthusiasts.
Access the latest Windows 11 preview builds as we incubate new ideas and develop long lead features.
There will be some rough edges and low stability.
Beta Channel:
Ideal for early adopters.
Preview and provide feedback on pre-release features for Windows 11 in a stable environment.
Release Preview Channel:
Ideal if you want to preview fixes and certain key features, plus get optional access to the next version of Windows before it’s generally available to the world.
This channel is also recommended for commercial users.
If you prefer not switching your Windows installation to a preview channel, you can still test the latest preview of WSL by issuing the command:
wsl.exe --update --pre-release
For more information check the WSL Releases page on GitHub .
Next Steps
Let's explore the basic commands of WSL next.
Basic WSL commands
Offline install
To install WSL offline, you need to do these steps:
Download and install latest WSL MSI package from the GitHub releases page
Open a PowerShell window with admin privileges and run dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart to enable the Virtual Machine Platform optional component. You will likely need to restart your computer for this to take effect.
Install a distribution via a .wsl file. You can find URLs to download these files at DistributionInfo.json for your chosen distro.
Additional resources
Windows Command Line Blog: Install WSL with a single command now available in Windows 10 version 2004 and higher
Collaborate with us on GitHub
The source for this content can be found on GitHub, where you can also create and review issues and pull requests. For more information, see our contributor guide .
Windows Subsystem for Linux
Open a documentation issue Provide product feedback
Feedback
Was this page helpful?
Yes No No
Need help with this topic?
Want to try using Ask Learn to clarify or guide you through this topic?
Ask Learn Ask Learn
Suggest a fix?
Additional resources
Last updated on 2025-08-06
In this article
Was this page helpful?
Need help with this topic?
Want to try using Ask Learn to clarify or guide you through this topic?
Ask Learn Ask Learn
Suggest a fix?
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
<!-- last-content-edit: 2026-09-12 03:39:53 MSK -->
<!-- content-sha256: sha256:5a975f1f2da894f8ae2bf8bdd2c2232046e1638963c85e59879443f277a0176f -->
<!-- FUM-MD-RECENCY:END -->
