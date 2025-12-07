//
//  Report.swift
//  LostAndFound
//
//  Created by Craig Bakke on 12/01/25.
//

import Foundation

enum ReportCategory: String, CaseIterable, Identifiable, Codable {
    case walletIdKeys = "Wallet/ID/Keys"
    case electronics = "Electronics"
    case clothingApparel = "Clothing & Apparel"
    case academicMaterials = "Academic Materials"
    case bags = "Bags"
    case other = "Other"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
}

enum ReportStatus: String, CaseIterable, Identifiable, Codable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "denied"
    case closed = "closed"
    
    var id: String { rawValue }
}

enum ReportType: String, CaseIterable, Identifiable, Codable {
    case lost = "lost"
    case found = "found"
    
    var id: String { rawValue }
}

struct ReportCoordinates: Hashable, Codable {
    let latitude: Double
    let longitude: Double
}

struct Report: Identifiable, Hashable, Codable {
    
    let id: UUID
    
    /// The category of the reported item, e.g. "Electronics"
    let category: ReportCategory
    
    /// The display name (real name) of the user who created the report.
    let createdByName: String
    
    /// The email of the user who created the report.
    let createdByEmail: String
    
    /// The phone number of the user who created the report. Must be a 10-digit number.
    let createdByPhone: String
    
    /// The date and time the report was created.
    let createdAt: Date
    
    /// The description of the report. Optional.
    let description: String?
    
    /// A basic name for the item, e.g. "iPhone 17"
    let title: String
    
    /// The Firebase Storage URL of the item image. Optional.
    let imageUrl: URL?
    
    /// The name of the building where the item was lost or found.
    let locationBuilding: String
    
    /// The coordinates of the location where the item was found or lost. Optional.
    let locationCoordinates: ReportCoordinates?
    
    /// The date and time the report was reviewed.
    let reviewedAt: Date?
    
    /// The email of the user who reviewed the report.
    let reviewedBy: String?
    
    /// The status of the report.
    let status: ReportStatus
    
    /// The type of the report. (Lost or Found)
    let type: ReportType
    
}


