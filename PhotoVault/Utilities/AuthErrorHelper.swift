//
//  AuthErrorHelper.swift
//  PhotoVault
//
//  Created by Vir Daksh on 02/07/26.
//

import Foundation
import FirebaseAuth

public struct AuthErrorHelper {
    /// Maps generic Errors or FirebaseAuth Errors to readable user-facing strings
    public static func message(for error: Error) -> String {
        let nsError = error as NSError
        
        // Handle network loss separately if needed
        if nsError.domain == NSURLErrorDomain {
            return "No internet connection. Please verify your network and try again."
        }
        
        guard nsError.domain == AuthErrorDomain else {
            return error.localizedDescription
        }
        
        guard let errorCode = AuthErrorCode(_bridgedNSError: nsError as NSError) else {
            return error.localizedDescription
        }
        
        switch errorCode {
        case .invalidEmail:
            return "Please enter a valid email address."
        case .wrongPassword:
            return "Incorrect password. Please check your credentials and try again."
        case .userNotFound:
            return "No user found with this email address. Please sign up first."
        case .emailAlreadyInUse:
            return "This email address is already registered. Try logging in instead."
        case .weakPassword:
            return "Password must be at least 8 characters long, containing at least one letter and one number."
        case .networkError:
            return "Network error. Please check your internet connection."
        case .userDisabled:
            return "This user account has been disabled."
        case .requiresRecentLogin:
            return "Please log in again to perform this sensitive action."
        case .invalidCredential:
            return "Invalid login credentials. Please check your email and password."
        default:
            return error.localizedDescription
        }
    }
}
