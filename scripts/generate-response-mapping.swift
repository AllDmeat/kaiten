#!/usr/bin/env swift
//
// generate-response-mapping.swift
//
// Generates Sources/KaitenSDK/ResponseMapping.swift from a declarative
// configuration. Run from the repository root:
//
//   swift scripts/generate-response-mapping.swift
//
// Each operation is described by its name and the set of error cases its
// OpenAPI-generated Output enum contains (besides `.ok` and `.undocumented`,
// which are always present).

// MARK: - Configuration

/// Error cases that an Output enum may contain (besides `.ok` and `.undocumented`).
enum ErrorCase: String {
  case badRequest
  case unauthorized
  case paymentRequired
  /// HTTP 302. Documented for get_comment_file, whose default disposition is a redirect
  /// to the file content. The SDK requests the JSON disposition, so a redirect reaching
  /// the client is unexpected and maps accordingly.
  case found
  case forbidden
  case notFound
  case conflict
  case unprocessableContent
  case serviceUnavailable
}

/// The documented success case of an Output enum. Most operations answer
/// `200 OK`; background jobs answer `202 Accepted`.
enum SuccessCase: String {
  case ok = "Ok"
  case accepted = "Accepted"

  /// The generated enum case name (`.ok` / `.accepted`).
  var caseName: String { rawValue.lowercased() }
}

struct Operation {
  let name: String
  let errors: [ErrorCase]
  /// Whether the success response carries a body. Operations documented as
  /// returning no content map to `ResponseCase<Void>`.
  let hasBody: Bool
  /// The documented success status of the operation.
  let success: SuccessCase

  init(name: String, errors: [ErrorCase], hasBody: Bool = true, success: SuccessCase = .ok) {
    self.name = name
    self.errors = errors
    self.hasBody = hasBody
    self.success = success
  }
}

struct Section {
  let mark: String
  let operations: [Operation]
}

let sections: [Section] = [
  Section(mark: "Cards", operations: [
    Operation(name: "get_cards", errors: [.unauthorized]),
    Operation(name: "create_card", errors: [.badRequest, .unauthorized, .forbidden]),
    Operation(name: "get_card", errors: [.unauthorized, .notFound]),
    Operation(name: "update_card", errors: [.badRequest, .unauthorized, .forbidden, .notFound]),
    Operation(
      name: "batch_update_cards",
      errors: [.badRequest, .unauthorized, .paymentRequired, .forbidden, .notFound],
      success: .accepted),
  ]),
  Section(mark: "Card Members & Comments", operations: [
    Operation(name: "retrieve_list_of_card_members", errors: [.unauthorized, .forbidden]),
    Operation(name: "add_card_member", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(name: "update_card_member_role", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(name: "remove_card_member", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(name: "retrieve_card_comments", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(name: "create_card_comment", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(name: "update_card_comment", errors: [.unauthorized, .forbidden, .notFound]),
  ]),
  Section(mark: "Checklists", operations: [
    Operation(name: "create_checklist", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(name: "get_checklist", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(name: "delete_card", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(name: "delete_card_comment", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(name: "remove_checklist", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(name: "update_checklist", errors: [.unauthorized, .forbidden, .notFound]),
  ]),
  Section(mark: "Checklist Items", operations: [
    Operation(name: "create_checklist_item", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(name: "remove_checklist_item", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(name: "update_checklist_item", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(
      name: "add_item_to_checklist",
      errors: [.badRequest, .unauthorized, .forbidden, .notFound]),
    Operation(
      name: "update_item_in_checklist",
      errors: [.badRequest, .unauthorized, .forbidden, .notFound]),
    Operation(name: "remove_item_from_checklist", errors: [.unauthorized, .forbidden, .notFound]),
  ]),
  Section(mark: "Custom Properties", operations: [
    Operation(name: "get_list_of_properties", errors: [.unauthorized, .forbidden]),
    Operation(name: "get_property", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(
      name: "create_property",
      errors: [.badRequest, .unauthorized, .paymentRequired, .forbidden]),
    Operation(
      name: "update_property",
      errors: [.badRequest, .unauthorized, .paymentRequired, .forbidden, .notFound]),
    Operation(
      name: "remove_property", errors: [.badRequest, .unauthorized, .forbidden, .notFound]),
    Operation(name: "get_list_of_select_values", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(
      name: "create_select_value", errors: [.badRequest, .unauthorized, .forbidden, .notFound]),
    Operation(name: "get_select_value", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(
      name: "update_select_value", errors: [.badRequest, .unauthorized, .forbidden, .notFound]),
    Operation(name: "remove_select_value", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(name: "get_list_of_vote_values", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(
      name: "create_vote_value", errors: [.badRequest, .unauthorized, .forbidden, .notFound]),
    Operation(
      name: "update_vote_value", errors: [.badRequest, .unauthorized, .forbidden, .notFound]),
    Operation(
      name: "delete_vote_value", errors: [.badRequest, .unauthorized, .forbidden, .notFound]),
  ]),
  Section(mark: "Custom Property Catalog Values", operations: [
    Operation(name: "get_list_of_catalog_values", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(
      name: "create_catalog_value", errors: [.badRequest, .unauthorized, .forbidden, .notFound]),
    Operation(name: "get_catalog_value", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(
      name: "update_catalog_value", errors: [.badRequest, .unauthorized, .forbidden, .notFound]),
    Operation(name: "remove_catalog_value", errors: [.unauthorized, .forbidden, .notFound]),
  ]),
  Section(mark: "Boards", operations: [
    Operation(name: "get_board", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(name: "get_space_board", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(name: "get_list_of_columns", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(name: "get_list_of_lanes", errors: [.unauthorized, .forbidden, .notFound]),
  ]),
  Section(mark: "Spaces", operations: [
    Operation(name: "retrieve_list_of_spaces", errors: [.unauthorized]),
    Operation(name: "get_list_of_boards", errors: [.unauthorized, .forbidden, .notFound]),
  ]),
  Section(mark: "Card Tags", operations: [
    Operation(name: "list_card_children", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(name: "add_card_child", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(name: "remove_card_child", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(name: "list_card_tags", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(name: "add_card_tag", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(name: "remove_card_tag", errors: [.unauthorized, .forbidden, .notFound]),
  ]),
  Section(mark: "Tags", operations: [
    Operation(name: "retrieve_list_of_tags", errors: [.unauthorized, .forbidden]),
    Operation(name: "add_tag", errors: [.badRequest, .unauthorized, .forbidden]),
  ]),
  Section(mark: "Users", operations: [
    Operation(name: "retrieve_list_of_users", errors: [.unauthorized]),
    Operation(name: "retrieve_current_user", errors: [.unauthorized]),
  ]),
  Section(mark: "Card Blockers", operations: [
    Operation(name: "list_card_blockers", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(name: "create_card_blocker", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(name: "update_card_blocker", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(name: "delete_card_blocker", errors: [.unauthorized, .forbidden, .notFound]),
  ]),
  Section(mark: "Card Types", operations: [
    Operation(name: "list_card_types", errors: [.unauthorized, .forbidden]),
    Operation(name: "create_card_type", errors: [.badRequest, .unauthorized, .forbidden]),
    Operation(name: "get_card_type", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(
      name: "update_card_type", errors: [.badRequest, .unauthorized, .forbidden, .notFound]),
    Operation(
      name: "delete_card_type", errors: [.badRequest, .unauthorized, .forbidden, .notFound]),
  ]),
  Section(mark: "Sprints", operations: [
    Operation(name: "list_sprints", errors: [.unauthorized, .forbidden]),
  ]),
  Section(mark: "External Links", operations: [
    Operation(name: "list_card_external_links", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(name: "create_card_external_link", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(name: "update_card_external_link", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(name: "remove_card_external_link", errors: [.unauthorized, .forbidden, .notFound]),
  ]),
  Section(mark: "Card Location History", operations: [
    Operation(name: "get_card_location_history", errors: [.unauthorized, .forbidden, .notFound]),
  ]),
  Section(mark: "Sprint Summary", operations: [
    Operation(name: "get_sprint_summary", errors: [.unauthorized, .forbidden, .notFound]),
  ]),
  Section(mark: "Spaces CRUD", operations: [
    Operation(name: "create_space", errors: [.badRequest, .unauthorized, .forbidden]),
    Operation(name: "retrieve_space", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(name: "update_space", errors: [.badRequest, .unauthorized, .forbidden, .notFound]),
  ]),
  Section(mark: "Boards CRUD", operations: [
    Operation(name: "create_board", errors: [.badRequest, .unauthorized, .forbidden, .notFound]),
    Operation(name: "update_board", errors: [.badRequest, .unauthorized, .forbidden, .notFound]),
  ]),
  Section(mark: "Columns CRUD", operations: [
    Operation(name: "create_column", errors: [.badRequest, .unauthorized, .forbidden, .notFound]),
    Operation(name: "update_column", errors: [.badRequest, .unauthorized, .forbidden, .notFound]),
    Operation(name: "remove_column", errors: [.badRequest, .unauthorized, .forbidden, .notFound]),
  ]),
  Section(mark: "Subcolumns", operations: [
    Operation(name: "get_list_of_subcolumns", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(name: "create_subcolumn", errors: [.badRequest, .unauthorized, .forbidden, .notFound]),
    Operation(name: "update_subcolumn", errors: [.badRequest, .unauthorized, .forbidden, .notFound]),
    Operation(name: "remove_subcolumn", errors: [.badRequest, .unauthorized, .forbidden, .notFound]),
  ]),
  Section(mark: "Lanes CRUD", operations: [
    Operation(name: "create_lane", errors: [.badRequest, .unauthorized, .forbidden, .notFound]),
    Operation(name: "update_lane", errors: [.badRequest, .unauthorized, .forbidden, .notFound]),
  ]),
  Section(mark: "Card Baselines", operations: [
    Operation(name: "get_card_baselines", errors: [.unauthorized, .forbidden]),
  ]),
  Section(mark: "Card SLA", operations: [
    Operation(
      name: "get_card_sla_measurements",
      errors: [.badRequest, .unauthorized, .forbidden, .notFound]),
  ]),
  Section(mark: "Card Files", operations: [
    Operation(
      name: "attach_file_to_card",
      errors: [.badRequest, .unauthorized, .forbidden, .notFound, .serviceUnavailable]),
    Operation(
      name: "update_card_file", errors: [.unauthorized, .forbidden, .notFound], hasBody: false),
    Operation(name: "detach_file_from_card", errors: [.unauthorized, .forbidden, .notFound]),
  ]),
  Section(mark: "Private Card Files", operations: [
    Operation(
      name: "attach_private_card_file",
      errors: [.badRequest, .unauthorized, .forbidden, .notFound]),
    Operation(
      name: "get_private_card_file",
      errors: [.found, .unauthorized, .forbidden, .notFound, .unprocessableContent]),
    Operation(
      name: "delete_private_card_file", errors: [.unauthorized, .forbidden, .notFound]),
  ]),
  Section(mark: "Private Comment Files", operations: [
    Operation(
      name: "attach_file_to_comment",
      errors: [.badRequest, .unauthorized, .forbidden, .notFound]),
    Operation(
      name: "get_comment_file",
      errors: [.found, .unauthorized, .forbidden, .notFound, .unprocessableContent]),
    Operation(name: "delete_comment_file", errors: [.unauthorized, .forbidden, .notFound]),
  ]),
  Section(mark: "Automations", operations: [
    Operation(name: "list_automations", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(
      name: "create_automation",
      errors: [.badRequest, .unauthorized, .paymentRequired, .forbidden, .notFound]),
    Operation(
      name: "update_automation",
      errors: [.badRequest, .unauthorized, .paymentRequired, .forbidden, .notFound]),
    Operation(
      name: "delete_automation", errors: [.unauthorized, .forbidden, .notFound], hasBody: false),
  ]),
  Section(mark: "Space Users", operations: [
    Operation(name: "list_space_users", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(
      name: "invite_user_to_space",
      errors: [.badRequest, .unauthorized, .forbidden, .notFound]),
    Operation(name: "get_space_user", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(
      name: "update_space_user",
      errors: [.badRequest, .unauthorized, .forbidden, .notFound]),
    Operation(
      name: "remove_space_user",
      errors: [.unauthorized, .forbidden, .notFound, .conflict]),
  ]),
  Section(mark: "Iterations", operations: [
    Operation(
      name: "get_card_iterations_history",
      errors: [.unauthorized, .paymentRequired, .forbidden, .notFound]),
    Operation(
      name: "list_iterations",
      errors: [.unauthorized, .paymentRequired, .forbidden, .notFound]),
    Operation(
      name: "create_iteration",
      errors: [.badRequest, .unauthorized, .paymentRequired, .forbidden, .notFound]),
    Operation(
      name: "get_iteration",
      errors: [.unauthorized, .paymentRequired, .forbidden, .notFound]),
    Operation(
      name: "update_iteration",
      errors: [.badRequest, .unauthorized, .paymentRequired, .forbidden, .notFound]),
    Operation(
      name: "delete_iteration",
      errors: [.badRequest, .unauthorized, .paymentRequired, .forbidden, .notFound]),
    Operation(
      name: "list_iteration_cards",
      errors: [.badRequest, .unauthorized, .paymentRequired, .forbidden, .notFound]),
    Operation(
      name: "add_card_to_iteration",
      errors: [.badRequest, .unauthorized, .paymentRequired, .forbidden, .notFound]),
    Operation(
      name: "remove_card_from_iteration",
      errors: [.badRequest, .unauthorized, .paymentRequired, .forbidden, .notFound]),
  ]),
  Section(mark: "Service Desk External Recipients", operations: [
    Operation(
      name: "add_sd_external_recipient",
      errors: [.badRequest, .unauthorized, .paymentRequired, .forbidden, .notFound]),
    Operation(
      name: "remove_sd_external_recipient",
      errors: [.badRequest, .unauthorized, .forbidden, .notFound]),
  ]),
  Section(mark: "Service Desk Services", operations: [
    Operation(name: "list_service_desk_services", errors: [.unauthorized, .forbidden])
  ]),
  Section(mark: "Blocker Categories", operations: [
    Operation(name: "list_blocker_categories", errors: [.unauthorized, .forbidden]),
    Operation(name: "add_blocker_category", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(name: "remove_blocker_category", errors: [.unauthorized, .forbidden, .notFound]),
  ]),
  Section(mark: "Card Type Tree Entities", operations: [
    Operation(
      name: "list_card_type_tree_entities",
      errors: [.unauthorized, .paymentRequired, .forbidden]),
    Operation(
      name: "add_card_type_tree_entity",
      errors: [.badRequest, .unauthorized, .paymentRequired, .forbidden]),
    Operation(
      name: "delete_card_type_tree_entity",
      errors: [.unauthorized, .paymentRequired, .forbidden]),
  ]),
  Section(mark: "Card Allowed Users", operations: [
    Operation(name: "retrieve_card_allowed_users", errors: [.unauthorized, .forbidden, .notFound])
  ]),
  Section(mark: "Card Time Logs", operations: [
    Operation(name: "get_card_time_logs", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(
      name: "create_card_time_log",
      errors: [.badRequest, .unauthorized, .paymentRequired, .forbidden, .notFound]),
    Operation(
      name: "update_card_time_log",
      errors: [.badRequest, .unauthorized, .paymentRequired, .forbidden, .notFound]),
    Operation(
      name: "delete_card_time_log",
      errors: [.unauthorized, .paymentRequired, .forbidden, .notFound]),
  ]),
  Section(mark: "Audit Logs", operations: [
    Operation(
      name: "retrieve_audit_log_events", errors: [.badRequest, .unauthorized, .forbidden]),
  ]),
  Section(mark: "Card Blocker Users", operations: [
    Operation(name: "list_card_blocker_users", errors: [.unauthorized]),
    Operation(name: "add_card_blocker_user", errors: [.unauthorized]),
    Operation(name: "remove_card_blocker_user", errors: [.unauthorized]),
    Operation(name: "retrieve_current_user_blockers", errors: [.unauthorized]),
  ]),
  Section(mark: "Checklist Cards", operations: [
    Operation(
      name: "retrieve_cards_with_checklist",
      errors: [.badRequest, .unauthorized, .forbidden, .notFound]),
  ]),
  Section(mark: "Custom Directories", operations: [
    Operation(name: "list_custom_directories", errors: [.unauthorized, .forbidden]),
    Operation(
      name: "create_custom_directory", errors: [.badRequest, .unauthorized, .forbidden]),
    Operation(name: "get_custom_directory", errors: [.unauthorized, .notFound]),
    Operation(
      name: "update_custom_directory", errors: [.badRequest, .unauthorized, .notFound]),
    Operation(
      name: "delete_custom_directory", errors: [.badRequest, .unauthorized, .notFound]),
  ]),
  Section(mark: "Company Users", operations: [
    Operation(name: "get_company_users", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(
      name: "update_company_user",
      errors: [.badRequest, .unauthorized, .forbidden, .notFound]),
    Operation(name: "remove_virtual_user", errors: [.forbidden, .notFound]),
  ]),
  Section(mark: "Custom Directory Fields", operations: [
    Operation(name: "list_custom_directory_fields", errors: [.unauthorized, .notFound]),
    Operation(
      name: "create_custom_directory_field", errors: [.badRequest, .unauthorized, .notFound]),
    Operation(name: "get_custom_directory_field", errors: [.unauthorized, .notFound]),
    Operation(name: "update_custom_directory_field", errors: [.unauthorized, .notFound]),
    Operation(name: "delete_custom_directory_field", errors: [.unauthorized, .notFound]),
  ]),
  Section(mark: "Custom Directory Records", operations: [
    Operation(name: "list_custom_directory_records", errors: [.unauthorized, .notFound]),
    Operation(
      name: "create_custom_directory_record", errors: [.badRequest, .unauthorized, .notFound]),
    Operation(name: "get_custom_directory_record", errors: [.unauthorized, .notFound]),
    Operation(
      name: "update_custom_directory_record", errors: [.badRequest, .unauthorized, .notFound]),
    Operation(name: "delete_custom_directory_record", errors: [.unauthorized, .notFound]),
    Operation(
      name: "list_custom_directory_record_cards", errors: [.badRequest, .unauthorized, .notFound]),
  ]),
  Section(mark: "Custom Property Tree Entities", operations: [
    Operation(
      name: "list_custom_property_tree_entities",
      errors: [.unauthorized, .paymentRequired, .forbidden]),
    Operation(
      name: "add_custom_property_tree_entity",
      errors: [.badRequest, .unauthorized, .paymentRequired, .forbidden]),
    Operation(
      name: "delete_custom_property_tree_entity",
      errors: [.unauthorized, .paymentRequired, .forbidden]),
  ]),
  Section(mark: "Group Admins", operations: [
    Operation(name: "list_group_admins", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(
      name: "add_group_admin",
      errors: [.badRequest, .unauthorized, .paymentRequired, .forbidden, .notFound]),
    Operation(
      name: "remove_group_admin",
      errors: [.unauthorized, .paymentRequired, .forbidden, .notFound]),
  ]),
  Section(mark: "Document Schemas", operations: [
    Operation(name: "get_document_schema", errors: [.badRequest, .notFound])
  ]),
  Section(mark: "Group Entities", operations: [
    Operation(name: "list_group_entities", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(
      name: "add_group_entity",
      errors: [.badRequest, .unauthorized, .paymentRequired, .forbidden, .notFound]),
    Operation(
      name: "update_group_entity",
      errors: [.badRequest, .unauthorized, .paymentRequired, .forbidden, .notFound]),
    Operation(name: "remove_group_entity", errors: [.unauthorized, .forbidden, .notFound]),
  ]),
  Section(mark: "Custom Property Collective Score Values", operations: [
    Operation(
      name: "get_list_of_collective_score_values",
      errors: [.unauthorized, .forbidden, .notFound]),
    Operation(
      name: "create_collective_score_value",
      errors: [.badRequest, .unauthorized, .paymentRequired, .forbidden, .notFound]),
    Operation(
      name: "update_collective_score_value",
      errors: [.badRequest, .unauthorized, .paymentRequired, .forbidden, .notFound]),
  ]),
  Section(mark: "Group Users", operations: [
    Operation(name: "list_group_users", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(
      name: "add_user_to_group",
      errors: [.badRequest, .unauthorized, .paymentRequired, .forbidden, .notFound]),
    Operation(
      name: "remove_user_from_group",
      errors: [.unauthorized, .paymentRequired, .forbidden, .notFound]),
  ]),
  Section(mark: "Document Groups", operations: [
    Operation(name: "list_document_groups", errors: [.unauthorized]),
    Operation(
      name: "create_document_group",
      errors: [.badRequest, .unauthorized, .paymentRequired, .forbidden, .conflict]),
    Operation(name: "get_document_group", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(
      name: "update_document_group",
      errors: [.badRequest, .unauthorized, .paymentRequired, .forbidden, .notFound, .conflict]),
    Operation(
      name: "delete_document_group",
      errors: [.badRequest, .unauthorized, .forbidden, .notFound]),
  ]),
  Section(mark: "Groups", operations: [
    Operation(name: "list_groups", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(
      name: "create_group",
      errors: [.badRequest, .unauthorized, .paymentRequired, .forbidden, .notFound]),
    Operation(name: "get_group", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(
      name: "update_group",
      errors: [.badRequest, .unauthorized, .paymentRequired, .forbidden, .notFound]),
    Operation(name: "remove_group", errors: [.unauthorized, .forbidden, .notFound]),
  ]),
  Section(mark: "Documents", operations: [
    Operation(name: "list_documents", errors: [.unauthorized]),
    Operation(
      name: "create_document",
      errors: [.badRequest, .unauthorized, .paymentRequired, .forbidden, .conflict]),
    Operation(name: "get_document", errors: [.unauthorized, .forbidden, .notFound]),
    Operation(
      name: "update_document",
      errors: [.badRequest, .unauthorized, .paymentRequired, .forbidden, .notFound, .conflict]),
    Operation(
      name: "delete_document", errors: [.badRequest, .unauthorized, .forbidden, .notFound]),
  ]),
  Section(mark: "Space Template Checklists", operations: [
    Operation(name: "list_space_template_checklists", errors: [.unauthorized]),
    Operation(name: "create_space_template_checklist", errors: [.unauthorized]),
    Operation(name: "update_space_template_checklist", errors: [.unauthorized]),
    Operation(name: "remove_space_template_checklist", errors: [.unauthorized]),
  ]),
  Section(mark: "Space Template Checklist Items", operations: [
    Operation(name: "create_space_template_checklist_item", errors: [.unauthorized]),
    Operation(name: "update_space_template_checklist_item", errors: [.unauthorized]),
    Operation(name: "remove_space_template_checklist_item", errors: [.unauthorized]),
  ]),
]

// MARK: - Generator

func generateExtension(_ op: Operation) -> String {
  let typeName = "Operations.\(op.name).Output"
  let returnType =
    "KaitenClient.ResponseCase<\(op.hasBody ? "\(typeName).\(op.success.rawValue).Body" : "Void")>"

  // Build switch cases
  var cases: [String] = []
  let successCase = op.success.caseName
  cases.append(
    op.hasBody
      ? "    case .\(successCase)(let \(successCase)): .ok(\(successCase).body)"
      : "    case .\(successCase): .ok(())")

  for error in op.errors {
    switch error {
    case .badRequest:
      cases.append("    case .badRequest: .undocumented(statusCode: 400)")
    case .unauthorized:
      cases.append("    case .unauthorized: .unauthorized")
    case .paymentRequired:
      cases.append("    case .code402: .undocumented(statusCode: 402)")
    case .found:
      cases.append("    case .found: .undocumented(statusCode: 302)")
    case .forbidden:
      cases.append("    case .forbidden: .forbidden")
    case .notFound:
      cases.append("    case .notFound: .notFound")
    case .conflict:
      cases.append("    case .conflict: .undocumented(statusCode: 409)")
    case .unprocessableContent:
      cases.append("    case .unprocessableContent: .undocumented(statusCode: 422)")
    case .serviceUnavailable:
      cases.append("    case .serviceUnavailable: .undocumented(statusCode: 503)")
    }
  }

  cases.append("    case .undocumented(statusCode: let code, _): .undocumented(statusCode: code)")

  // Determine if we need a line break in the signature
  let signatureLine = "  func toCase() -> \(returnType)"
  let needsLineBreak = signatureLine.count > 100

  var lines: [String] = []
  lines.append("extension \(typeName) {")
  if needsLineBreak {
    lines.append("  func toCase()")
    lines.append("    -> \(returnType)")
    lines.append("  {")
  } else {
    lines.append("  func toCase() -> \(returnType) {")
  }
  lines.append("    switch self {")
  lines.append(contentsOf: cases)
  lines.append("    }")
  lines.append("  }")
  lines.append("}")

  return lines.joined(separator: "\n")
}

func generate() -> String {
  var output: [String] = []

  output.append("""
    // MARK: - ResponseMapping
    //
    // Auto-generated by scripts/generate-response-mapping.swift
    // DO NOT EDIT THIS FILE MANUALLY.
    //
    // To regenerate, run from the repository root:
    //   swift scripts/generate-response-mapping.swift
    //
    // Maps OpenAPI-generated Output enums to the unified ResponseCase type.
    // Each extension converts operation-specific cases into a common shape,
    // eliminating repetitive switch boilerplate in KaitenClient methods.
    """)

  for section in sections {
    output.append("")
    output.append("// MARK: - \(section.mark)")

    for op in section.operations {
      output.append("")
      output.append(generateExtension(op))
    }
  }

  return output.joined(separator: "\n") + "\n"
}

// MARK: - Main

import Foundation

let repoRoot: String
if CommandLine.arguments.count > 1 {
  repoRoot = CommandLine.arguments[1]
} else {
  repoRoot = FileManager.default.currentDirectoryPath
}

let outputPath = "\(repoRoot)/Sources/KaitenSDK/ResponseMapping.swift"
let content = generate()

do {
  try content.write(toFile: outputPath, atomically: true, encoding: .utf8)
  print("Generated \(outputPath)")
  let opCount = sections.reduce(0) { $0 + $1.operations.count }
  print("\(opCount) operations across \(sections.count) sections")
} catch {
  fputs("Error writing file: \(error)\n", stderr)
  exit(1)
}
