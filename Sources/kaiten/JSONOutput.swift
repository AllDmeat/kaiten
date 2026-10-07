import ArgumentParser
import Foundation

/// Trims nested entities out of command output.
///
/// Kaiten responses embed whole related entities alongside the references to them: a card carries
/// `owner_id` *and* the entire owner, plus its board, type, lane, column, members, tags, checklists,
/// children and files. Those thirteen-odd fields dwarf the seventy scalars callers usually read, so
/// by default they are cut back to the reference alone and `--expand` names the ones to restore.
///
/// Only what something else in the response stands in for is cut. A single entity is dropped only
/// when its reference sits beside it — `owner` goes because `owner_id` stays — while a collection of
/// entities becomes the ids of its members, under its own key. Anything else is data and is passed
/// through whole: dropping a card's `properties` would lose the custom field values themselves, and
/// dropping a user's `personal_settings`, which has an `id` but no `personal_settings_id`, would
/// lose the settings. That silent loss is what this trimming exists to avoid.
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
    if var envelope = json as? [String: Any], let key = envelopePayloadKey(envelope) {
      envelope[key] = try trim(envelope[key] ?? [], expand: expand)
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
    if let envelope = json as? [String: Any], let key = envelopePayloadKey(envelope) {
      return expandableFields(in: envelope[key] ?? [])
    }
    return Set(
      objects(in: json).flatMap { object in
        object.filter { key, value in
          isEntityReference(key, in: object) || (value as? [Any])?.isEmpty == true
        }.keys
      }
    )
  }

  // MARK: - Trimming

  /// Drops nested fields other than `keep`, flattens the ones kept, and leaves an id array behind
  /// where a dropped collection would otherwise vanish without trace.
  private static func keeping(_ keep: Set<String>, in object: [String: Any]) -> [String: Any] {
    var result: [String: Any] = [:]
    for (key, value) in object {
      guard isEntityReference(key, in: object) else {
        result[key] = value
        continue
      }
      if keep.contains(key) {
        result[key] = flattened(value)
      } else if let ids = identifiers(of: value) {
        result[key] = ids
      }
    }
    return result
  }

  /// The ids of a collection's entities, which take the collection's place when it is dropped.
  ///
  /// A dropped single relation leaves its reference behind — `owner` goes, `owner_id` stays — but a
  /// collection had no such fallback, so a card with members was indistinguishable from a card with
  /// none. Keeping the ids under the collection's own key closes that without renaming anything: an
  /// empty collection and a full one report the same field, and `--expand` swaps the ids back for
  /// the entities in place.
  ///
  /// The field's element type therefore depends on `--expand` — ids by default, objects when
  /// expanded. That is what `--expand` is for, and it beats the alternative of two different field
  /// names for the same relation.
  ///
  /// Returns nil for a single object, which needs no help — its reference is already alongside it.
  /// Every element is known to carry an `id` by the time this runs; ``isEntityReference(_:in:)`` is
  /// what established that, and a collection failing it is kept whole rather than arriving here.
  private static func identifiers(of value: Any) -> [Any]? {
    guard let elements = value as? [Any] else { return nil }
    return elements.compactMap { ($0 as? [String: Any])?["id"] }
  }

  /// Strips an expanded value of its own nested fields — the one level of depth.
  private static func flattened(_ value: Any) -> Any {
    apply(value) { object in object.filter { key, _ in !isEntityReference(key, in: object) } }
  }

  /// Whether `object[key]` holds entities that something else in the response points at, rather
  /// than data that exists only here.
  ///
  /// A single object qualifies only when it carries an `id` and its reference sits beside it, as
  /// `<key>_id` or `<key>_uid`: removing `owner` costs nothing because `owner_id` says the same
  /// thing. The `id` alone is not enough — `personal_settings` carries one, yet nothing else in a
  /// user points at it, so dropping it would silently lose the settings themselves. A collection
  /// qualifies when every element carries an `id`, because those ids are what it leaves behind. A card's
  /// `properties` — the custom field values, shaped `{"id_714": [1088]}` — passes neither test and
  /// is kept whole.
  ///
  /// An empty array is data by this test, which is also the right answer: it is indistinguishable
  /// from an empty list of ids and costs nothing to keep.
  private static func isEntityReference(_ key: String, in object: [String: Any]) -> Bool {
    let value = object[key]
    if let nested = value as? [String: Any] {
      return nested["id"] != nil && (object["\(key)_id"] != nil || object["\(key)_uid"] != nil)
    }
    guard let array = value as? [Any], !array.isEmpty else { return false }
    let objects = array.compactMap { $0 as? [String: Any] }
    return objects.count == array.count && objects.allSatisfy { $0["id"] != nil }
  }

  // MARK: - Pagination

  /// The key holding the rows when an object is a pagination envelope rather than an entity.
  ///
  /// The envelope's array is the response payload, not a nested entity, so trimming has to reach
  /// through it. Treating it like any other array of objects would leave a paginated command
  /// returning its page metadata and none of the rows. A `KaitenSDK.Page` keeps its rows in
  /// `items`, and `hasMore` is what tells it apart from an entity that merely has `items`, such as
  /// a checklist. A version=2 search keeps them in `result` next to its `position` cursor, and
  /// having no `id` is what tells it apart from an entity.
  private static func envelopePayloadKey(_ object: [String: Any]) -> String? {
    if object["items"] is [Any] && object["hasMore"] != nil { return "items" }
    if object["result"] is [Any] && object["id"] == nil { return "result" }
    return nil
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
