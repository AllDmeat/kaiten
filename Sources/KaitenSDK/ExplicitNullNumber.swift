/// A numeric value that supports three distinct encoding states in a PATCH request body.
///
/// The numeric counterpart of ``ExplicitNullString`` — see that type for the full rationale.
/// Swift's synthesized `Codable` uses `encodeIfPresent` for optional properties, so a plain
/// `Double?` cannot distinguish "don't touch this field" (field absent) from "clear this
/// field" (field present as JSON `null`).
///
/// `NullableNumber` is registered in `openapi-generator-config.yaml` via `typeOverrides.schemas`
/// to replace the generated type for the `NullableNumber` OpenAPI schema. Properties using
/// `$ref: '#/components/schemas/NullableNumber'` get generated as `NullableNumber?`, where:
///
/// | Swift value             | JSON result       | Server behavior |
/// |-------------------------|-------------------|-----------------|
/// | `nil` (outer optional)  | field absent      | field unchanged |
/// | `.some(.null)`          | `"field": null`   | field cleared   |
/// | `.some(.value(3))`      | `"field": 3`      | field set       |
///
/// Public-facing API uses `Double??` for ergonomics and maps it internally:
///
/// ```swift
/// number_vote: numberVote.map { $0.map(ExplicitNullNumber.value) ?? .null }
/// ```
public enum ExplicitNullNumber: Codable, Hashable, Sendable {
  /// A non-null numeric value.
  case value(Double)
  /// An explicit JSON `null` — signals the server to clear the field.
  case null

  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    if container.decodeNil() {
      self = .null
    } else {
      self = .value(try container.decode(Double.self))
    }
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .value(let number):
      try container.encode(number)
    case .null:
      try container.encodeNil()
    }
  }
}

extension ExplicitNullNumber: ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral {
  public init(floatLiteral value: Double) {
    self = .value(value)
  }

  public init(integerLiteral value: Int) {
    self = .value(Double(value))
  }
}
