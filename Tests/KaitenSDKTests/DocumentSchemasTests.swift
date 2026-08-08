import Foundation
import HTTPTypes
import Testing

@testable import KaitenSDK

@Suite("Document Schemas")
struct DocumentSchemasTests {

  private func makeClient(_ transport: MockClientTransport) throws -> KaitenClient {
    try KaitenClient(
      baseURL: "https://test.kaiten.ru/api/latest", token: "test-token", transport: transport)
  }

  /// `KaitenError` is not `Equatable`, so the status code is matched by pattern.
  private func expectUnexpectedResponse(
    statusCode: Int,
    sourceLocation: SourceLocation = #_sourceLocation,
    _ operation: () async throws -> Void
  ) async {
    do {
      try await operation()
      Issue.record(
        "expected KaitenError.unexpectedResponse(statusCode: \(statusCode)), no error thrown",
        sourceLocation: sourceLocation)
    } catch let error as KaitenError {
      guard case .unexpectedResponse(let code, _) = error, code == statusCode else {
        Issue.record(
          "expected KaitenError.unexpectedResponse(statusCode: \(statusCode)), got \(error)",
          sourceLocation: sourceLocation)
        return
      }
    } catch {
      Issue.record("expected KaitenError, got \(error)", sourceLocation: sourceLocation)
    }
  }

  /// Trimmed from a live response: full top-level shape, `definitions` cut down to a
  /// representative node and mark.
  private static let draft06JSON = """
    {
      "$schema": "http://json-schema.org/draft-06/schema",
      "$id": "kaiten://document-schemas/v25",
      "title": "Kaiten document data ProseMirror schema v25",
      "description": "JSON Schema representation for ProseMirror document data.",
      "allOf": [{"$ref": "#/definitions/nodes/doc"}],
      "version": "v25",
      "definitions": {
        "nodes": {
          "doc": {
            "type": "object",
            "additionalProperties": false,
            "required": ["type", "content"],
            "properties": {
              "type": {"const": "doc"},
              "content": {
                "type": "array",
                "items": {"anyOf": [{"$ref": "#/definitions/nodes/paragraph"}]},
                "minItems": 1
              }
            },
            "x-prosemirror": {"content": "block+"}
          },
          "paragraph": {"type": "object"}
        },
        "marks": {
          "strong": {"type": "object"}
        }
      }
    }
    """

  /// Trimmed from a live response: full top-level shape, `nodes` and `marks` cut down to
  /// representative specs.
  private static let proseMirrorJSON = """
    {
      "type": "prosemirror-document-data-schema",
      "version": "v25",
      "topNode": "doc",
      "data": {"type": "doc", "content": "block+"},
      "nodes": {
        "doc": {"content": "block+"},
        "text": {"group": "inline"},
        "paragraph": {
          "content": "inline*",
          "attrs": {"textAlign": {"default": "left"}},
          "group": "block"
        }
      },
      "marks": {
        "strong": {},
        "em": {}
      }
    }
    """

  // MARK: - Get

  @Test("200 with the default format decodes the draft-06 variant")
  func getDraft06() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: Self.draft06JSON)
    let client = try makeClient(transport)

    let schema = try await client.getDocumentSchema(id: "latest")

    let draft06 = try #require(schema.draft06)
    #expect(schema.proseMirror == nil)
    #expect(draft06._dollar_schema == "http://json-schema.org/draft-06/schema")
    #expect(draft06._dollar_id == "kaiten://document-schemas/v25")
    #expect(draft06.version == "v25")
    #expect(draft06.allOf?.count == 1)
    let nodes = try #require(draft06.definitions?.nodes)
    #expect(nodes.additionalProperties.value.keys.contains("doc"))
    let marks = try #require(draft06.definitions?.marks)
    #expect(marks.additionalProperties.value.keys.contains("strong"))

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    #expect(recorded.request.path == "/document-schemas/latest")
  }

  @Test("200 with format=prosemirror decodes the ProseMirror variant")
  func getProseMirror() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: Self.proseMirrorJSON)
    let client = try makeClient(transport)

    let schema = try await client.getDocumentSchema(id: "v25", format: .proseMirror)

    let proseMirror = try #require(schema.proseMirror)
    #expect(schema.draft06 == nil)
    #expect(proseMirror._type == "prosemirror-document-data-schema")
    #expect(proseMirror.version == "v25")
    #expect(proseMirror.topNode == "doc")
    let nodes = try #require(proseMirror.nodes)
    #expect(nodes.additionalProperties.value.keys.contains("paragraph"))
    let marks = try #require(proseMirror.marks)
    #expect(marks.additionalProperties.value.keys.contains("em"))

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.method == .get)
    #expect(recorded.request.path == "/document-schemas/v25?format=prosemirror")
  }

  @Test("format is omitted from the query when not passed")
  func getOmitsFormat() async throws {
    let transport = MockClientTransport.returning(statusCode: 200, body: Self.draft06JSON)
    let client = try makeClient(transport)

    _ = try await client.getDocumentSchema(id: "v25")

    let recorded = try #require(transport.recordedRequests.first)
    #expect(recorded.request.path == "/document-schemas/v25")
  }

  @Test("400 unsupported format throws unexpectedResponse")
  func getBadRequest() async throws {
    let client = try makeClient(.returning(statusCode: 400))
    await expectUnexpectedResponse(statusCode: 400) {
      _ = try await client.getDocumentSchema(id: "latest", format: .unknown("bogus"))
    }
  }

  /// Document schemas are addressed by string version, which
  /// ``KaitenError/notFound(resource:id:)`` cannot represent, so a 404 surfaces as
  /// `unexpectedResponse`.
  @Test("404 throws unexpectedResponse")
  func getNotFound() async throws {
    let client = try makeClient(.returning(statusCode: 404))
    await expectUnexpectedResponse(statusCode: 404) {
      _ = try await client.getDocumentSchema(id: "v99999")
    }
  }
}
