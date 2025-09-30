//
//  MainAppView.swift
//  SacaviaApp
//
//  Created by Antonio Kodheli on 1/16/25.
//

import SwiftUI

struct MainAppView: View {
    @State private var showSplashScreen = false
    @State private var hasCheckedFirstLaunch = false
    
    var body: some View {
        ZStack {
            if showSplashScreen {
                SplashScreenView {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showSplashScreen = false
                    }
                }
                .transition(.opacity)
            } else {
                ContentView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showSplashScreen)
        .onAppear {
            checkFirstLaunch()
        }
    }
    
    private func checkFirstLaunch() {
        guard !hasCheckedFirstLaunch else { return }
        hasCheckedFirstLaunch = true
        
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "HasLaunchedBefore")
        
        if !hasLaunchedBefore {
            // First launch - show splash screen
            print("🎉 First app launch - showing splash screen")
            showSplashScreen = true
            
            // Mark that the app has launched before
            UserDefaults.standard.set(true, forKey: "HasLaunchedBefore")
        } else {
            // Not first launch - go directly to main app
            print("📱 App has launched before - skipping splash screen")
            showSplashScreen = false
        }
    }
}

// MARK: - Preview
struct MainAppView_Previews: PreviewProvider {
    static var previews: some View {
        MainAppView()
    }
}
