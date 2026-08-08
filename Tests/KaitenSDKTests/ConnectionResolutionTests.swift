import ArgumentParser
import Testing

@testable import kaiten

@Suite("Connection resolution")
struct ConnectionResolutionTests {
  private let configPath = "/tmp/test-config.json"

  @Test("Environment alone resolves both parameters")
  func environmentOnly() throws {
    let connection = try GlobalOptions.resolveConnection(
      environment: [
        "KAITEN_URL": "https://env.kaiten.ru/api/latest",
        "KAITEN_TOKEN": "env-token",
      ],
      configURL: nil,
      configToken: nil,
      configPath: configPath
    )
    #expect(connection.url == "https://env.kaiten.ru/api/latest")
    #expect(connection.token == "env-token")
  }

  @Test("Environment wins over config per parameter")
  func environmentWinsOverConfig() throws {
    let connection = try GlobalOptions.resolveConnection(
      environment: [
        "KAITEN_URL": "https://env.kaiten.ru/api/latest",
        "KAITEN_TOKEN": "env-token",
      ],
      configURL: "https://file.kaiten.ru/api/latest",
      configToken: "file-token",
      configPath: configPath
    )
    #expect(connection.url == "https://env.kaiten.ru/api/latest")
    #expect(connection.token == "env-token")
  }

  @Test("Each parameter falls back independently")
  func mixedSources() throws {
    let connection = try GlobalOptions.resolveConnection(
      environment: ["KAITEN_TOKEN": "env-token"],
      configURL: "https://file.kaiten.ru/api/latest",
      configToken: nil,
      configPath: configPath
    )
    #expect(connection.url == "https://file.kaiten.ru/api/latest")
    #expect(connection.token == "env-token")
  }

  @Test("Empty environment value counts as unset")
  func emptyEnvironmentFallsBack() throws {
    let connection = try GlobalOptions.resolveConnection(
      environment: ["KAITEN_URL": "", "KAITEN_TOKEN": ""],
      configURL: "https://file.kaiten.ru/api/latest",
      configToken: "file-token",
      configPath: configPath
    )
    #expect(connection.url == "https://file.kaiten.ru/api/latest")
    #expect(connection.token == "file-token")
  }

  @Test("Missing URL names KAITEN_URL in the error")
  func missingURLError() {
    #expect(throws: ValidationError.self) {
      _ = try GlobalOptions.resolveConnection(
        environment: ["KAITEN_TOKEN": "env-token"],
        configURL: nil,
        configToken: nil,
        configPath: configPath
      )
    }
    do {
      _ = try GlobalOptions.resolveConnection(
        environment: ["KAITEN_TOKEN": "env-token"],
        configURL: nil,
        configToken: nil,
        configPath: configPath
      )
    } catch let error as ValidationError {
      #expect(error.message.contains("KAITEN_URL"))
    } catch {
      Issue.record("Expected ValidationError, got \(error)")
    }
  }

  @Test("Missing token names KAITEN_TOKEN in the error")
  func missingTokenError() {
    do {
      _ = try GlobalOptions.resolveConnection(
        environment: [:],
        configURL: "https://file.kaiten.ru/api/latest",
        configToken: nil,
        configPath: configPath
      )
      Issue.record("Expected ValidationError")
    } catch let error as ValidationError {
      #expect(error.message.contains("KAITEN_TOKEN"))
    } catch {
      Issue.record("Expected ValidationError, got \(error)")
    }
  }
}
