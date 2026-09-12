# Извлечённый текст

Источник: <https://www.python.org/downloads/release/python-3147/>

## Содержимое

Python Release Python 3.14.7 | Python.org
Notice: This page displays a fallback because interactive scripts did not run. Possible causes include disabled JavaScript or failure to load scripts or stylesheets.
Skip to content
▼ Close
Python
PSF
Docs
PyPI
Jobs
Community
▲ The Python Network
Donate
≡ Menu Search This Site GO
A A
Smaller
Larger
Reset
Socialize
LinkedIn
Mastodon
Chat on IRC
Twitter
About
Applications
Quotes
Getting Started
Help
Downloads
All releases
Source code
Windows
macOS
Android
iOS
Other Platforms
License
Alternative Implementations
Documentation
Docs
Audio/Visual Talks
Beginner's Guide
FAQ
Non-English Docs
PEP Index
Python Books
Python Essays
Community
Diversity
Mailing Lists
IRC
Forums
PSF Annual Impact Report
Python Conferences
Special Interest Groups
Python Logo
Python Wiki
Code of Conduct
Community Awards
Get Involved
Shared Stories
Success Stories
Arts
Business
Education
Engineering
Government
Scientific
Software Development
News
Python News
PSF Newsletter
PSF News
PyCon US News
Python Insider
News from the Community
Events
Python Events
User Group Events
Python Events Archive
User Group Events Archive
Submit an Event
Python 3.14.7
Release date: Aug. 5, 2026
This is the seventh maintenance release of Python 3.14
Python 3.14.7 is the seventh maintenance release of 3.14, containing around 499 bugfixes, build improvements and documentation changes from 86 contributors since 3.14.6.
Major new features of the 3.14 series, compared to 3.13
Some of the major new features and changes in Python 3.14 are:
New features
PEP 779 :  Free-threaded Python is officially supported
PEP 649 : The evaluation of annotations is now deferred, improving the semantics of using annotations.
PEP 750 : Template string literals (t-strings) for custom string processing, using the familiar syntax of f-strings.
PEP 734 : Multiple interpreters in the stdlib.
PEP 784 : A new module compression.zstd providing support for the Zstandard compression algorithm.
PEP 758 : except and except* expressions may now omit the brackets.
Syntax highlighting in PyREPL , and support for color in unittest , argparse , json and calendar CLIs.
PEP 768 : A zero-overhead external debugger interface for CPython.
UUID versions 6-8 are now supported by the uuid module, and generation of versions 3-5 are up to 40% faster.
PEP 765 : Disallow return / break / continue that exit a finally block.
PEP 741 : An improved C API for configuring Python.
A new type of interpreter . For certain newer compilers, this interpreter provides significantly better performance. Opt-in for now, requires building from source.
Improved error messages.
Builtin implementation of HMAC with formally verified code from the HACL* project.
A new command-line interface to inspect running Python processes using asynchronous tasks.
The pdb module now supports remote attaching to a running Python process .
For more details on the changes to Python 3.14, see What’s new in Python 3.14 .
Build changes
PEP 761 : Python 3.14 and onwards no longer provides PGP signatures for release artifacts. Instead, Sigstore is recommended for verifiers.
Official macOS and Windows release binaries include an experimental JIT compiler .
Official Android binary releases are now available.
Incompatible changes, removals and new deprecations
Incompatible changes
Python removals and deprecations
C API removals and deprecations
Overview of all pending deprecations
Python install manager
The installer we offer for Windows is being replaced by our new install manager, which can be installed from the Windows Store or from its download page . See our documentation for more information. The JSON file available for download contains the list of all the installable packages available as part of this release, including file URLs and hashes, but is not required to install the latest release. The traditional installer will remain available throughout the 3.14 and 3.15 releases.
More resources
Online documentation
PEP 745 , 3.14 Release Schedule
Report bugs at github.com/python/cpython/issues
Help fund Python directly (or via GitHub Sponsors ) and support the Python community
And now for something completely different
On 2nd August 2010, Shigeru Kondo calculated π to 5 trillion digits using y-cruncher 0.5.4. It took 90 days using 12 cores, 96 GiB RAM and 39 TB storage on Windows Server 2008 R2.
The current record is 314 trillion digits from 18 November 2025, calculated by Kevin O'Brien, Divyansh Jain, Brian Beeler using y-cruncher 0.8.6. This took 110 days using 384 cores, 1.5 TiB RAM and 2.4 PB storage on Ubuntu 24.04.
Enjoy the new release
Thanks to all of the many volunteers who help make Python development and these releases possible! Please consider supporting our efforts by volunteering yourself or through organisation contributions to the Python Software Foundation .
Full Changelog
Files
macOS
Download macOS installer
Windows
Download Python install manager
Source release
Download XZ compressed source tarball
Version Operating system Description File size Sigstore SBOM SHA-256 checksum
Gzipped source tarball Source release 30.0 MB .sigstore SPDX 62859805f6fdf25e 2bcbf3fa3217801e 1996887ca33e6a2a f80674bdfa2dbe07
XZ compressed source tarball Source release 22.9 MB .sigstore SPDX 3b48dac8fb59f62e aa67ac83c1eb12bd a1b7a08406dd286e 252c11a66be27f81
Android embeddable package (aarch64) Android 21.4 MB .sigstore 6d50cc3aa66e414a 439594089bcdfb5f 1264358155c70c1f 00471c24cfb477fb
Android embeddable package (x86_64) Android 21.8 MB .sigstore 2c16ce2359565cd8 c24f86cfb7563076 8ba6607e732946b2 94b969797f583b60
macOS installer macOS for macOS 10.15 and later 74.9 MB .sigstore 70c5239ad2d62925 d2947e46921d0ddd 3d35be3d2f0a2d50 db33da507dbcb419
Windows installer (64-bit) Windows Recommended 31.7 MB .sigstore SPDX 9d9eb2709ef81bf5 cd30db3c2096bdbc 4ea10087c22e62f2 7d356b36f6ae9649
Windows installer (32-bit) Windows 30.2 MB .sigstore SPDX 097fc03d4ac2de66 ee1d73a0c5d2d323 b5c0f14923f72076 86ce93149a80f0a6
Windows installer (ARM64) Windows Experimental 31.1 MB .sigstore SPDX 9a3fe120cc81bc2c b099550f794d8356 811f96a86c7f4385 19243c3485db928d
Windows embeddable package (64-bit) Windows 12.1 MB .sigstore SPDX d297e5ff01996681 7ad8502465176139 f2d3d840fa4ed84b 13bed399a6ab1f15
Windows embeddable package (32-bit) Windows 10.6 MB .sigstore SPDX 2bce2347adb05b45 65d0bf50f7a44298 f6c0bb08ae4f9d88 d051b8512a55fcf7
Windows embeddable package (ARM64) Windows 11.4 MB .sigstore SPDX f6773983c8959d42 81e48c4540cb0bdd 23e42391e4e951ce 17e7ceb52658f21c
Windows release manifest Windows Install with 'py install 3.14' 15.1 KB .sigstore b70dda5471def7e4 1e8cae246ff2394d 92fb9b918c381ce2 f357649dcae53008
▲ Back to Top
About
Applications
Quotes
Getting Started
Help
Downloads
All releases
Source code
Windows
macOS
Android
iOS
Other Platforms
License
Alternative Implementations
Documentation
Docs
Audio/Visual Talks
Beginner's Guide
FAQ
Non-English Docs
PEP Index
Python Books
Python Essays
Community
Diversity
Mailing Lists
IRC
Forums
PSF Annual Impact Report
Python Conferences
Special Interest Groups
Python Logo
Python Wiki
Code of Conduct
Community Awards
Get Involved
Shared Stories
Success Stories
Arts
Business
Education
Engineering
Government
Scientific
Software Development
News
Python News
PSF Newsletter
PSF News
PyCon US News
Python Insider
News from the Community
Events
Python Events
User Group Events
Python Events Archive
User Group Events Archive
Submit an Event
Contributing
Developer's Guide
Issue Tracker
python-dev list
Core Mentorship
Report a Security Issue
▲ Back to Top
Help & General Contact
Diversity Initiatives
Submit Website Bug
Status
Copyright ©2001-2026. Python Software Foundation Legal Statements Privacy Notice

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-12 03:39:53 MSK -->
<!-- content-sha256: sha256:6baec9dd90f4e615f39992ce6710dab4d4ba50d40db23e38f95de6f8d609cf0f -->
<!-- FUM-MD-RECENCY:END -->
