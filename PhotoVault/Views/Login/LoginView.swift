//
//  LoginView.swift
//  PhotoVault
//
//  Created by Vir Daksh on 02/07/26.
//

import SwiftUI

public struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var isPasswordVisible = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Premium background gradient
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.secondarySystemBackground), Color.blue.opacity(0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Background decorative circles
                GeometryReader { geo in
                    Circle()
                        .fill(Color.purple.opacity(0.12))
                        .frame(width: 300, height: 300)
                        .blur(radius: 60)
                        .offset(x: -80, y: -50)
                    
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 350, height: 350)
                        .blur(radius: 70)
                        .offset(x: geo.size.width - 250, y: geo.size.height - 250)
                }
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 80, height: 80)
                                    .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
                                
                                Image(systemName: "photo.stack.fill")
                                    .font(.title)
                                    .foregroundColor(.white)
                            }
                            
                            Text("PhotoVault")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                            
                            Text("Secure your memories in the cloud")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 40)
                        
                        // Input card
                        VStack(spacing: 20) {
                            // Email field
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
                            
                            // Password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.secondary)
                                    
                                    if isPasswordVisible {
                                        TextField("Enter your password", text: $viewModel.password)
                                    } else {
                                        SecureField("Enter your password", text: $viewModel.password)
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
                            
                            // Forgot Password link
                            HStack {
                                Spacer()
                                NavigationLink(destination: ForgotPasswordView()) {
                                    Text("Forgot Password?")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            // Login Action
                            CustomButton(title: "Log In", isLoading: viewModel.isLoading) {
                                Task {
                                    await viewModel.login()
                                }
                            }
                            .padding(.top, 8)
                        }
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .cornerRadius(24)
                        .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 10)
                        .padding(.horizontal)
                        
                        // Signup link
                        HStack(spacing: 4) {
                            Text("Don't have an account?")
                                .foregroundColor(.secondary)
                            
                            NavigationLink(destination: SignupView()) {
                                Text("Sign Up")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                        }
                        .font(.subheadline)
                        .padding(.bottom, 20)
                    }
                }
                
                if viewModel.isLoading {
                    LoadingView(message: "Logging in...")
                }
            }
            .alert("Error", isPresented: $viewModel.showError, actions: {
                Button("OK", role: .cancel) {}
            }, message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred.")
            })
        }
    }
}

#Preview {
    LoginView()
}
