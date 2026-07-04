//
//  FirestoreManager.swift
//  PhotoVault
//
//  Created by Vir Daksh on 02/07/26.
//

import Foundation
import FirebaseFirestore

public final class FirestoreManager: Sendable {
    public static let shared = FirestoreManager()
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - User Collection
    
    /// Create or update a user profile document
    public func saveUserProfile(_ user: User) async throws {
        let docRef = db.collection("users").document(user.uid)
        try docRef.setData(from: user)
    }
    
    /// Fetch a user profile document by UID
    public func fetchUserProfile(uid: String) async throws -> User {
        let docRef = db.collection("users").document(uid)
        return try await docRef.getDocument(as: User.self)
    }
    
    /// Update counts and storage usage for a user
    public func updateUserStorageStats(uid: String, totalPhotos: Int, totalAlbums: Int, totalStorageUsed: Int64) async throws {
        let docRef = db.collection("users").document(uid)
        try await docRef.updateData([
            "totalPhotos": totalPhotos,
            "totalAlbums": totalAlbums,
            "totalStorageUsed": totalStorageUsed,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }
    
    /// Atomically increment/decrement user storage statistics
    public func incrementUserStats(uid: String, bytesCount: Int64, photosDelta: Int) async throws {
        let docRef = db.collection("users").document(uid)
        try await docRef.updateData([
            "totalPhotos": FieldValue.increment(Int64(photosDelta)),
            "totalStorageUsed": FieldValue.increment(bytesCount),
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }
    
    // MARK: - Photo Collection
    
    /// Save new photo metadata
    public func savePhotoMetadata(_ photo: Photo) async throws {
        let docRef = db.collection("photos").document(photo.id)
        try docRef.setData(from: photo)
    }
    
    /// Update existing photo metadata (such as renaming or favoriting)
    public func updatePhotoMetadata(_ photo: Photo) async throws {
        let docRef = db.collection("photos").document(photo.id)
        try docRef.setData(from: photo)
    }
    
    /// Fetch all photos for a user, with optional filters
    public func fetchPhotos(forUserID userID: String, includeDeleted: Bool = false) async throws -> [Photo] {
        var query: Query = db.collection("photos")
            .whereField("userID", isEqualTo: userID)
        
        if !includeDeleted {
            query = query.whereField("isDeleted", isEqualTo: false)
        }
        
        let snapshot = try await query.getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: Photo.self) }
    }
    
    /// Fetch recently deleted photos for a user
    public func fetchRecentlyDeletedPhotos(forUserID userID: String) async throws -> [Photo] {
        let query = db.collection("photos")
            .whereField("userID", isEqualTo: userID)
            .whereField("isDeleted", isEqualTo: true)
        
        let snapshot = try await query.getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: Photo.self) }
    }
    
    /// Permanently delete a photo document from Firestore
    public func deletePhotoMetadata(photoID: String) async throws {
        let docRef = db.collection("photos").document(photoID)
        try await docRef.delete()
    }
    
    // MARK: - Album Collection
    
    /// Save or update an album document
    public func saveAlbum(_ album: Album) async throws {
        let docRef = db.collection("albums").document(album.id)
        try docRef.setData(from: album)
    }
    
    /// Fetch all albums for a user
    public func fetchAlbums(forUserID userID: String) async throws -> [Album] {
        let query = db.collection("albums")
            .whereField("userID", isEqualTo: userID)
        
        let snapshot = try await query.getDocuments()
        return try snapshot.documents.compactMap { try $0.data(as: Album.self) }
    }
    
    /// Delete an album and update any photos inside it to be unassigned
    public func deleteAlbum(albumID: String) async throws {
        // 1. Find all photos inside this album
        let photosQuery = db.collection("photos")
            .whereField("albumID", isEqualTo: albumID)
        
        let snapshot = try await photosQuery.getDocuments()
        
        // 2. Perform write batch to remove albumID from all matching photos and delete the album
        let batch = db.batch()
        
        for doc in snapshot.documents {
            batch.updateData(["albumID": FieldValue.delete()], forDocument: doc.reference)
        }
        
        let albumRef = db.collection("albums").document(albumID)
        batch.deleteDocument(albumRef)
        
        try await batch.commit()
    }
}
