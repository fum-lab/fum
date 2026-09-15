# Извлечённый текст

Источник: <https://learn.microsoft.com/en-us/previous-versions/windows/desktop/sppwmi/softwarelicensingproduct>

## Содержимое

SoftwareLicensingProduct class | Microsoft Learn
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
SoftwareLicensingProduct class
Feedback
Summarize this article for me
In this article
This class exposes the product-specific properties and methods of the Software Licensing service.
The following syntax is simplified from Managed Object Format (MOF) code and includes all of the inherited properties.
Syntax
class SoftwareLicensingProduct
{
string   ID;
string   Name;
string   Description;
string   ApplicationID;
string   ProcessorURL;
string   MachineURL;
string   ProductKeyURL;
string   UseLicenseURL;
uint32   LicenseStatus;
uint32   LicenseStatusReason;
uint32   GracePeriodRemaining;
datetime EvaluationEndDate;
string   OfflineInstallationId;
string   PartialProductKey;
string   ProductKeyID;
string   LicenseFamily;
string   LicenseDependsOn;
boolean  LicenseIsAddon;
uint32   VLActivationInterval;
uint32   VLRenewalInterval;
string   KeyManagementServiceProductKeyID;
string   KeyManagementServiceMachine;
uint32   KeyManagementServicePort;
string   DiscoveredKeyManagementServiceMachineName;
uint32   DiscoveredKeyManagementServiceMachinePort;
uint32   IsKeyManagementServiceMachine;
uint32   KeyManagementServiceCurrentCount;
uint32   RequiredClientCount;
uint32   KeyManagementServiceUnlicensedRequests;
uint32   KeyManagementServiceLicensedRequests;
uint32   KeyManagementServiceOOBGraceRequests;
uint32   KeyManagementServiceOOTGraceRequests;
uint32   KeyManagementServiceNonGenuineGraceRequests;
uint32   KeyManagementServiceTotalRequests;
uint32   KeyManagementServiceFailedRequests;
uint32   KeyManagementServiceNotificationRequests;
uint32   GenuineStatus;
uint32   ExtendedGrace;
string   TokenActivationILID;
uint32   TokenActivationILVID;
uint32   TokenActivationGrantNumber;
string   TokenActivationCertificateThumbprint;
string   TokenActivationAdditionalInfo;
datetime TrustedTime;
};
Members
The SoftwareLicensingProduct class has these types of members:
Methods
Properties
Methods
The SoftwareLicensingProduct class has these methods.
Method Description
Activate Activates the product.
ClearKeyManagementServiceMachine Clears any previously configured KMS host name.
ClearKeyManagementServicePort Clears any previously specified port number.
DepositOfflineConfirmationId Activates the product by depositing an Offline Confirmation Identifier for this product when performing a telephone activation.
DepositTokenActivationResponse Deposits a token-based activation response.
GenerateTokenActivationChallenge Returns a token-based activation challenge.
GetPolicyInformationDWord Gets the license policy information of type DWORD.
GetPolicyInformationString Gets the license policy information of type string.
GetTokenActivationGrants Returns token-based activation grants.
SetKeyManagementServiceMachine Sets the KMS host name for volume activation.
SetKeyManagementServicePort Sets the TCP port used by a client to make requests of a KMS host. If not specified, port 1688 is used.
UninstallProductKey Uninstalls the product key.
Properties
The SoftwareLicensingProduct class has these properties.
ApplicationID
Data type: string
Access type: Read-only
Specifies the ID of current product application.
Description
Data type: string
Access type: Read-only
Specifies the product description.
DiscoveredKeyManagementServiceMachineName
Data type: string
Access type: Read-only
Specifies the last discovered KMS host name through DNS.
DiscoveredKeyManagementServiceMachinePort
Data type: uint32
Access type: Read-only
Specifies the last discovered KMS host port through DNS.
EvaluationEndDate
Data type: datetime
Access type: Read-only
Specifies the expiration date of this product application. After this date, the LicenseStatus property is set to Unlicensed and cannot be activated.
ExtendedGrace
Data type: uint32
Access type: Read-only
Specifies the extended grace time, in minutes, before the parent application goes into notification mode.
GenuineStatus
Data type: uint32
Access type: Read-only
Specifies the genuine status for the product application.
GracePeriodRemaining
Data type: uint32
Access type: Read-only
Specifies the remaining time, in minutes, before the parent application goes into notification mode. For volume clients, this is the remaining time before reactivation is required.
ID
Data type: string
Access type: Read-only
Qualifiers: Key
Specifies the product identifier.
IsKeyManagementServiceMachine
Data type: uint32
Access type: Read-only
Indicates whether KMS is enabled on the computer. The following values are possible.
Value Description
0
False
1
True
KeyManagementServiceCurrentCount
Data type: uint32
Access type: Read-only
Specifies the count of currently active KMS clients on the KMS host. A value of -1 indicates the host is not enabled as a KMS or that it has not received any client-licensing requests.
KeyManagementServiceFailedRequests
Data type: uint32
Access type: Read-only
Specifies the count of failed KMS requests.
KeyManagementServiceLicensedRequests
Data type: uint32
Access type: Read-only
Specifies the count of KMS requests from clients with LicenseStatus set to 1 (Licensed).
KeyManagementServiceMachine
Data type: string
Access type: Read-only
Specifies the name of the KMS host. Returns null if SetKeyManagementServiceMachine has not been called.
KeyManagementServiceNonGenuineGraceRequests
Data type: uint32
Access type: Read-only
Specifies the count of KMS requests from clients with LicenseStatus set to 4 (NonGenuineGrace).
KeyManagementServiceNotificationRequests
Data type: uint32
Access type: Read-only
Specifies the count of KMS requests from clients with LicenseStatus set to 5 (Notification).
KeyManagementServiceOOBGraceRequests
Data type: uint32
Access type: Read-only
Specifies the count of KMS requests from clients with LicenseStatus set to 2 (OOBGrace).
KeyManagementServiceOOTGraceRequests
Data type: uint32
Access type: Read-only
Specifies the count of KMS requests from clients with LicenseStatus set to 3 (OOTGrace).
KeyManagementServicePort
Data type: uint32
Access type: Read-only
Specifies the TCP port that is used by clients to send KMS-activation requests. Returns 0 if SetKeyManagementServicePort has not been called.
KeyManagementServiceProductKeyID
Data type: string
Access type: Read-only
Specifies the KMS product key ID. Returns null if it is not applicable.
KeyManagementServiceTotalRequests
Data type: uint32
Access type: Read-only
Specifies the count of valid KMS requests.
KeyManagementServiceUnlicensedRequests
Data type: uint32
Access type: Read-only
Specifies the count of KMS requests from clients with LicenseStatus set to 0 (Unlicensed).
LicenseDependsOn
Data type: string
Access type: Read-only
Specifies the dependency identifier for the set of SKUs used to determine license relationships for add-ons.
LicenseFamily
Data type: string
Access type: Read-only
Specifies the group identifier for the SKU used to determine license relationships for add-ons.
LicenseIsAddon
Data type: boolean
Access type: Read-only
Indicates TRUE if the product is identified as an add-on license.
LicenseStatus
Data type: uint32
Access type: Read-only
Specifies the license status of this product application. The following values are possible.
Value Description
0
Unlicensed
1
Licensed
2
OOBGrace
3
OOTGrace
4
NonGenuineGrace
5
Notification
6
ExtendedGrace
LicenseStatusReason
Data type: uint32
Access type: Read-only
Specifies the license status. Provides additional information about why a computer is in a specific licensing state.
MachineURL
Data type: string
Access type: Read-only
Specifies the software licensing server URL for the binding certificate.
Name
Data type: string
Access type: Read-only
Specifies the product name.
OfflineInstallationId
Data type: string
Access type: Read-only
Specifies the offline installation identifier of this product application. Used for offline activation. Returns a null value if a product key is not installed.
PartialProductKey
Data type: string
Access type: Read-only
Specifies the last five characters of the product key. Returns a null value if a product key is not installed.
ProcessorURL
Data type: string
Access type: Read-only
Specifies the software licensing server URL for the process certificate.
ProductKeyID
Data type: string
Access type: Read-only
Specifies the product key ID. Returns a null value if a product key is not installed.
ProductKeyURL
Data type: string
Access type: Read-only
Specifies the software licensing server URL for the product certificate.
RequiredClientCount
Data type: uint32
Access type: Read-only
Specifies the minimum number of clients that are required to connect to a KMS host to enable volume licensing.
TokenActivationAdditionalInfo
Data type: string
Access type: Read-only
Specifies additional information for token-based activation.
TokenActivationCertificateThumbprint
Data type: string
Access type: Read-only
Specifies the thumbprint of the certificate that activated the product.
TokenActivationGrantNumber
Data type: uint32
Access type: Read-only
Specifies the grant number in the token-based activation license that activated the product.
TokenActivationILID
Data type: string
Access type: Read-only
Specifies the ID of the token-based activation license that activated the product.
TokenActivationILVID
Data type: uint32
Access type: Read-only
Specifies the version of the token-based activation license that activated the product.
TrustedTime
Data type: datetime
Access type: Read-only
Specifies the trusted time for the product.
UseLicenseURL
Data type: string
Access type: Read-only
Specifies the software licensing server URL for the user license.
VLActivationInterval
Data type: uint32
Access type: Read-only
Specifies the frequency, in minutes, of how often a client will contact the KMS host before the product is licensed.
VLRenewalInterval
Data type: uint32
Access type: Read-only
Specifies the frequency, in minutes, of how often a client will contact the KMS host after the product is licensed.
Examples
For a longer discussion of accessing the SoftwareLicensingProduct class with PowerShell, see the Scripting Guy blog entry .
Requirements
Minimum supported client
Windows 7
Minimum supported server
Windows Server 2008 R2
Namespace
Root\CIMV2
MOF
SppWmi.mof
DLL
SppWmi.dll
See also
Software Licensing Classes for Windows Vista
Additional resources
Last updated on 2018-05-31
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
<!-- content-sha256: sha256:012e3945087e11fb58e6f5db0afb54c9e92d5afc15cc56fe2c448d6a0f638144 -->
<!-- FUM-MD-RECENCY:END -->
