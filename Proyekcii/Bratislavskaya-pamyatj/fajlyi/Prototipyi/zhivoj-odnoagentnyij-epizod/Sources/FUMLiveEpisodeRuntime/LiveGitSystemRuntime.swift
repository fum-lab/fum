import Foundation

public enum LiveGitSystemRuntime {
  static let gitExecutableURL = URL(fileURLWithPath: "/usr/bin/git", isDirectory: false)
  static let nullDevicePath = "/dev/null"
  static let disabledCommandPath = "/usr/bin/false"
  public static let executableSearchPath = "/usr/bin:/bin"
  public static let shellExecutablePath = "/bin/sh"
  static let packObjectsCommand = "/usr/bin/git pack-objects"
}
