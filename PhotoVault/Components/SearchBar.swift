//
//  SearchBar.swift
//  PhotoVault
//
//  Created by Vir Daksh on 02/07/26.
//

import SwiftUI

public struct SearchBar: View {
    @Binding public var text: String
    public var placeholder: String
    
    public init(text: Binding<String>, placeholder: String = "Search photos...") {
        self._text = text
        self.placeholder = placeholder
    }
    
    public var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.none)
                .autocorrectionDisabled()
            
            if !text.isEmpty {
                Button(action: {
                    self.text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.02), radius: 3)
    }
}

#Preview {
    SearchBar(text: .constant(""))
        .padding()
}
