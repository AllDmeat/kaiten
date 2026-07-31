import ArgumentParser
import KaitenSDK
import Testing

@testable import kaiten

@Suite("CLI validation")
struct CLIValidationTests {
  @Test("Card member role parser rejects unknown value")
  func cardMemberRoleRejectsUnknown() {
    #expect(throws: ValidationError.self) {
      _ = try parseCardMemberRoleType(999)
    }
  }

  @Test("Card states parser trims whitespace")
  func cardStatesTrimsWhitespace() throws {
    let parsed = try parseCardStates("1, 2")
    #expect(parsed?.count == 2)
  }

  @Test("Card states parser rejects invalid token")
  func cardStatesRejectsInvalidToken() {
    #expect(throws: ValidationError.self) {
      _ = try parseCardStates("1,abc")
    }
  }

  @Test("Lane condition parser rejects unknown value")
  func laneConditionRejectsUnknown() {
    #expect(throws: ValidationError.self) {
      _ = try parseLaneCondition(999)
    }
  }

  @Test("Column type parser rejects unknown value")
  func columnTypeRejectsUnknown() {
    #expect(throws: ValidationError.self) {
      _ = try parseColumnType(999)
    }
  }

  @Test("Integer CSV parser rejects invalid token")
  func integerCSVRejectsInvalidToken() {
    #expect(throws: ValidationError.self) {
      _ = try parseIntegerCSV("1,abc", fieldName: "ids")
    }
  }

  @Test("Global options reject legacy URL/token flags")
  func globalOptionsRejectLegacyConnectionFlags() {
    #expect(throws: Error.self) {
      _ = try GlobalOptions.parse(["--url", "https://company.kaiten.ru/api/latest"])
    }
    #expect(throws: Error.self) {
      _ = try GlobalOptions.parse(["--token", "secret"])
    }
    #expect(throws: Error.self) {
      _ = try GlobalOptions.parse(["--token-file", "/tmp/token"])
    }
  }

  @Test("Global options use selected config path")
  func globalOptionsUseSelectedConfigPath() throws {
    let explicit = try GlobalOptions.parse(["--config", "/tmp/custom-config.json"])
    #expect(explicit.selectedConfigPath == "/tmp/custom-config.json")

    let `default` = try GlobalOptions.parse([])
    #expect(`default`.selectedConfigPath == GlobalOptions.defaultConfigPath)
  }

  @Test("Card properties parser returns nil when the option is absent")
  func cardPropertiesReturnsNilWhenAbsent() throws {
    let parsed: Components.Schemas.UpdateCardRequest.propertiesPayload? =
      try parseCardProperties(nil, fieldName: "properties")
    #expect(parsed == nil)
  }

  @Test("Card properties parser accepts select and numeric values")
  func cardPropertiesAcceptsValues() throws {
    let parsed: Components.Schemas.UpdateCardRequest.propertiesPayload? =
      try parseCardProperties(
        #"{"id_299126": [106915], "id_160": 7, "id_42": null}"#,
        fieldName: "properties"
      )
    #expect(parsed != nil)
  }

  @Test("Card properties parser rejects malformed JSON")
  func cardPropertiesRejectsMalformedJSON() {
    #expect(throws: ValidationError.self) {
      let _: Components.Schemas.UpdateCardRequest.propertiesPayload? =
        try parseCardProperties("{oops", fieldName: "properties")
    }
  }

  @Test("Card properties parser rejects a non-object payload")
  func cardPropertiesRejectsNonObject() {
    #expect(throws: ValidationError.self) {
      let _: Components.Schemas.UpdateCardRequest.propertiesPayload? =
        try parseCardProperties("[1, 2]", fieldName: "properties")
    }
  }
}
