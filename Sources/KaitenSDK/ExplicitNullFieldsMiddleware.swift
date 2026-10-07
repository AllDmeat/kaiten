import Foundation
import HTTPTypes
import OpenAPIRuntime

/// A middleware that adds JSON `null` fields to the request body.
///
/// Generated request types encode a plain optional with `encodeIfPresent`, so they cannot send
/// `null`. Where retyping the property to ``ExplicitNullInteger`` would change a public generated
/// type, a wrapper sets ``fields`` around the call instead and this middleware writes the nulls.
struct ExplicitNullFieldsMiddleware: ClientMiddleware {
  /// Top-level body keys to send as `null` for requests made within the current task.
  @TaskLocal static var fields: [String] = []

  func intercept(
    _ request: HTTPRequest,
    body: HTTPBody?,
    baseURL: URL,
    operationID: String,
    next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
  ) async throws -> (HTTPResponse, HTTPBody?) {
    let fields = Self.fields
    guard !fields.isEmpty, let body else {
      return try await next(request, body, baseURL)
    }
    let data = try await Data(collecting: body, upTo: .max)
    guard var json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      return try await next(request, HTTPBody(data), baseURL)
    }
    for field in fields {
      json[field] = NSNull()
    }
    let patched = try JSONSerialization.data(withJSONObject: json)
    // The runtime stamps content-length from the original body before middlewares run.
    var request = request
    request.headerFields[.contentLength] = String(patched.count)
    return try await next(request, HTTPBody(patched), baseURL)
  }
}
