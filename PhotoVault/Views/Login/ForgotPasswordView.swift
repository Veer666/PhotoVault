//
//  ForgotPasswordView.swift
//  PhotoVault
//
//  Created by Vir Daksh on 02/07/26.
//

import SwiftUI

public struct ForgotPasswordView: View {
    @StateObject private var viewModel = LoginViewModel()
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(.systemBackground), Color(.secondarySystemBackground), Color.blue.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 80, height: 80)
                            .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        Image(systemName: "key.horizontal.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    
                    Text("Reset Password")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    
                    Text("Enter your email address and we'll send you a link to reset your password.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 40)
                
                // Form
                VStack(spacing: 20) {
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
                    }
                    
                    CustomButton(title: "Send Link", isLoading: viewModel.isLoading) {
                        Task {
                            await viewModel.resetPassword()
                        }
                    }
                }
                .padding(24)
                .background(.ultraThinMaterial)
                .cornerRadius(24)
                .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 10)
                .padding(.horizontal)
                
                Spacer()
            }
            
            if viewModel.isLoading {
                LoadingView(message: "Sending email...")
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
        .alert("Success", isPresented: $viewModel.showResetSuccess, actions: {
            Button("OK", role: .cancel) {
                dismiss()
            }
        }, message: {
            Text("A password reset link has been sent to your email. Please check your inbox.")
        })
    }
}

#Preview {
    ForgotPasswordView()
}
