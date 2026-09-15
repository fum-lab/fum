# Извлечённый текст

Источник: <https://www.swift.org/documentation/articles/swift-sdk-for-android-getting-started.html>

## Содержимое

Getting Started with the Swift SDK for Android | Swift.org
Docs
Community
Packages
Blog
Install (6.4.0)
Docs
Community
Packages
Blog
Install (6.4.0)
Getting Started with the Swift SDK for Android
Since it was first open-sourced in 2015, Swift has grown from a language focused on creating apps for Darwin-based systems (iOS, macOS, etc.) into a cross-platform development language supporting Linux, Windows, and various embedded systems. With the release of the Swift SDK for Android, it is now possible to use Swift for Android application development as well.
Getting Started
Building a Swift package for Android requires cross-compiling: building code on
one platform (the host ) to run on a different platform (the target ). In the
context of Android, the host is a desktop operating system like macOS or Linux,
and the target is an Android device or emulator.
Cross-compilation for Android requires installing three separate components:
The Swift Toolchain : The core Swift compiler and related tools needed to
compile and run Swift code on your host machine. This includes the swift command-line and LLVM tools.
The Swift SDK for Android : An additional bundle of Swift libraries,
headers, and configuration files that extends the Swift toolchain with the
specific support needed to cross-compile for Android.
The Android NDK : The Android Native Development Kit provides
platform-specific headers, system libraries, and linker tools required to
build native binaries for Android architectures.
1. Install the Swift Toolchain
While swift may already be installed on your system (such as through an Xcode installation on macOS), using a cross-compilation Swift SDK requires using an open-source toolchain and for the Swift SDK version to match exactly.
The easiest and recommended way to manage host toolchains on macOS and Linux is to use the swiftly command . Once that has been setup, you can install the host toolchain with:
$ swiftly install latest Fetching the latest stable Swift release...
Installing Swift 6.4.0
Installing package in user home directory...
Swift 6.4.0 is installed successfully! $ swiftly use latest The global default toolchain has been set to `Swift 6.4.0` $ swift --version Apple Swift version 6.4.0 (swift-6.4.0-RELEASE)
Target: arm64-apple-macosx26.0
You can also find direct links to the open-source Swift toolchains , if you prefer manually installing then adding Swift to your PATH .
2. Install the Swift SDK for Android
Next, download and install the Swift SDK bundle using the swift sdk command:
$ swift sdk install https://download.swift.org/swift-6.4.0-release/android-sdk/swift-6.4.0-RELEASE/swift-6.4.0-RELEASE_android.artifactbundle.tar.gz --checksum 21fb555122a3d801ad943d48df7ebffdd8824de61c25c180bb792d3edaee0b43
You can provide either the URL, with a corresponding checksum, or a local
filename where the SDK can be found.
You should now see the Android Swift SDK included with the swift sdk list command:
$ swift sdk list swift-6.4.0-RELEASE_android
3. Install and configure the Android NDK
The Swift SDK for Android depends on the Android NDK, LTS version 30, to provide the headers and tools necessary for cross-compiling to Android architectures. There are a variety of ways to install the Android NDK , but the simplest is to just download and unzip the archive from the NDK Downloads page directly.
You can automate this with the following commands:
$ curl -fSL -o ndk.zip https://dl.google.com/android/repository/android-ndk-r30- $( uname -s ) .zip $ unzip -qo ndk.zip $ export ANDROID_NDK_HOME = $PWD /android-ndk-r30
If you have already installed the NDK in a different location, you can simply set the ANDROID_NDK_HOME environment variable to that location.
At this point, you will have a fully working cross-compilation toolchain for Android.
Hello World on Android
Now let’s try the canonical “Hello World” program, by first creating a directory to hold your code and initialize a new package:
$ cd /tmp $ mkdir hello $ cd hello $ swift package init --type executable
Check the new package by building and running locally for the host:
$ swift build Building for debugging...
[8/8] Applying hello
Build complete! (15.29s) $ .build/debug/hello Hello, world!
With the Swift SDK for Android installed and configured, you can now cross-compile the executable to Android for the x86_64 architecture:
$ swift build --swift-sdk swift-6.4.0-RELEASE_android --triple x86_64-unknown-linux-android23 --static-swift-stdlib Building for debugging...
[8/8] Linking hello
Build complete! (2.04s) $ file .build/x86_64-unknown-linux-android23/debug/hello .build/x86_64-unknown-linux-android23/debug/hello: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /system/bin/linker64, with debug_info, not stripped
or for the aarch64 architecture:
$ swift build --swift-sdk swift-6.4.0-RELEASE_android --triple aarch64-unknown-linux-android23 --static-swift-stdlib Building for debugging...
[8/8] Linking hello
Build complete! (2.04s) $ file .build/aarch64-unknown-linux-android23/debug/hello .build/aarch64-unknown-linux-android23/debug/hello: ELF 64-bit LSB pie executable, ARM aarch64, version 1 (SYSV), dynamically linked, interpreter /system/bin/linker64, with debug_info, not stripped
Using a connected Android device that has USB debugging enabled or a locally-running Android emulator , you can now copy the executable over, along with the required libc++_shared.so dependency from the Android NDK, and run it with the adb utility :
$ adb push .build/aarch64-unknown-linux-android23/debug/hello /data/local/tmp .build/aarch64-unknown-linux-android23/debug/hello: 1 file pushed, 0 skipped. 155.9 MB/s (69559568 bytes in 0.425s) $ adb push $ANDROID_NDK_HOME /toolchains/llvm/prebuilt/ * /sysroot/usr/lib/aarch64-linux-android/libc++_shared.so /data/local/tmp/ aarch64-linux-android/libc++_shared.so: 1 file pushed, 0 skipped. 145.7 MB/s (1794776 bytes in 0.012s) $ adb shell /data/local/tmp/hello Hello, world!
Next Steps
Congratulations, you have built and run your first Swift program on Android!
Android applications are typically not deployed as command-line executable tools. Rather, they are assembled into an .apk archive and launched as an app from the home screen. To support this, Swift modules can be built as shared libraries for each supported architecture and included in an app archive. Swift code can then be accessed from the Android app — which is typically written in Java or Kotlin — through the swift-java interoperability library and tools , which handle the Java Native Interface (JNI) for you. For advanced uses, Swift Java JNI Core is also available as a low-level interface.
Visit the Android Examples repository to see a variety of projects that demonstrate how to build full Android applications that utilize the Swift SDK for Android.
More documentation is being placed online , and these larger development topics will be expanded on in future posts. You can visit the Android category in the Swift forums to discuss and seek help with the Swift SDK for Android.
Contributed by
Marc Prud'hommeaux
Marc Prud'hommeaux works on bringing Swift application development to Android at Skip.dev.
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
Android is a trademark of Google LLC.
Privacy Policy
Cookies
API

<!-- FUM-MD-RECENCY:BEGIN -->
<!-- last-content-edit: 2026-09-15 21:21:48 MSK -->
<!-- content-sha256: sha256:f9f186878972c8086ca92ea2dfa6babfd60fe371c25bd1ef796135cb8534ada6 -->
<!-- FUM-MD-RECENCY:END -->
