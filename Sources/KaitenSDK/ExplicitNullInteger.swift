/// An integer value that supports three distinct encoding states in a PATCH request body.
///
/// The integer counterpart of ``ExplicitNullString`` — see that type for the full rationale.
/// Swift's synthesized `Codable` uses `encodeIfPresent` for optional properties, so a plain
/// `Int?` cannot distinguish "don't touch this field" (field absent) from "clear this
/// field" (field present as JSON `null`).
///
/// `NullableInteger` is registered in `openapi-generator-config.yaml` via `typeOverrides.schemas`
/// to replace the generated type for the `NullableInteger` OpenAPI schema. Properties using
/// `$ref: '#/components/schemas/NullableInteger'` get generated as `NullableInteger?`, where:
///
/// | Swift value             | JSON result       | Server behavior |
/// |-------------------------|-------------------|-----------------|
/// | `nil` (outer optional)  | field absent      | field unchanged |
/// | `.some(.null)`          | `"field": null`   | field cleared   |
/// | `.some(.value(3))`      | `"field": 3`      | field set       |
///
/// Public-facing API uses `Int??` for ergonomics and maps it internally:
///
/// ```swift
/// card_hide_after_days: .from(cardHideAfterDays)
/// ```
public enum ExplicitNullInteger: Codable, Hashable, Sendable {
  /// A non-null integer value.
  case value(Int)
  /// An explicit JSON `null` — signals the server to clear the field.
  case null

  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    if container.decodeNil() {
      self = .null
    } else {
      self = .value(try container.decode(Int.self))
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

  /// Maps the public `Int??` convention onto the three encoding states.
  static func from(_ value: Int??) -> ExplicitNullInteger? {
    value.map { $0.map(ExplicitNullInteger.value) ?? .null }
  }
}

extension ExplicitNullInteger: ExpressibleByIntegerLiteral {
  public init(integerLiteral value: Int) {
    self = .value(value)
  }
}
