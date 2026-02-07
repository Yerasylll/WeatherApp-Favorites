//
//  WeatherApp_FavoritesApp.swift
//  WeatherApp-Favorites
//
//  Created by Yerasyl Alimbek on 04.02.2026.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        print("Firebase configured successfully")
        return true
    }
}

@main
struct WeatherApp_FavoritesApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authService = AuthenticationService.shared
    @StateObject private var repository = FirebaseRepository.shared
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(authService)
                .environmentObject(repository)
        }
    }
}
