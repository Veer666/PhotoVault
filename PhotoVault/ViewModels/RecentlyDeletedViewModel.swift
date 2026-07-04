//
//  RecentlyDeletedViewModel.swift
//  PhotoVault
//
//  Created by Vir Daksh on 03/07/26.
//

import Foundation
import FirebaseFirestore
import Combine
import FirebaseAuth

@MainActor
public final class RecentlyDeletedViewModel: ObservableObject {
    @Published public var deletedPhotos: [Photo] = []
    @Published public var isLoading = false
    
    private var listener: ListenerRegistration?
    
    public init() {
        self.startListening()
    }
    
    deinit {
        listener?.remove()
    }
    
    /// Listens for recently deleted files in real time
    public func startListening() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        listener?.remove()
        
        let db = Firestore.firestore()
        let query = db.collection("photos")
            .whereField("userID", isEqualTo: userID)
            .whereField("isDeleted", isEqualTo: true)
            .order(by: "deletedAt", descending: true)
        
        listener = query.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error {
                print("Error listening to recently deleted: \(error.localizedDescription)")
                return
            }
            guard let documents = snapshot?.documents else { return }
            
            DispatchQueue.main.async {
                self.deletedPhotos = documents.compactMap { doc in
                    try? doc.data(as: Photo.self)
                }
            }
        }
    }
    
    /// Restores a photo to active vault state, re-incrementing user counts/storage statistics
    public func restorePhoto(_ photo: Photo) async {
        var updated = photo
        updated.isDeleted = false
        updated.deletedAt = nil
        updated.updatedAt = Date()
        
        self.isLoading = true
        do {
            // 1. Update document in Firestore
            try await FirestoreManager.shared.updatePhotoMetadata(updated)
            
            // 2. Re-increment statistics
            try await FirestoreManager.shared.incrementUserStats(
                uid: photo.userID,
                bytesCount: photo.fileSize,
                photosDelta: 1
            )
        } catch {
            print("Failed to restore photo: \(error.localizedDescription)")
        }
        self.isLoading = false
    }
    
    /// Permanently deletes photo metadata from Firestore and triggers Cloudinary mock delete
    public func permanentlyDelete(_ photo: Photo) async {
        self.isLoading = true
        do {
            // 1. Trigger deletion call on Cloudinary (mocks deletion for client-side API limits)
            try await CloudinaryManager.shared.deletePhoto(url: photo.imageURL)
            
            // 2. Delete Firestore document
            try await FirestoreManager.shared.deletePhotoMetadata(photoID: photo.id)
            
            // Note: We do NOT decrement statistics here as they were already decremented upon soft delete.
        } catch {
            print("Failed to permanently delete photo: \(error.localizedDescription)")
        }
        self.isLoading = false
    }
}
