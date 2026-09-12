# Извлечённый текст

Источник: <https://learn.microsoft.com/en-us/powershell/module/secureboot/confirm-securebootuefi>

## Содержимое

Confirm-SecureBootUEFI (SecureBoot) | Microsoft Learn
Skip to main content Skip to in-page navigation Skip to Ask Learn chat experience
This browser is no longer supported.
Upgrade to Microsoft Edge to take advantage of the latest features, security updates, and technical support.
Download Microsoft Edge More info about Internet Explorer and Microsoft Edge
Table of contents Exit editor mode
Ask Learn Ask Learn
Reading mode Table of contents Read in English Add Add to Plans Edit Copy Markdown Print
Note
Access to this page requires authorization. You can try signing in or changing directories .
Access to this page requires authorization. You can try changing directories .
Confirm-Secure BootUEFI
Module: SecureBoot Module
Confirms that Secure Boot is enabled by checking the Secure Boot status on the local computer.
Syntax
Default (Default)
Confirm-SecureBootUEFI
Description
The Confirm-SecureBootUEFI cmdlet confirms that Secure Boot is enabled by checking the Secure Boot status on a UEFI computer.
If the computer supports Secure Boot and Secure Boot is enabled, this cmdlet returns $True.
If the computer supports Secure Boot and Secure Boot is disabled, this cmdlet returns $False.
If the computer does not support Secure Boot or is a BIOS (non-UEFI) computer, this cmdlet displays the following:
Cmdlet not supported on this platform.
If Windows PowerShell® is not run in administrator mode, this cmdlet displays the following:
Unable to set proper privileges. Access was denied.
This cmdlet requires that Windows PowerShell be run in administrator mode.
Examples
Example 1: Confirm Secure Boot
PS C:\> Confirm-SecureBootUEFI
True
This command checks whether Secure Boot is enabled on the computer.
Inputs
None
Outputs
Boolean
This cmdlet returns a Boolean.
If the computer supports Secure Boot and Secure Boot is enabled, this cmdlet returns $True.
If the computer supports Secure Boot and Secure Boot is disabled, this cmdlet returns $False.
If the computer does not support Secure Boot or is a BIOS (non-UEFI) computer, this cmdlet displays the following:
Cmdlet not supported on this platform .
Related Links
Format-SecureBootUEFI
Get-SecureBootPolicy
Get-SecureBootUEFI
Set-SecureBootUEFI
Feedback
Was this page helpful?
Yes No No
Need help with this topic?
Want to try using Ask Learn to clarify or guide you through this topic?
Ask Learn Ask Learn
Suggest a fix?
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
<!-- content-sha256: sha256:4cc0b02a194a97e8e8d12c9186afed65bf29165f37060d979cf224d2c23c9562 -->
<!-- FUM-MD-RECENCY:END -->
