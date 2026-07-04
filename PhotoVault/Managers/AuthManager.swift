//
//  AuthManager.swift
//  PhotoVault
//
//  Created by Vir Daksh on 02/07/26.
//

import Foundation
import FirebaseAuth
import Combine

@MainActor
public final class AuthManager: ObservableObject {
    public static let shared = AuthManager()
    
    @Published public var userSession: FirebaseAuth.User?
    
    private var handler: AuthStateDidChangeListenerHandle?
    
    private init() {
        // Track the current user session
        self.userSession = Auth.auth().currentUser
        
        self.handler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.userSession = user
            }
        }
    }
    
    deinit {
        if let handler = handler {
            Auth.auth().removeStateDidChangeListener(handler)
        }
    }
    
    public var currentUser: FirebaseAuth.User? {
        Auth.auth().currentUser
    }
    
    public var isAuthenticated: Bool {
        currentUser != nil
    }
    
    /// Sign up a new user using email and password
    public func signUp(withEmail email: String, password: String) async throws -> AuthDataResult {
        return try await Auth.auth().createUser(withEmail: email, password: password)
    }
    
    /// Log in an existing user using email and password
    public func signIn(withEmail email: String, password: String) async throws -> AuthDataResult {
        return try await Auth.auth().signIn(withEmail: email, password: password)
    }
    
    /// Send password reset link to user's email
    public func sendPasswordReset(toEmail email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
    
    /// Log out the current user
    public func signOut() throws {
        try Auth.auth().signOut()
    }
    
    /// Delete the current authenticated user account
    public func deleteAccount() async throws {
        guard let user = currentUser else {
            throw NSError(
                domain: "AuthManager",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "No user is currently signed in."]
            )
        }
        try await user.delete()
    }
}
