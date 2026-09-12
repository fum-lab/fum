# Извлечённый текст

Источник: <https://learn.microsoft.com/en-us/windows/win32/secprov/win32-tpm>

## Содержимое

Win32_Tpm class - Win32 apps | Microsoft Learn
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
Win32_Tpm class
Feedback
Summarize this article for me
In this article
The Win32_Tpm class represents the Trusted Platform Module (TPM), a hardware security chip that provides a root of trust for a computer system.
Syntax
class Win32_Tpm
{
boolean IsActivated_InitialValue;
boolean IsEnabled_InitialValue;
boolean IsOwned_InitialValue;
string  SpecVersion;
string  ManufacturerVersion;
string  ManufacturerVersionInfo;
uint32  ManufacturerId;
string  PhysicalPresenceVersionInfo;
};
Members
The Win32_Tpm class has these types of members:
Methods
Properties
Methods
The Win32_Tpm class has these methods.
Method Description
AddBlockedCommand Adds a TPM command to the local list of commands blocked on Windows.
ChangeOwnerAuth Changes the TPM owner authorization value.
Clear Resets the TPM to its factory-default state.
ConvertToOwnerAuth Converts a user-provided passphrase to a 20-byte owner authorization value that can be used to interact with the TPM.
CreateEndorsementKeyPair Creates a 2048-bit endorsement key pair on the TPM.
Disable Allows the TPM owner to disable the TPM.
Enable Allows the TPM owner to enable the TPM.
GetPhysicalPresenceRequest Gets and returns the pending TPM physical presence operation. Use the SetPhysicalPresenceRequest method to request an operation.
GetPhysicalPresenceResponse Gets and returns the results from a TPM physical presence operation that was performed.
GetPhysicalPresenceTransition Indicates the user action that is needed to perform a TPM physical presence operation.
IsActivated Indicates whether the TPM is activated.
IsCommandBlocked Indicates whether the TPM command can run on this operating system.
IsCommandPresent Indicates whether a TPM command is supported by this computer.
IsEnabled Indicates whether the TPM is enabled.
IsEndorsementKeyPairPresent Indicates whether the TPM has an endorsement key pair.
IsOwned Indicates whether the TPM has an owner.
IsOwnerClearDisabled Indicates whether the TPM owner can clear the TPM.
IsOwnershipAllowed Indicates whether a TPM owner can be installed.
IsPhysicalClearDisabled Indicates whether a TPM physical presence operation can clear the TPM.
IsPhysicalPresenceHardwareEnabled Indicates whether this computer supports a dedicated hardware path to signal physical presence.
IsSrkAuthCompatible Indicates whether the Storage Root Key (SRK) authorization is compatible with Windows.
RemoveBlockedCommand Removes a TPM command from the local list of commands blocked by Windows.
ResetAuthLockOut Resets the time-out period or other mechanism that TPM manufacturers implement to protect against dictionary attacks on the TPM.
ResetSrkAuth Resets the Storage Root Key (SRK) authorization value to be compatible with Windows.
SelfTest Performs a self-test of the TPM and returns the result.
SetPhysicalPresenceRequest Requests a TPM physical presence operation to run.
TakeOwnership Installs an owner for the TPM.
Properties
The Win32_Tpm class has these properties.
IsActivated_InitialValue
Data type: boolean
Access type: Read-only
Indicates whether the TPM is activated.
true if the device is activated (that is, if IsActivated_InitialValue is true); otherwise, false .
This value is stored when the class is instantiated. It is possible for the TPM to change state between the instantiation and when you check this value. To check whether the TPM is activated in real time, use the IsActivated method.
Windows Server 2008 and Windows Vista: This property is not available.
IsEnabled_InitialValue
Data type: boolean
Access type: Read-only
Indicates whether the TPM is enabled.
true if the device is enabled (that is, if IsEnabled_InitialValue is true); otherwise, false .
This value is stored when the class is instantiated. It is possible for the TPM to change state between the instantiation and when you check this value. To check whether the TPM is enabled in real time, use the IsEnabled method.
Windows Server 2008 and Windows Vista: This property is not available.
IsOwned_InitialValue
Data type: boolean
Access type: Read-only
Indicates whether the TPM has an owner.
true if the device has an owner (that is, if IsOwned_InitialValue is true); otherwise, false .
This value is stored when the class is instantiated. It is possible for the TPM to change state between the instantiation and when you check this value. To check whether the TPM is owned in real time, use the IsOwned method.
Windows Server 2008 and Windows Vista: This property is not available.
ManufacturerId
Data type: uint32
Access type: Read-only
The identifying information that uniquely names the TPM manufacturer.
When the data is unavailable, zero is returned.
This integer value can be translated to a string value by interpreting each byte as an ASCII character. For example, an integer value of 1414548736 can be divided into these 4 bytes: 0x54, 0x50, 0x4D, and 0x00. Assuming the string is interpreted from left to right, this integer value translated to a string value of "TPM".
ManufacturerVersion
Data type: string
Access type: Read-only
The version of the TPM, as specified by the manufacturer.
When the data is unavailable, "Not Supported" is returned.
ManufacturerVersionInfo
Data type: string
Access type: Read-only
Other manufacturer-specific version information for the TPM.
When the data is unavailable, "Not Supported" is returned.
PhysicalPresenceVersionInfo
Data type: string
Access type: Read-only
The version of the Physical Presence Interface, a communication mechanism used to run device operations that require physical presence, that the computer supports.
This interface must be available to run TPM physical presence operations. The Win32_Tpm methods SetPhysicalPresenceRequest , GetPhysicalPresenceRequest , GetPhysicalPresenceTransition , and GetPhysicalPresenceResponse expose the capabilities of the Physical Presence Interface.
When the data is unavailable, "Not Supported" is returned.
SpecVersion
Data type: string
Access type: Read-only
The version of the Trusted Computing Group (TCG) specification that the TPM supports. This value includes the major and minor TCG specification version, the specification revision level, and the errata revision level. All values are in hexadecimal. For example, a version information of "1.2, 2, 0" indicates that the device was implemented to TCG specification version 1.2, revision level 2, and with no errata.
When the data is unavailable, "Not Supported" is returned.
Remarks
Managed Object Format (MOF) files contain the definitions for Windows Management Instrumentation (WMI) classes. MOF files are not installed as part of the Windows SDK. They are installed on the server when you add the associated role by using the Server Manager. For more information about MOF files, see Managed Object Format (MOF) .
Requirements
Requirement Value
Minimum supported client
Windows Vista [desktop apps only]
Minimum supported server
Windows Server 2008 [desktop apps only]
Namespace
Root\CIMV2\Security\MicrosoftTpm
MOF
Win32_tpm.mof
DLL
Win32_tpm.dll
Feedback
Was this page helpful?
Yes No No
Need help with this topic?
Want to try using Ask Learn to clarify or guide you through this topic?
Ask Learn Ask Learn
Suggest a fix?
Additional resources
Last updated on 2021-01-07
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
<!-- content-sha256: sha256:3e34645c61086a48227287a9852c7c49157a197bb2264468049b6f5805d7ee3a -->
<!-- FUM-MD-RECENCY:END -->
