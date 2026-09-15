# Извлечённый текст

Источник: <https://learn.microsoft.com/en-us/visualstudio/install/create-an-offline-installation-of-visual-studio?view=vs-2022>

## Содержимое

Create an offline installation - Visual Studio (Windows) | Microsoft Learn
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
Create an offline installation package of Visual Studio for local installation
Feedback
Summarize this article for me
In this article
📣 We'd love to hear your feedback! Please take a moment to complete this survey and let us know how we can improve the layout experience. Thank you for your support!
Visual Studio works well in various computer configurations. In this article, you learn how to create an offline installation package of files for installation on the local machine .
Important
If you're an enterprise IT administrator who wants to perform a deployment of Visual Studio throughout a network of client workstations, or if you need to create an installation package of files to transfer to or install onto another machine, see the Visual Studio Administrators Guide , the create a network-based installation of Visual Studio page, and the deploy a layout onto a client machine documentation.
Use the "Download all, then install" feature
Sometimes online access is problematic. For example, you might have an unreliable internet connection or your internet connection might have low bandwidth. For situations like these, you have other methods available for acquiring Visual Studio. You can use the Download all, then install feature from the Visual Studio Installer to download an installation package on the local machine before you install it locally, or you can use the command line to create a local installation package to install locally later.
After you download the bootstrapper , run it to install Visual Studio. It first installs and then launches the latest version of the Visual Studio Installer. You can use the installer to customize and configure your installation, download installation packages, and install the product.
To complete downloading the product before installation starts, select the Download all, then install option in the dropdown at the bottom of the default Workloads tab of the Visual Studio Installer. The purpose of this feature is to download the Visual Studio packages in advance on the computer where Visual Studio will eventually be installed. By downloading the packages locally first, you can then safely disconnect from the internet before you install Visual Studio.
Note
The Download all, then install functionality downloads a Visual Studio installation package that is customized to the local machine. Don't transfer this downloaded installation package to another computer, as it's not designed to work that way.
If you want to download an installation package, host it on a network share or an intranet website, and transfer it to or install it on another machine, you need to create a network layout as described in the create a network-based installation of Visual Studio documentation.
You can also configure future updates of Visual Studio to respect the Download all, then install behavior. For more information, see the installation and download behavior documentation.
Use the command line to create a local layout
Step 1 - Download the Visual Studio bootstrapper
Download the correct bootstrapper for the version and edition of Visual Studio you want and copy it into the directory you want to use as the source location for your local layout. The bootstrapper is the executable you use to create, update, or modify your local layout. You must have an internet connection to complete this step.
Step 2 - Create a local layout
Open a command prompt with administrator privileges, go to the directory where you downloaded the bootstrapper, and use the bootstrapper's parameters to create your local layout. You need an internet connection to finish this step.
To install a language other than English, change en-US to a locale from the list of language locales . To further customize your local layout, use the list of components and workloads .
The following examples show how to create a local layout. For more examples, see create a network layout of Visual Studio and command-line parameter examples .
To create a complete local layout with all features and all languages (this operation takes a long time because there are many features), run:
vs_enterprise.exe --layout c:\localVSlayout
Note
Make sure that your full installation path is less than 80 characters and that your machine has ample storage. A complete local layout of Visual Studio requires at least 45 GB of disk space. For more information, see System requirements .
Note
Make sure that your full installation path is less than 80 characters and that your machine has ample storage. A complete local layout of Visual Studio requires at least 45 GB of disk space. For more information, see System requirements .
For .NET web and .NET desktop development for only one language, run:
vs_enterprise.exe --layout c:\localVSlayout --add Microsoft.VisualStudio.Workload.ManagedDesktop --add Microsoft.VisualStudio.Workload.NetWeb --lang en-US
For C++ desktop development including all recommended and optional components, for only one language, run:
vs_enterprise.exe --layout c:\localVSlayout --add Microsoft.VisualStudio.Workload.NativeDesktop --includeRecommended --includeOptional --lang en-US
You can also use an exported vsconfig file to customize the layout content, verify a layout, or fix a layout.
Step 3 - Install Visual Studio from the local layout
When you install Visual Studio from a local layout, the Visual Studio Installer uses the local versions of the files. But if you select components during installation that aren't in the layout, the Visual Studio Installer tries to download them from the internet. To make sure you install only the files you previously downloaded, use the same command-line options you used to create the local layout. To make sure your installer doesn't try to access the internet when it's installing the product, use the --noweb switch.
For example, if you created a local installation layout by using the following command:
vs_enterprise.exe --layout c:\localVSlayout --add Microsoft.VisualStudio.Workload.ManagedDesktop --add Microsoft.VisualStudio.Workload.NetWeb --includeOptional --lang en-US
Then use the following command to run the installation and prevent the client machine from accessing the internet:
c:\localVSlayout\vs_enterprise.exe --noWeb --add Microsoft.VisualStudio.Workload.ManagedDesktop --add Microsoft.VisualStudio.Workload.NetWeb --includeOptional
Important
When Visual Studio is installed from a local layout, the installer records the layout path in the C:\ProgramData\Microsoft\VisualStudio\Packages\_Instances\<InstanceID>\state.json file.
Future Updates or component additions expect the layout to remain at the same path.
If the local layout is moved to a different location, the installer may not be able to find the required packages.
Important
If you're using Visual Studio Community, you might be prompted to sign in within 30 days of installation, but this prompt doesn't affect your ability to use the product.
Note
If you get an error that a signature is invalid, you must install updated certificates . Open the Certificates folder in your local layout. Double-click each of the certificate files, and then click through the Certificate Manager wizard. If you're asked for a password, leave it blank.
Support or troubleshooting
Sometimes, things can go wrong. If your Visual Studio installation fails, see Troubleshoot Visual Studio installation and upgrade issues for step-by-step guidance.
Here are a few more support options:
Use the installation chat (English only) support option for installation-related issues.
Report product issues to us by using the Report a Problem tool that appears both in the Visual Studio Installer and in the Visual Studio IDE. If you're an IT Administrator and don't have Visual Studio installed, you can submit IT Admin feedback .
Suggest a feature, track product issues, and find answers in the Visual Studio Developer Community .
Related content
Visual Studio Administrators Guide
Install certificates required for Visual Studio offline installation
Use command-line parameters to install Visual Studio
Visual Studio workload and component IDs
Update a network-based installation of Visual Studio
Install Help Viewer for offline documentation
Feedback
Was this page helpful?
Yes No No
Need help with this topic?
Want to try using Ask Learn to clarify or guide you through this topic?
Ask Learn Ask Learn
Suggest a fix?
Additional resources
Last updated on 2026-03-20
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
<!-- last-content-edit: 2026-09-15 21:13:52 MSK -->
<!-- content-sha256: sha256:dc65bba9eabd421ad3fca771eb1e37d4b7e426a1dcdea1f66b4a0d931f389808 -->
<!-- FUM-MD-RECENCY:END -->
