//
//  AppDelegate.swift
//  NewsExplorer
//
//  Created by Aagontuk on 12/30/25.
//
//


import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // MARK: - Application Lifecycle
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Configure app based on environment
        configureAppearance()
        configureEnvironment()
        
        return true
    }
    
    // MARK: - UISceneSession Lifecycle
    
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(
        _ application: UIApplication,
        didDiscardSceneSessions sceneSessions: Set<UISceneSession>
    ) {
        // Clean up resources for discarded scenes
    }
    
    // MARK: - Private Methods
    
    private func configureAppearance() {
        // Configure global appearance
        UINavigationBar.appearance().tintColor = UIColor(named: "AccentColor") ?? .systemBlue
        
        // Configure tab bar if needed
        UITabBar.appearance().tintColor = UIColor(named: "AccentColor") ?? .systemBlue
    }
    
    private func configureEnvironment() {
        let config = AppConfiguration.shared
        print("NewsExplorer running in \(config.environment.name) environment")
        
        if config.isLoggingEnabled {
            print("Logging is enabled")
            print("Base URL: \(config.baseURL)")
        }
    }
}
