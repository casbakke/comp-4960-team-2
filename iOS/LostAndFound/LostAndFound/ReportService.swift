//
//  ReportService.swift
//  LostAndFound
//
//  Created by Craig Bakke on 12/07/25.
//

import Foundation
import FirebaseFirestore

/// Service class for managing Report operations with Firestore
class ReportService {
    private let db = Firestore.firestore()
    
    /// Fetches approved found item reports from Firestore
    /// - Returns: Array of Report objects
    /// - Throws: Error if fetching fails
    func fetchApprovedFoundReports() async throws -> [Report] {
        let snapshot = try await db.collection("reports")
            .whereField("type", isEqualTo: "found")
            .whereField("status", isEqualTo: "approved")
            .getDocuments()
        
        var reports: [Report] = []
        
        for document in snapshot.documents {
            if let report = try? parseReportFromDocument(document) {
                reports.append(report)
            } else {
                #if DEBUG
                print("Warning: Failed to parse report from document \(document.documentID)")
                #endif
            }
        }
        
        return reports
    }
    
    /// Parses a Firestore document into a Report object
    /// - Parameter document: Firestore document snapshot
    /// - Returns: Report object
    /// - Throws: Error if parsing fails
    private func parseReportFromDocument(_ document: QueryDocumentSnapshot) throws -> Report {
        let data = document.data()
        
        // Parse ID: use the id field if it exists, otherwise use document ID
        let id: UUID
        if let idString = data["id"] as? String, let parsedUUID = UUID(uuidString: idString) {
            id = parsedUUID
        } else {
            // Use document ID as UUID
            if let documentUUID = UUID(uuidString: document.documentID) {
                id = documentUUID
            } else {
                throw ReportParsingError.invalidID
            }
        }
        
        // Parse required fields
        guard let categoryString = data["category"] as? String,
              let category = ReportCategory(rawValue: categoryString) else {
            throw ReportParsingError.missingField("category")
        }
        
        guard let createdByName = data["createdByName"] as? String else {
            throw ReportParsingError.missingField("createdByName")
        }
        
        guard let createdByEmail = data["createdByEmail"] as? String else {
            throw ReportParsingError.missingField("createdByEmail")
        }
        
        guard let createdByPhone = data["createdByPhone"] as? String else {
            throw ReportParsingError.missingField("createdByPhone")
        }
        
        guard let createdAtTimestamp = data["createdAt"] as? Timestamp else {
            throw ReportParsingError.missingField("createdAt")
        }
        let createdAt = createdAtTimestamp.dateValue()
        
        guard let title = data["title"] as? String else {
            throw ReportParsingError.missingField("title")
        }
        
        guard let locationBuilding = data["locationBuilding"] as? String else {
            throw ReportParsingError.missingField("locationBuilding")
        }
        
        guard let statusString = data["status"] as? String,
              let status = ReportStatus(rawValue: statusString) else {
            throw ReportParsingError.missingField("status")
        }
        
        guard let typeString = data["type"] as? String,
              let type = ReportType(rawValue: typeString) else {
            throw ReportParsingError.missingField("type")
        }
        
        // Parse optional fields
        let description = parseOptionalString(data["description"])
        
        let imageUrl: URL?
        if let imageUrlString = parseOptionalString(data["imageUrl"]) {
            imageUrl = URL(string: imageUrlString)
        } else {
            imageUrl = nil
        }
        
        let locationCoordinates: ReportCoordinates?
        if let geoPoint = data["locationCoordinates"] as? GeoPoint {
            locationCoordinates = ReportCoordinates(
                latitude: geoPoint.latitude,
                longitude: geoPoint.longitude
            )
        } else {
            locationCoordinates = nil
        }
        
        let reviewedAt: Date?
        if let reviewedAtTimestamp = data["reviewedAt"] as? Timestamp {
            reviewedAt = reviewedAtTimestamp.dateValue()
        } else {
            reviewedAt = nil
        }
        
        let reviewedBy = parseOptionalString(data["reviewedBy"])
        
        return Report(
            id: id,
            category: category,
            createdByName: createdByName,
            createdByEmail: createdByEmail,
            createdByPhone: createdByPhone,
            createdAt: createdAt,
            description: description,
            title: title,
            imageUrl: imageUrl,
            locationBuilding: locationBuilding,
            locationCoordinates: locationCoordinates,
            reviewedAt: reviewedAt,
            reviewedBy: reviewedBy,
            status: status,
            type: type
        )
    }
    
    /// Helper to parse optional string fields, handling NSNull
    /// - Parameter value: The value from Firestore document
    /// - Returns: Optional string value
    private func parseOptionalString(_ value: Any?) -> String? {
        guard let value = value else { return nil }
        
        // Check if it's NSNull
        if value is NSNull {
            return nil
        }
        
        // Try to cast to string
        guard let stringValue = value as? String else {
            return nil
        }
        
        // Return nil if string is empty after trimming
        let trimmed = stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

/// Errors that can occur when parsing Report documents
enum ReportParsingError: LocalizedError {
    case missingField(String)
    case invalidID
    
    var errorDescription: String? {
        switch self {
        case .missingField(let field):
            return "Missing required field: \(field)"
        case .invalidID:
            return "Invalid or missing report ID"
        }
    }
}

