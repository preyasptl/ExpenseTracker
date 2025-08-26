//
//  SplashScreenView.swift
//  ExpenseTracker
//
//  Created by iMacPro on 26/06/25.
//


import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimating = false
    @State private var showText = false
    
    var body: some View {
        ZStack {
            // Background gradient
            ThemeColors.primaryGradient
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // App icon with animation
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                    
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        .animation(
                            Animation.linear(duration: 2.0)
                                .repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                }
                
                // App name with typing animation
                if showText {
                    VStack(spacing: 8) {
                        Text("ExpenseTracker")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        
                        Text("Track your expenses smartly")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                isAnimating = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    showText = true
                }
            }
        }
    }
}
