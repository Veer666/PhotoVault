//
//  ProfileViewModel.swift
//  PhotoVault
//
//  Created by Vir Daksh on 03/07/26.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

@MainActor
public final class ProfileViewModel: ObservableObject {
    @Published public var userProfile: User?
    @Published public var favoriteCount = 0
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    @Published public var showError = false
    @Published public var showPasswordResetSuccess = false
    
    public init() {}
    
    /// Retrieve user profile statistics and calculate favorites count
    public func fetchProfile() async {
        guard let userID = AuthManager.shared.currentUser?.uid else { return }
        
        self.isLoading = true
        self.errorMessage = nil
        
        do {
            // 1. Fetch user counts and statistics from Firestore
            do {
                self.userProfile = try await FirestoreManager.shared.fetchUserProfile(uid: userID)
            } catch {
                // If the profile document doesn't exist, create a local fallback instead of crashing
                let fallbackEmail = AuthManager.shared.currentUser?.email ?? ""
                self.userProfile = User(
                    uid: userID,
                    email: fallbackEmail,
                    totalPhotos: 0,
                    totalAlbums: 0,
                    totalStorageUsed: 0
                )
            }
            
            // 2. Perform aggregate count of favorite photos
            let db = Firestore.firestore()
            let query = db.collection("photos")
                .whereField("userID", isEqualTo: userID)
                .whereField("isDeleted", isEqualTo: false)
                .whereField("isFavorite", isEqualTo: true)
            
            let countQuery = query.count
            let countSnapshot = try await countQuery.getAggregation(source: .server)
            self.favoriteCount = countSnapshot.count.intValue
            
        } catch {
            self.errorMessage = AuthErrorHelper.message(for: error)
            self.showError = true
        }
        
        self.isLoading = false
    }
    
    /// Triggers password reset email via AuthManager
    public func changePassword() async {
        guard let email = AuthManager.shared.currentUser?.email else {
            self.errorMessage = "No email address found for the current user session."
            self.showError = true
            return
        }
        
        self.isLoading = true
        self.errorMessage = nil
        
        do {
            try await AuthManager.shared.sendPasswordReset(toEmail: email)
            self.showPasswordResetSuccess = true
        } catch {
            self.errorMessage = AuthErrorHelper.message(for: error)
            self.showError = true
        }
        
        self.isLoading = false
    }
    
    /// Sign out the current user session
    public func logout() throws {
        try AuthManager.shared.signOut()
    }
}

