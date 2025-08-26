//
//  ExpenseTrackerApp.swift
//  ExpenseTracker
//
//  Created by iMacPro on 26/06/25.
//

import SwiftUI
import Firebase

@main
struct ExpenseTrackerApp: App {
    @StateObject private var expenseStore = ExpenseStore()
    @State private var showSplashScreen = true
    
    init() {
        FirebaseApp.configure()
        print("🔥 Firebase configured successfully")
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplashScreen {
                    SplashScreenView()
                        .transition(.opacity)
                } else {
                    ContentView()
                        .environmentObject(expenseStore)
                        .transition(.opacity)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        showSplashScreen = false
                    }
                }
            }
        }
    }
}
