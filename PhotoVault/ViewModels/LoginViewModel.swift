//
//  LoginViewModel.swift
//  PhotoVault
//
//  Created by Vir Daksh on 02/07/26.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
public final class LoginViewModel: ObservableObject {
    @Published public var email = ""
    @Published public var password = ""
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    @Published public var showError = false
    @Published public var showResetSuccess = false
    
    public init() {}
    
    public var isFormValid: Bool {
        Validation.isValidEmail(email) && password.count >= 8
    }
    
    /// Trigger login with current email and password
    public func login() async {
        guard isFormValid else {
            self.errorMessage = "Please check your email formatting and ensure your password is at least 8 characters."
            self.showError = true
            return
        }
        
        self.isLoading = true
        self.errorMessage = nil
        
        do {
            _ = try await AuthManager.shared.signIn(withEmail: email, password: password)
        } catch {
            self.errorMessage = AuthErrorHelper.message(for: error)
            self.showError = true
        }
        
        self.isLoading = false
    }
    
    /// Trigger a password reset email
    public func resetPassword() async {
        guard Validation.isValidEmail(email) else {
            self.errorMessage = "Please enter a valid email address first."
            self.showError = true
            return
        }
        
        self.isLoading = true
        self.errorMessage = nil
        
        do {
            try await AuthManager.shared.sendPasswordReset(toEmail: email)
            self.showResetSuccess = true
        } catch {
            self.errorMessage = AuthErrorHelper.message(for: error)
            self.showError = true
        }
        
        self.isLoading = false
    }
}
