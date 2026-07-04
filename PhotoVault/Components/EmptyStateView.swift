//
//  EmptyStateView.swift
//  PhotoVault
//
//  Created by Vir Daksh on 02/07/26.
//

import SwiftUI

public struct EmptyStateView: View {
    public let iconName: String
    public let title: String
    public let description: String
    
    public init(iconName: String, title: String, description: String) {
        self.iconName = iconName
        self.title = title
        self.description = description
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.6))
                .padding(.bottom, 8)
            
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    EmptyStateView(
        iconName: "photo.on.rectangle.angled",
        title: "No Photos Yet",
        description: "Tap the floating upload button below to select and upload your first photo."
    )
}

