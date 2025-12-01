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

extension Report {
    static let sampleFoundReports: [Report] = [
        Report(
            id: UUID(),
            category: .electronics,
            createdByName: "Jordan Clark",
            createdByEmail: "jclark@wit.edu",
            createdByPhone: "6175551200",
            createdAt: Date().addingTimeInterval(-60 * 60 * 2),
            description: "Silver 13\" HP Pavilion with sticker near the trackpad.",
            title: "HP Pavilion Laptop",
            imageUrl: URL(string: "https://www.cnet.com/a/img/resize/bb8a2aa9c31f8ec08d82228a51eabf05f00e54d2/hub/2025/03/10/d190e21d-9634-440d-8f33-396c8cb3da6a/m4-macbook-air-15-11.jpg?auto=webp&height=500"),
            locationBuilding: "Wentworth Library",
            locationCoordinates: ReportCoordinates(latitude: 42.3378, longitude: -71.0953),
            reviewedAt: Date().addingTimeInterval(-60 * 35),
            reviewedBy: "carter@wit.edu",
            status: .approved,
            type: .found
        ),
        Report(
            id: UUID(),
            category: .walletIdKeys,
            createdByName: "Amanda Reyes",
            createdByEmail: "areyes@wit.edu",
            createdByPhone: "6175552189",
            createdAt: Date().addingTimeInterval(-60 * 60 * 26),
            description: "Set of dorm keys on a red carabiner with a WIT Student ID.",
            title: "Dorm Keys & Student ID",
            imageUrl: nil,
            locationBuilding: "Dobbs Hall Lobby",
            locationCoordinates: ReportCoordinates(latitude: 42.3362, longitude: -71.0927),
            reviewedAt: Date().addingTimeInterval(-60 * 60 * 3),
            reviewedBy: "lporter@wit.edu",
            status: .approved,
            type: .found
        ),
        Report(
            id: UUID(),
            category: .academicMaterials,
            createdByName: "Noah Patel",
            createdByEmail: "npatel@wit.edu",
            createdByPhone: "6175553344",
            createdAt: Date().addingTimeInterval(-60 * 60 * 72),
            description: "Black engineering notebook with graph paper and circuits homework.",
            title: "Engineering Notebook",
            imageUrl: nil,
            locationBuilding: "Beatty Hall Room 207",
            locationCoordinates: ReportCoordinates(latitude: 42.3369, longitude: -71.0959),
            reviewedAt: Date().addingTimeInterval(-60 * 60 * 8),
            reviewedBy: "sscott@wit.edu",
            status: .approved,
            type: .found
        ),
        Report(
            id: UUID(),
            category: .bags,
            createdByName: "Ethan Brooks",
            createdByEmail: "ebrooks@wit.edu",
            createdByPhone: "6175550199",
            createdAt: Date().addingTimeInterval(-60 * 60 * 15),
            description: "Grey Herschel backpack with a water bottle inside.",
            title: "Herschel Backpack",
            imageUrl: nil,
            locationBuilding: "Wentworth Gym",
            locationCoordinates: ReportCoordinates(latitude: 42.3356, longitude: -71.0938),
            reviewedAt: Date().addingTimeInterval(-60 * 60 * 4),
            reviewedBy: "mphelps@wit.edu",
            status: .approved,
            type: .found
        ),
        Report(
            id: UUID(),
            category: .clothingApparel,
            createdByName: "Priya Desai",
            createdByEmail: "pdesai@wit.edu",
            createdByPhone: "6175558877",
            createdAt: Date().addingTimeInterval(-60 * 30),
            description: "Black North Face puffer jacket, women's medium.",
            title: "North Face Jacket",
            imageUrl: nil,
            locationBuilding: "Flanagan Campus Center",
            locationCoordinates: ReportCoordinates(latitude: 42.3373, longitude: -71.0932),
            reviewedAt: Date().addingTimeInterval(-60 * 10),
            reviewedBy: "knguyen@wit.edu",
            status: .approved,
            type: .found
        )
    ]
}


