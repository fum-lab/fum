import Foundation

enum LiveGitSystemRuntime {
  static let gitExecutableURL = URL(fileURLWithPath: "/usr/bin/git", isDirectory: false)
  static let nullDevicePath = "/dev/null"
  static let disabledCommandPath = "/usr/bin/false"
  static let executableSearchPath = "/usr/bin:/bin"
  static let packObjectsCommand = "/usr/bin/git pack-objects"
}
