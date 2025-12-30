//
//  Environment.swift
//  NewsExplorer
//
//  Created by Aagontuk on 12/31/25.
//


import Foundation

// MARK: - Environment Protocol

protocol EnvironmentProtocol {
    var baseURL: String { get }
    var apiKey: String { get }
    var name: String { get }
    var isLoggingEnabled: Bool { get }
}

// MARK: - Environment Enum

enum Environment: EnvironmentProtocol {
    case development
    case qa
    case production
    
    // MARK: - Properties
    
    var baseURL: String {
        switch self {
        case .development:
            return "https://newsapi.org/v2"
        case .qa:
            return "https://newsapi.org/v2"
        case .production:
            return "https://newsapi.org/v2"
        }
    }
    
    var apiKey: String {
      
        switch self {
        case .development:
            return "abf87ad1f7714eaab23219ba55cf199f"
        case .qa:
            return "abf87ad1f7714eaab23219ba55cf199f"
        case .production:
            return "abf87ad1f7714eaab23219ba55cf199f"
        }
    }
    
    var name: String {
        switch self {
        case .development:
            return "Development"
        case .qa:
            return "QA"
        case .production:
            return "Production"
        }
    }
    
    var isLoggingEnabled: Bool {
        switch self {
        case .development, .qa:
            return true
        case .production:
            return false
        }
    }
}

// MARK: - App Configuration

final class AppConfiguration {
    
    
    static let shared = AppConfiguration()
    
    // MARK: - Properties
    
    private(set) var environment: Environment
    
    // MARK: - Initialization
    
    private init() {
        #if DEBUG
        self.environment = .development
        #elseif QA
        self.environment = .qa
        #else
        self.environment = .production
        #endif
    }

    
    func configure(with environment: Environment) {
        self.environment = environment
    }
    
    var baseURL: String {
        return environment.baseURL
    }
    
    var apiKey: String {
        return environment.apiKey
    }
    
    var isLoggingEnabled: Bool {
        return environment.isLoggingEnabled
    }
}


