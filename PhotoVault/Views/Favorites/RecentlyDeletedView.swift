//
//  RecentlyDeletedView.swift
//  PhotoVault
//
//  Created by Vir Daksh on 03/07/26.
//

import SwiftUI

public struct RecentlyDeletedView: View {
    @StateObject private var viewModel = RecentlyDeletedViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var photoToConfirmDelete: Photo?
    @State private var showDeleteConfirmation = false
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack {
                if viewModel.deletedPhotos.isEmpty {
                    Spacer()
                    EmptyStateView(
                        iconName: "trash.slash.fill",
                        title: "No Deleted Media",
                        description: "Photos and videos you delete will be kept here for 30 days before permanent deletion."
                    )
                    Spacer()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Items will be permanently deleted after 30 days.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .padding(.top, 12)
                            
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(viewModel.deletedPhotos) { photo in
                                    VStack(spacing: 0) {
                                        // Preview card
                                        PhotoCard(photo: photo) {}
                                            .disabled(true) // Disable heart toggle interactions
                                        
                                        // Actions Row
                                        HStack {
                                            Button(action: {
                                                Task {
                                                    await viewModel.restorePhoto(photo)
                                                }
                                            }) {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "arrow.clockwise")
                                                    Text("Restore")
                                                }
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.blue)
                                            }
                                            
                                            Spacer()
                                            
                                            Button(action: {
                                                photoToConfirmDelete = photo
                                                showDeleteConfirmation = true
                                            }) {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "trash.fill")
                                                    Text("Delete")
                                                }
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.red)
                                            }
                                        }
                                        .padding(10)
                                        .background(Color(.systemBackground))
                                        .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
                                    }
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .cornerRadius(16)
                                    .shadow(color: Color.black.opacity(0.04), radius: 5)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 24)
                        }
                    }
                }
            }
            
            if viewModel.isLoading {
                LoadingView(message: "Processing...")
            }
        }
        .navigationTitle("Recently Deleted")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Vault")
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .confirmationDialog(
            "Permanently Delete Photo?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Permanently", role: .destructive) {
                if let photo = photoToConfirmDelete {
                    Task {
                        await viewModel.permanentlyDelete(photo)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone. The file and metadata will be permanently deleted.")
        }
    }
}

// Helper extension to support selective corners rounding
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

#Preview {
    NavigationStack {
        RecentlyDeletedView()
    }
}
