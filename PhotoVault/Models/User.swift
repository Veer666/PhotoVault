//
//  User.swift
//  PhotoVault
//
//  Created by Vir Daksh on 02/07/26.
//

import Foundation

public struct User: Codable, Identifiable, Sendable {
    public var id: String { uid }
    public let uid: String
    public let email: String
    public var totalPhotos: Int
    public var totalAlbums: Int
    public var totalStorageUsed: Int64 // in bytes
    public let createdAt: Date
    public var updatedAt: Date
    
    public init(uid: String, email: String, totalPhotos: Int = 0, totalAlbums: Int = 0, totalStorageUsed: Int64 = 0, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.uid = uid
        self.email = email
        self.totalPhotos = totalPhotos
        self.totalAlbums = totalAlbums
        self.totalStorageUsed = totalStorageUsed
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
