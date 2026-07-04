//
//  PhotoCard.swift
//  PhotoVault
//
//  Created by Vir Daksh on 02/07/26.
//

import SwiftUI

public struct PhotoCard: View {
    public let photo: Photo
    public let onFavoriteToggle: () -> Void
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    public init(photo: Photo, onFavoriteToggle: @escaping () -> Void) {
        self.photo = photo
        self.onFavoriteToggle = onFavoriteToggle
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                // Media preview (AsyncImage)
                AsyncImage(url: URL(string: photo.imageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 140)
                            .clipped()
                    case .failure:
                        Image(systemName: photo.mediaType == "video" ? "video.fill" : "photo.fill")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                            .frame(height: 140)
                            .frame(maxWidth: .infinity)
                            .background(Color(.secondarySystemBackground))
                    case .empty:
                        ProgressView()
                            .frame(height: 140)
                            .frame(maxWidth: .infinity)
                            .background(Color(.secondarySystemBackground))
                    @unknown default:
                        EmptyView()
                    }
                }
                
                // Video Play Icon overlay if video
                if photo.mediaType == "video" {
                    Color.black.opacity(0.15)
                        .frame(height: 140)
                    
                    Image(systemName: "play.circle.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 4)
                        .frame(height: 140)
                        .frame(maxWidth: .infinity)
                }
                
                // Favorite Heart Overlay (Top Right)
                Image(systemName: photo.isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(photo.isFavorite ? .red : .white)
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.1), radius: 3)
                    .onTapGesture {
                        onFavoriteToggle()
                    }
                    .padding(8)
            }
            
            // Text Details
            VStack(alignment: .leading, spacing: 4) {
                Text(photo.photoName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(dateFormatter.string(from: photo.createdAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    PhotoCard(
        photo: Photo(
            id: "1",
            userID: "1",
            photoName: "Sunset Drive.jpg",
            imageURL: "https://picsum.photos/200",
            isFavorite: true,
            createdAt: Date(),
            mediaType: "image"
        ),
        onFavoriteToggle: {}
    )
    .frame(width: 170)
    .padding()
}

