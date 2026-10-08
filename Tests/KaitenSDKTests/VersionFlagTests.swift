import ArgumentParser
import Testing

@testable import kaiten

@Suite("Version flag")
struct VersionFlagTests {
  @Test("Local builds report the development fallback")
  func fallback() {
    #expect(kaitenVersion == "development")
  }

  @Test("-v and --version print the version and exit successfully", arguments: ["-v", "--version"])
  func printsVersion(flag: String) {
    do {
      _ = try Kaiten.parseAsRoot([flag])
      Issue.record("Expected a clean exit")
    } catch {
      #expect(Kaiten.exitCode(for: error) == .success)
      #expect(Kaiten.message(for: error) == kaitenVersion)
    }
  }

  @Test("No arguments still shows help")
  func noArgumentsShowsHelp() throws {
    var command = try Kaiten.parseAsRoot([])
    #expect(throws: CleanExit.self) { try command.run() }
  }
}
