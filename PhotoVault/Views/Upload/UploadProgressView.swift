//
//  UploadProgressView.swift
//  PhotoVault
//
//  Created by Vir Daksh on 02/07/26.
//

import SwiftUI

public struct UploadProgressView: View {
    public let progress: Double
    
    public init(progress: Double) {
        self.progress = progress
    }
    
    public var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Uploading Media...")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(.linear)
                    .tint(.blue)
                    .frame(width: 200)
                
                Text("\(Int(progress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
            }
            .padding(24)
            .background(.ultraThinMaterial)
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(0.1), radius: 10)
        }
    }
}

#Preview {
    UploadProgressView(progress: 0.45)
}
