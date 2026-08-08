import Foundation
import OpenAPIRuntime

// MARK: - Card SLA

extension KaitenClient {
  /// Retrieves SLA rule timing metrics for a card.
  ///
  /// Kaiten computes SLA measurements only for service desk request cards; for any other
  /// card, and for archived cards, the API answers HTTP 400, which surfaces as
  /// ``KaitenError/unexpectedResponse(statusCode:body:)``.
  ///
  /// - Parameter cardId: The card identifier.
  /// - Returns: The card's SLA measurements: the calendars used for the calculations and
  ///   the per-rule timing data. Both collections are empty when no SLA rules apply to the card.
  /// - Throws:
  ///   - ``KaitenError/notFound(resource:id:)`` if the card does not exist.
  ///   - ``KaitenError/unauthorized`` if the API token is invalid or lacks permissions.
  ///   - ``KaitenError/decodingError(underlying:)`` if the response body cannot be decoded.
  ///   - ``KaitenError/networkError(underlying:)`` for connectivity failures.
  ///   - ``KaitenError/unexpectedResponse(statusCode:body:)`` for bad request (400), forbidden
  ///     (403) or other undocumented HTTP status codes.
  public func getCardSlaMeasurements(
    cardId: Int
  ) async throws(KaitenError) -> Components.Schemas.CardSlaMeasurements {
    let response = try await call {
      try await client.get_card_sla_measurements(path: .init(card_id: cardId))
    }
    return try decodeResponse(response.toCase(), notFoundResource: ("card", cardId)) {
      try $0.json
    }
  }
}
