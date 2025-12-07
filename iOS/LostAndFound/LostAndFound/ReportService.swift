//
//  ReportService.swift
//  LostAndFound
//
//  Created by Craig Bakke on 12/07/25.
//

import Foundation
import FirebaseFirestore
import CryptoKit

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
        
        // Parse ID: use the id field if it exists, otherwise create UUID from document ID
        let id: UUID
        if let idString = data["id"] as? String, let parsedUUID = UUID(uuidString: idString) {
            // Use the id field if it exists and is a valid UUID
            id = parsedUUID
        } else if let documentUUID = UUID(uuidString: document.documentID) {
            // If document ID happens to be a UUID format, use it
            id = documentUUID
        } else {
            // Create a deterministic UUID from the document ID string
            // This ensures the same document always gets the same UUID
            id = createUUIDFromString(document.documentID)
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
    
    /// Creates a deterministic UUID from a string (like a Firestore document ID)
    /// This ensures the same string always produces the same UUID
    /// - Parameter string: The input string (e.g., Firestore document ID)
    /// - Returns: A UUID created from the string
    private func createUUIDFromString(_ string: String) -> UUID {
        // Use SHA256 hash to create a deterministic UUID from the string
        // This is a common approach for converting arbitrary strings to UUIDs
        let data = string.data(using: .utf8) ?? Data()
        let hash = data.withUnsafeBytes { bytes in
            var hasher = SHA256()
            if let baseAddress = bytes.baseAddress, bytes.count > 0 {
                hasher.update(bufferPointer: UnsafeRawBufferPointer(start: baseAddress, count: bytes.count))
            }
            return hasher.finalize()
        }
        
        // Take first 16 bytes of hash to create UUID
        let uuidBytes = Array(hash.prefix(16))
        let uuidString = String(format: "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
                                uuidBytes[0], uuidBytes[1], uuidBytes[2], uuidBytes[3],
                                uuidBytes[4], uuidBytes[5], uuidBytes[6], uuidBytes[7],
                                uuidBytes[8], uuidBytes[9], uuidBytes[10], uuidBytes[11],
                                uuidBytes[12], uuidBytes[13], uuidBytes[14], uuidBytes[15])
        
        return UUID(uuidString: uuidString) ?? UUID()
    }
}

/// Errors that can occur when parsing Report documents
enum ReportParsingError: LocalizedError {
    case missingField(String)
    
    var errorDescription: String? {
        switch self {
        case .missingField(let field):
            return "Missing required field: \(field)"
        }
    }
}

