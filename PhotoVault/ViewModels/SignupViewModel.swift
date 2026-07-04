//
//  SignupViewModel.swift
//  PhotoVault
//
//  Created by Vir Daksh on 02/07/26.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
public final class SignupViewModel: ObservableObject {
    @Published public var email = ""
    @Published public var password = ""
    @Published public var confirmPassword = ""
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    @Published public var showError = false
    
    public init() {}
    
    public var isFormValid: Bool {
        Validation.isValidEmail(email) &&
        Validation.isValidPassword(password) &&
        password == confirmPassword
    }
    
    /// Register a new user and set up their profile metadata in Firestore
    public func signUp() async {
        guard isFormValid else {
            if !Validation.isValidEmail(email) {
                self.errorMessage = "Please enter a valid email address."
            } else if !Validation.isValidPassword(password) {
                self.errorMessage = "Password must be at least 8 characters long, containing at least one letter and one number."
            } else {
                self.errorMessage = "Passwords do not match."
            }
            self.showError = true
            return
        }
        
        self.isLoading = true
        self.errorMessage = nil
        
        do {
            // 1. Sign up user via Firebase Auth
            let authResult = try await AuthManager.shared.signUp(withEmail: email, password: password)
            let user = authResult.user
            
            // 2. Initialize Firestore user profile document
            let userProfile = User(
                uid: user.uid,
                email: user.email ?? email,
                totalPhotos: 0,
                totalAlbums: 0,
                totalStorageUsed: 0,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            try await FirestoreManager.shared.saveUserProfile(userProfile)
            
        } catch {
            print("🔥 Full Error:", error)

            let nsError = error as NSError

            print("🔥 Domain:", nsError.domain)
            print("🔥 Code:", nsError.code)
            print("🔥 UserInfo:", nsError.userInfo)

            self.errorMessage = nsError.localizedDescription
            self.showError = true
        }
        
        self.isLoading = false
    }
}
