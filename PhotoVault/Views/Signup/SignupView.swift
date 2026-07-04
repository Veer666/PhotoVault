//
//  SignupView.swift
//  PhotoVault
//
//  Created by Vir Daksh on 02/07/26.
//

import SwiftUI

public struct SignupView: View {
    @StateObject private var viewModel = SignupViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(.systemBackground), Color(.secondarySystemBackground), Color.purple.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Background decorative circles
            GeometryReader { geo in
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 320, height: 320)
                    .blur(radius: 60)
                    .offset(x: -90, y: -60)
                
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 300, height: 300)
                    .blur(radius: 70)
                    .offset(x: geo.size.width - 220, y: geo.size.height - 250)
            }
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Text("Create Account")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        
                        Text("Get started with your secure photo storage")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // Input Card
                    VStack(spacing: 20) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.secondary)
                                
                                TextField("Enter your email", text: $viewModel.email)
                                    .textInputAutocapitalization(.none)
                                    .autocorrectionDisabled()
                                    .keyboardType(.emailAddress)
                            }
                            .padding()
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(viewModel.email.isEmpty || Validation.isValidEmail(viewModel.email) ? Color.clear : Color.red.opacity(0.5), lineWidth: 1)
                            )
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.secondary)
                                
                                if isPasswordVisible {
                                    TextField("Create password", text: $viewModel.password)
                                } else {
                                    SecureField("Create password", text: $viewModel.password)
                                }
                                
                                Button(action: { isPasswordVisible.toggle() }) {
                                    Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(12)
                        }
                        
                        // Confirm Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Image(systemName: "lock.shield.fill")
                                    .foregroundColor(.secondary)
                                
                                if isConfirmPasswordVisible {
                                    TextField("Re-enter password", text: $viewModel.confirmPassword)
                                } else {
                                    SecureField("Re-enter password", text: $viewModel.confirmPassword)
                                }
                                
                                Button(action: { isConfirmPasswordVisible.toggle() }) {
                                    Image(systemName: isConfirmPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color(.tertiarySystemBackground))
                            .cornerRadius(12)
                        }
                        
                        // Requirements hint
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: viewModel.password.count >= 8 ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(viewModel.password.count >= 8 ? .green : .secondary)
                                Text("At least 8 characters")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            HStack {
                                Image(systemName: Validation.isValidPassword(viewModel.password) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(Validation.isValidPassword(viewModel.password) ? .green : .secondary)
                                Text("Must contain 1 letter and 1 number")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                        
                        // Signup Button
                        CustomButton(title: "Sign Up", isLoading: viewModel.isLoading) {
                            Task {
                                await viewModel.signUp()
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(24)
                    .background(.ultraThinMaterial)
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 10)
                    .padding(.horizontal)
                    
                    // Back to Login link
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Text("Already have an account?")
                                .foregroundColor(.secondary)
                            Text("Log In")
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                        .font(.subheadline)
                    }
                    .padding(.bottom, 20)
                }
            }
            
            if viewModel.isLoading {
                LoadingView(message: "Creating account...")
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .alert("Error", isPresented: $viewModel.showError, actions: {
            Button("OK", role: .cancel) {}
        }, message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred.")
        })
    }
}

#Preview {
    SignupView()
}
