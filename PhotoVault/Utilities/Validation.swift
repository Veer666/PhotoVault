//
//  Validation.swift
//  PhotoVault
//
//  Created by Vir Daksh on 02/07/26.
//
import Foundation

public struct Validation {

    // MARK: - Email Validation
    public static func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}$"#
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    // MARK: - Password Validation
    //
    // Rules:
    // ✅ Minimum 8 characters
    // ✅ At least one uppercase letter
    // ✅ At least one lowercase letter
    // ✅ At least one number
    // ✅ At least one special character
    //
    // Examples:
    // Sahil@123
    // PhotoVault@2026
    // Apple#123
    //
    public static func isValidPassword(_ password: String) -> Bool {

        let passwordRegEx =
        #"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&^#()_\-+=])[A-Za-z\d@$!%*?&^#()_\-+=]{8,}$"#

        let passwordPred = NSPredicate(format: "SELF MATCHES %@", passwordRegEx)

        return passwordPred.evaluate(with: password)
    }

    // MARK: - Password Requirements

    public static func hasMinimumLength(_ password: String) -> Bool {
        password.count >= 8
    }

    public static func hasUppercase(_ password: String) -> Bool {
        password.contains { $0.isUppercase }
    }

    public static func hasLowercase(_ password: String) -> Bool {
        password.contains { $0.isLowercase }
    }

    public static func hasNumber(_ password: String) -> Bool {
        password.contains { $0.isNumber }
    }

    public static func hasSpecialCharacter(_ password: String) -> Bool {

        let specialCharacters = CharacterSet(charactersIn: "@$!%*?&^#()_-+=")

        return password.unicodeScalars.contains {
            specialCharacters.contains($0)
        }
    }

    // MARK: - Password Match

    public static func passwordsMatch(_ password: String,
                                      _ confirmPassword: String) -> Bool {
        password == confirmPassword
    }

    // MARK: - Password Strength

    public static func passwordStrength(_ password: String) -> String {

        var score = 0

        if hasMinimumLength(password) { score += 1 }
        if hasUppercase(password) { score += 1 }
        if hasLowercase(password) { score += 1 }
        if hasNumber(password) { score += 1 }
        if hasSpecialCharacter(password) { score += 1 }

        switch score {
        case 0...2:
            return "Weak"

        case 3...4:
            return "Medium"

        case 5:
            return "Strong"

        default:
            return "Weak"
        }
    }
}
