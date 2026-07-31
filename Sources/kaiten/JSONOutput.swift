import ArgumentParser
import Foundation

/// Trims nested entities out of command output.
///
/// Kaiten responses embed whole related entities alongside the references to them: a card carries
/// `owner_id` *and* the entire owner, plus its board, type, lane, column, members, tags, checklists,
/// children and files. Those thirteen-odd fields dwarf the seventy scalars callers usually read, so
/// by default they are dropped and only scalars and `*_id` references survive. `--expand` names the
/// ones to keep.
///
/// Expansion is one level deep. An expanded value is itself stripped of its own nested fields, so
/// `--expand children` on an epic returns its children without *their* children. The bound is not a
/// simplification but a correctness requirement: `Card.children` and `Card.parents` are arrays of
/// cards, so unbounded expansion would make the response follow the shape of the card graph rather
/// than the request, and a cycle in that graph would not terminate at all. Callers who need a
/// deeper level ask for it with a second command.
enum JSONOutput {
  /// Expands every nested field rather than a named subset.
  static let expandAllKeyword = "all"

  /// Removes nested entities the caller did not ask for.
  ///
  /// - Parameters:
  ///   - json: a decoded response — an object, or an array of objects.
  ///   - expand: field names to keep, or `["all"]` for all of them.
  /// - Returns: the response with unexpanded nested fields removed and expanded ones flattened.
  /// - Throws: `ValidationError` if a requested name is not expandable in this response.
  static func trim(_ json: Any, expand: Set<String>) throws -> Any {
    if var envelope = json as? [String: Any], isPageEnvelope(envelope) {
      envelope["items"] = try trim(envelope["items"] ?? [], expand: expand)
      return envelope
    }
    // An empty result set has nothing to expand and nothing to validate a name against. Rejecting
    // --expand here would fail a filter that legitimately matched no rows.
    guard !objects(in: json).isEmpty else { return json }

    let expandable = expandableFields(in: json)
    let expandAll = expand.contains(expandAllKeyword)
    if !expandAll {
      let unknown = expand.subtracting(expandable).sorted()
      guard unknown.isEmpty else {
        let quoted = unknown.map { "'\($0)'" }.joined(separator: ", ")
        let available =
          expandable.isEmpty
          ? "none, this command's response has no nested entities"
          : (expandable.sorted() + [expandAllKeyword]).joined(separator: ", ")
        throw ValidationError("Unknown --expand field: \(quoted). Available: \(available)")
      }
    }
    let keep = expandAll ? expandable : expand
    return apply(json) { keeping(keep, in: $0) }
  }

  /// Names of the fields `--expand` accepts for a given response.
  ///
  /// Derived from the response itself rather than from a hand-maintained per-schema list, so new
  /// API fields become expandable without a code change and can never drift out of sync. The cost
  /// is that a field the API did not return at all is indistinguishable from a typo.
  ///
  /// An empty array counts as expandable even though it is kept by default: the key is there and
  /// simply has nothing in it. Judging by the value's type instead would make `--expand tags`
  /// succeed on a card that has tags and fail on one that does not, so a script sweeping cards
  /// would break on whichever row happened to be empty.
  static func expandableFields(in json: Any) -> Set<String> {
    if let envelope = json as? [String: Any], isPageEnvelope(envelope) {
      return expandableFields(in: envelope["items"] ?? [])
    }
    return Set(
      objects(in: json).flatMap { object in
        object.filter { isNested($1) || ($1 as? [Any])?.isEmpty == true }.keys
      }
    )
  }

  // MARK: - Trimming

  /// Drops nested fields other than `keep`, and flattens the ones kept.
  private static func keeping(_ keep: Set<String>, in object: [String: Any]) -> [String: Any] {
    var result: [String: Any] = [:]
    for (key, value) in object {
      guard isNested(value) else {
        result[key] = value
        continue
      }
      if keep.contains(key) {
        result[key] = flattened(value)
      }
    }
    return result
  }

  /// Strips an expanded value of its own nested fields — the one level of depth.
  private static func flattened(_ value: Any) -> Any {
    apply(value) { object in object.filter { _, nested in !isNested(nested) } }
  }

  /// Whether a value carries a whole entity rather than a scalar.
  ///
  /// An empty array is treated as scalar: it is indistinguishable from an empty list of IDs and
  /// costs nothing to keep, whereas dropping it would make a card with no tags differ in shape from
  /// one whose tags were merely not expanded.
  private static func isNested(_ value: Any) -> Bool {
    if value is [String: Any] { return true }
    if let array = value as? [Any] { return array.contains { $0 is [String: Any] } }
    return false
  }

  // MARK: - Pagination

  /// Whether an object is a `KaitenSDK.Page` envelope rather than an entity.
  ///
  /// Its `items` array is the response payload, not a nested entity, so trimming has to reach
  /// through it. Treating it like any other array of objects would leave a paginated command
  /// returning its page metadata and none of the rows. `hasMore` is what tells the envelope apart
  /// from an entity that merely has `items`, such as a checklist.
  private static func isPageEnvelope(_ object: [String: Any]) -> Bool {
    object["items"] is [Any] && object["hasMore"] != nil
  }

  // MARK: - Traversal

  /// Applies `transform` to the response's objects: the top-level object, or every element of a
  /// top-level array. Anything else passes through untouched.
  private static func apply(
    _ json: Any,
    _ transform: ([String: Any]) -> [String: Any]
  ) -> Any {
    if let object = json as? [String: Any] { return transform(object) }
    if let array = json as? [Any] {
      return array.map { element in
        (element as? [String: Any]).map(transform) ?? element
      }
    }
    return json
  }

  /// The response's objects, whether it is one object or an array of them.
  private static func objects(in json: Any) -> [[String: Any]] {
    if let object = json as? [String: Any] { return [object] }
    if let array = json as? [Any] { return array.compactMap { $0 as? [String: Any] } }
    return []
  }

}

// MARK: - Output

/// Encodes `value`, keeping only the nested fields named in `expand`.
///
/// Output is compact rather than pretty-printed: every consumer either pipes it into a parser or
/// reads it as an agent, and indentation is pure overhead for both. Keys are sorted so the field
/// order stays stable across runs and output diffs stay readable.
func renderJSON(_ value: some Encodable, expand: Set<String> = []) throws -> String {
  let encoder = JSONEncoder()
  encoder.outputFormatting = [.sortedKeys]
  let encoded = try encoder.encode(value)

  let json = try JSONSerialization.jsonObject(with: encoded, options: [.fragmentsAllowed])
  let trimmed = try JSONOutput.trim(json, expand: expand)
  let output = try JSONSerialization.data(
    withJSONObject: trimmed,
    options: [.sortedKeys, .fragmentsAllowed]
  )
  return String(decoding: output, as: UTF8.self)
}

/// Writes `value` to stdout as JSON, keeping only the nested fields named in `expand`.
func printJSON(_ value: some Encodable, expand: Set<String> = []) throws {
  print(try renderJSON(value, expand: expand))
}
