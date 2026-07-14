//
//  HomeView.swift
//  PhotoVault
//
//  Created by Vir Daksh on 02/07/26.
//

import SwiftUI
import PhotosUI

public struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var uploadViewModel = UploadViewModel()
    
    @State private var photoToRename: Photo? = nil
    @State private var newPhotoName = ""
    @State private var showRenameAlert = false
    
    @State private var selectedPhotoForOptions: Photo? = nil
    @State private var photoToDelete: Photo? = nil
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Background Gradient
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    // Header Search and Category chip selection
                    VStack(spacing: 12) {
                        SearchBar(text: $viewModel.searchText)
                            .padding(.horizontal)
                        
                        HStack(spacing: 12) {
                            FilterChip(title: "All Photos", isSelected: !viewModel.showOnlyFavorites) {
                                viewModel.showOnlyFavorites = false
                            }
                            
                            FilterChip(title: "Favorites", isSelected: viewModel.showOnlyFavorites) {
                                viewModel.showOnlyFavorites = true
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 8)
                    
                    ScrollView {
                        if viewModel.filteredPhotos.isEmpty {
                            VStack {
                                Spacer()
                                    .frame(height: 120)
                                if viewModel.searchText.isEmpty {
                                    EmptyStateView(
                                        iconName: "photo.on.rectangle.angled",
                                        title: "Your Vault is Empty",
                                        description: "Tap the floating upload button below to secure your first photo or video."
                                    )
                                } else {
                                    EmptyStateView(
                                        iconName: "magnifyingglass",
                                        title: "No Results Found",
                                        description: "No media items matched '\(viewModel.searchText)'."
                                    )
                                }
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, minHeight: 400)
                        } else {
                            // Media Scrollable Grid
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(viewModel.filteredPhotos) { photo in
                                    PhotoCard(photo: photo) {
                                        Task {
                                            await viewModel.toggleFavorite(for: photo)
                                        }
                                    }
                                    .onTapGesture {
                                        selectedPhotoForOptions = photo
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 100) // Avoid overlap with the floating button
                        }
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
                
                // Floating Picker Button
                PhotosPicker(
                    selection: $uploadViewModel.selectedItem,
                    matching: .any(of: [.images, .videos]),
                    photoLibrary: .shared()
                ) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("Upload Media")
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 28)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(30)
                    .shadow(color: Color.purple.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.bottom, 24)
                
                // Floating progress indicator
                if uploadViewModel.isUploading {
                    UploadProgressView(progress: uploadViewModel.uploadProgress)
                }
            }
            .navigationTitle("PhotoVault")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 12) {
                        NavigationLink(destination: Text("Albums Management Screen").font(.headline)) {
                            HStack(spacing: 4) {
                                Image(systemName: "folder.fill")
                                Text("Albums")
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        }
                        
                        NavigationLink(destination: RecentlyDeletedView()) {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ProfileView()) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
            }
            .alert("Upload Error", isPresented: $uploadViewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(uploadViewModel.errorMessage ?? "An error occurred during upload.")
            }
            .alert("Rename Photo", isPresented: $showRenameAlert) {
                TextField("Enter new name", text: $newPhotoName)
                Button("Cancel", role: .cancel) {
                    photoToRename = nil
                }
                Button("Save") {
                    if let photo = photoToRename {
                        Task {
                            await viewModel.renamePhoto(photo, to: newPhotoName)
                            photoToRename = nil
                        }
                    }
                }
            } message: {
                Text("Enter a new name for this photo.")
            }
            .confirmationDialog(
                "Options",
                isPresented: Binding(
                    get: { selectedPhotoForOptions != nil },
                    set: { if !$0 { selectedPhotoForOptions = nil } }
                ),
                titleVisibility: .hidden
            ) {
                Button("Delete", role: .destructive) {
                    photoToDelete = selectedPhotoForOptions
                    selectedPhotoForOptions = nil
                }
                Button("Cancel", role: .cancel) {
                    selectedPhotoForOptions = nil
                }
            }
            .alert(
                "Move this photo to Recently Deleted?",
                isPresented: Binding(
                    get: { photoToDelete != nil },
                    set: { if !$0 { photoToDelete = nil } }
                )
            ) {
                Button("Cancel", role: .cancel) {
                    photoToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let photo = photoToDelete {
                        Task {
                            await viewModel.softDelete(photo)
                            photoToDelete = nil
                        }
                    }
                }
            }
            .onChange(of: uploadViewModel.showSuccess) { success in
                if success {
                    Task {
                        await viewModel.refresh()
                    }
                }
            }
        }
    }
}

// Subview for categories
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.footnote)
                .fontWeight(.bold)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(isSelected ? Color.blue : Color(.tertiarySystemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
                .shadow(color: isSelected ? Color.blue.opacity(0.2) : Color.clear, radius: 4)
        }
    }
}

#Preview {
    HomeView()
}

