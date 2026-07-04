//
//  Album.swift
//  PhotoVault
//
//  Created by Vir Daksh on 02/07/26.
//

import Foundation

public struct Album: Codable, Identifiable, Sendable {
    public let id: String // Matches albumID
    public let userID: String
    public var name: String
    public let createdAt: Date
    public var updatedAt: Date
    
    public init(id: String, userID: String, name: String, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.userID = userID
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
