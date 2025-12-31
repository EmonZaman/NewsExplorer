//
//  SceneDelegate.swift
//  NewsExplorer
//
//  Created by Aagontuk on 12/30/25.
//


import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    // MARK: - Properties
    
    var window: UIWindow?
    
    // MARK: - UIWindowSceneDelegate
    
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // Create window
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        
        // Configure navigation bar appearance
        configureNavigationBarAppearance()
        
        // Set up root view controller with MVVM
        let repository = NewsRepository()
        let viewModel = NewsListViewModel(repository: repository)
        let newsListVC = NewsListViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: newsListVC)
        
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Release resources for this scene
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Restart tasks that were paused
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Pause ongoing tasks
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Undo changes made on entering background
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Save data and release shared resources
    }
    
    // MARK: - Private Methods
    
    private func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(named: "PrimaryColor") ?? UIColor.systemBackground
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().prefersLargeTitles = true
        UINavigationBar.appearance().tintColor = UIColor(named: "AccentColor") ?? .systemBlue
    }
}
