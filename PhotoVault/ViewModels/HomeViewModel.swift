//
//  HomeViewModel.swift
//  PhotoVault
//
//  Created by Vir Daksh on 02/07/26.
//

import Foundation
import FirebaseFirestore
import Combine
import FirebaseAuth

@MainActor
public final class HomeViewModel: ObservableObject {
    @Published public var photos: [Photo] = []
    @Published public var albums: [Album] = []
    
    @Published public var searchText = ""
    @Published public var showOnlyFavorites = false
    
    private var photosListener: ListenerRegistration?
    private var albumsListener: ListenerRegistration?
    
    public init() {
        self.startListening()
    }
    
    deinit {
        photosListener?.remove()
        albumsListener?.remove()
    }
    
    /// Starts real-time observation of the user's photos and albums
    public func startListening() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        // Remove existing listeners if any
        photosListener?.remove()
        albumsListener?.remove()
        
        let db = Firestore.firestore()
        
        // Listen to Active Photos (not soft-deleted)
        let photosQuery = db.collection("photos")
            .whereField("userID", isEqualTo: userID)
            .whereField("isDeleted", isEqualTo: false)
            .order(by: "createdAt", descending: true)
        
        photosListener = photosQuery.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                print("🔥 FIRESTORE ERROR:")
                print(error.localizedDescription)
                return
            }

            guard let documents = snapshot?.documents else {
                print("No documents received")
                return
            }

            print("Documents Count: \(documents.count)")

            DispatchQueue.main.async {
                self.photos = documents.compactMap { doc in
                    try? doc.data(as: Photo.self)
                }

                print("Decoded Photos: \(self.photos.count)")
            }
        }
        // Listen to Albums
        let albumsQuery = db.collection("albums")
            .whereField("userID", isEqualTo: userID)
            .order(by: "createdAt", descending: true)
        
        albumsListener = albumsQuery.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error {
                print("Error listening to albums: \(error.localizedDescription)")
                return
            }
            guard let documents = snapshot?.documents else { return }
            
            DispatchQueue.main.async {
                self.albums = documents.compactMap { doc in
                    try? doc.data(as: Album.self)
                }
            }
        }
    }
    
    /// Maps album IDs to album names for search filtering
    private var albumNamesDict: [String: String] {
        Dictionary(uniqueKeysWithValues: albums.map { ($0.id, $0.name) })
    }
    
    /// Filtered list of photos matching search and favorite criteria
    public var filteredPhotos: [Photo] {
        photos.filter { photo in
            // 1. Favorites Filter
            if showOnlyFavorites && !photo.isFavorite {
                return false
            }
            
            // 2. Search Text Filter
            if searchText.isEmpty {
                return true
            }
            
            let query = searchText.lowercased()
            let matchesName = photo.photoName.lowercased().contains(query)
            
            // Resolve Album Name to match photo's album
            let albumName = photo.albumID.flatMap { albumNamesDict[$0] }?.lowercased() ?? ""
            let matchesAlbum = albumName.contains(query)
            
            return matchesName || matchesAlbum
        }
    }
    
    /// Toggle photo favorite status in Firestore
    public func toggleFavorite(for photo: Photo) async {
        var updated = photo
        updated.isFavorite.toggle()
        updated.updatedAt = Date()
        
        do {
            try await FirestoreManager.shared.updatePhotoMetadata(updated)
        } catch {
            print("Failed to toggle favorite: \(error.localizedDescription)")
        }
    }
    
    /// Soft delete: Move photo to Recently Deleted and decrement user stats
    public func softDelete(_ photo: Photo) async {
        var updated = photo
        updated.isDeleted = true
        updated.deletedAt = Date()
        updated.updatedAt = Date()
        
        do {
            try await FirestoreManager.shared.updatePhotoMetadata(updated)
            // Decrement statistics
            try await FirestoreManager.shared.incrementUserStats(
                uid: photo.userID,
                bytesCount: -photo.fileSize,
                photosDelta: -1
            )
        } catch {
            print("Failed to delete photo: \(error.localizedDescription)")
        }
    }
    
    /// Rename a photo document metadata in Firestore
    public func renamePhoto(_ photo: Photo, to newName: String) async {
        var updated = photo
        updated.photoName = newName
        updated.updatedAt = Date()
        
        do {
            try await FirestoreManager.shared.updatePhotoMetadata(updated)
        } catch {
            print("Failed to rename photo: \(error.localizedDescription)")
        }
    }
}
