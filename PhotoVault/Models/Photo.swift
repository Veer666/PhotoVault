//
//  Photo.swift
//  PhotoVault
//
//  Created by Vir Daksh on 02/07/26.
//

import Foundation

public struct Photo: Codable, Identifiable, Sendable {
    public let id: String // Matches photoID
    public let userID: String
    public var photoName: String
    public let imageURL: String
    public var albumID: String?
    public var isFavorite: Bool
    public let createdAt: Date
    public var updatedAt: Date
    
    // Recently Deleted State
    public var isDeleted: Bool
    public var deletedAt: Date?
    
    // Media Type: "image" or "video"
    public var mediaType: String
    
    // File size in bytes
    public var fileSize: Int64
    
    public init(
        id: String,
        userID: String,
        photoName: String,
        imageURL: String,
        albumID: String? = nil,
        isFavorite: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isDeleted: Bool = false,
        deletedAt: Date? = nil,
        mediaType: String = "image",
        fileSize: Int64 = 0
    ) {
        self.id = id
        self.userID = userID
        self.photoName = photoName
        self.imageURL = imageURL
        self.albumID = albumID
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isDeleted = isDeleted
        self.deletedAt = deletedAt
        self.mediaType = mediaType
        self.fileSize = fileSize
    }
}

