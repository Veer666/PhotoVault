//
//  ContentView.swift
//  PhotoVault
//
//  Created by Vir Daksh on 02/07/26.
//

import SwiftUI
import FirebaseAuth
import FirebaseAuth

struct ContentView: View {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some View {
        Group {
            if authManager.userSession != nil {
                HomeView()
            } else {
                LoginView()
            }
        }
        .animation(.default, value: authManager.userSession)
    }
}

#Preview {
    ContentView()
}
