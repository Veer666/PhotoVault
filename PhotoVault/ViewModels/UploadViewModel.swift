//
//  UploadViewModel.swift
//  PhotoVault
//
//  Created by Vir Daksh on 02/07/26.
//

import Foundation
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import FirebaseAuth
import Combine

@MainActor
public final class UploadViewModel: ObservableObject {
    @Published public var selectedItem: PhotosPickerItem? {
        didSet {
            if selectedItem != nil {
                Task {
                    await handleSelection()
                }
            }
        }
    }
    
    @Published public var uploadProgress: Double = 0.0
    @Published public var isUploading = false
    @Published public var errorMessage: String?
    @Published public var showError = false
    @Published public var showSuccess = false
    
    public init() {}
    
    /// Handle PhotosPicker selection and trigger appropriate upload flow
    private func handleSelection() async {
        guard let item = selectedItem else { return }
        
        self.isUploading = true
        self.uploadProgress = 0.0
        self.errorMessage = nil
        self.showSuccess = false
        
        do {
            guard let userID = AuthManager.shared.currentUser?.uid else {
                throw NSError(
                    domain: "UploadViewModel",
                    code: 401,
                    userInfo: [NSLocalizedDescriptionKey: "User not authenticated. Please log in again."]
                )
            }
            
            // 1. Load data
            guard let rawData = try await item.loadTransferable(type: Data.self) else {
                throw NSError(
                    domain: "UploadViewModel",
                    code: -2,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to extract media data. Try selecting another file."]
                )
            }
            
            var mediaData = rawData
            var mediaType = "image"
            var fileName = "photo_\(UUID().uuidString.prefix(8)).jpg"
            
            // 2. Identify and compress if photo
            if let contentType = item.supportedContentTypes.first {
                if contentType.conforms(to: UTType.image) {
                    mediaType = "image"
                    if let image = UIImage(data: rawData) {
                        // Compress photo to under 1MB
                        if let compressed = CloudinaryManager.shared.compressImage(image) {
                            mediaData = compressed
                        }
                    }
                } else if contentType.conforms(to: UTType.movie) || contentType.conforms(to: UTType.video) {
                    mediaType = "video"
                    fileName = "video_\(UUID().uuidString.prefix(8)).mp4"
                }
            }
            
            let photoID = UUID().uuidString
            
            // 3. Upload file to Cloudinary
            let downloadURL = try await CloudinaryManager.shared.uploadPhoto(
                data: mediaData,
                userID: userID,
                photoID: photoID,
                mediaType: mediaType
            ) { [weak self] progress in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.uploadProgress = progress
                }
            }
            
            // 4. Save metadata to Cloud Firestore
            let photoMetadata = Photo(
                id: photoID,
                userID: userID,
                photoName: fileName,
                imageURL: downloadURL,
                albumID: nil,
                isFavorite: false,
                createdAt: Date(),
                updatedAt: Date(),
                isDeleted: false,
                deletedAt: nil,
                mediaType: mediaType,
                fileSize: Int64(mediaData.count)
            )
            
            do {
                try await FirestoreManager.shared.savePhotoMetadata(photoMetadata)
                print("✅ Photo metadata saved")
            } catch {
                print("❌ savePhotoMetadata failed:")
                print(error)
                throw error
            }
            
            // 5. Atomic increment stats in Firestore user document
            do {
                try await FirestoreManager.shared.incrementUserStats(
                    uid: userID,
                    bytesCount: Int64(mediaData.count),
                    photosDelta: 1
                )
                print("✅ User stats updated")
            } catch {
                print("❌ incrementUserStats failed:")
                print(error)
                throw error
            }
            
            self.showSuccess = true
            self.selectedItem = nil // Reset selected item after success
            
        } catch {
            self.errorMessage = AuthErrorHelper.message(for: error)
            self.showError = true
        }
        
        self.isUploading = false
    }
}
