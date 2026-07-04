//
//  ProfileView.swift
//  PhotoVault
//
//  Created by Vir Daksh on 03/07/26.
//

import SwiftUI
import FirebaseAuth

public struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showLogoutConfirmation = false
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // White/secondary background (dark mode compatible)
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // MARK: - SECTION 1: USER INFO
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 90, height: 90)
                            .foregroundColor(.blue)
                            .background(
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 96, height: 96)
                            )
                            .padding(.bottom, 8)
                        
                        Text(AuthManager.shared.currentUser?.email ?? "User Email")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("UID: \(AuthManager.shared.currentUser?.uid ?? "Unknown")")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 4)
                    
                    // MARK: - SECTION 2: STATISTICS
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Library Stats")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                        
                        HStack(spacing: 12) {
                            StatCard(
                                iconName: "photo.on.rectangle.angled",
                                title: "Photos",
                                value: "\(viewModel.userProfile?.totalPhotos ?? 0)",
                                color: .blue
                            )
                            
                            StatCard(
                                iconName: "cloud.fill",
                                title: "Storage",
                                value: ByteFormatter.format(bytes: viewModel.userProfile?.totalStorageUsed ?? 0),
                                color: .purple
                            )
                            
                            StatCard(
                                iconName: "heart.fill",
                                title: "Favorites",
                                value: "\(viewModel.favoriteCount)",
                                color: .red
                            )
                        }
                    }
                    
                    // MARK: - SECTION 3: ACCOUNT ACTIONS
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Account settings")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                        
                        VStack(spacing: 0) {
                            // Change Password Row
                            Button(action: {
                                Task {
                                    await viewModel.changePassword()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "key.fill")
                                        .foregroundColor(.blue)
                                        .frame(width: 24)
                                    Text("Change Password")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemBackground))
                            }
                            
                            Divider()
                                .padding(.leading, 52)
                            
                            // Log Out Row
                            Button(action: {
                                showLogoutConfirmation = true
                            }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .foregroundColor(.red)
                                        .frame(width: 24)
                                    Text("Log Out")
                                        .fontWeight(.medium)
                                        .foregroundColor(.red)
                                    Spacer()
                                }
                                .padding()
                                .background(Color(.systemBackground))
                            }
                        }
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 4)
                    }
                    
                    // MARK: - SECTION 4: VERSION
                    VStack(spacing: 4) {
                        Text("PhotoVault")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                        Text("Version 1.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
                .padding(.horizontal)
            }
            
            if viewModel.isLoading {
                LoadingView(message: "Updating Profile...")
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.fetchProfile()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred.")
        }
        .alert("Reset Password Link Sent", isPresented: $viewModel.showPasswordResetSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("A password reset email has been sent. Please check your inbox.")
        }
        .confirmationDialog(
            "Are you sure you want to log out?",
            isPresented: $showLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Log Out", role: .destructive) {
                do {
                    try viewModel.logout()
                    dismiss()
                } catch {
                    viewModel.errorMessage = error.localizedDescription
                    viewModel.showError = true
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// Sub-component: StatCard
struct StatCard: View {
    let iconName: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 3)
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
}
