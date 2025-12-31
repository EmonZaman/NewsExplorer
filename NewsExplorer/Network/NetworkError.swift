//
//  NetworkError.swift
//  NewsExplorer
//
//  Created by Aagontuk on 12/31/25.
//

import Foundation

// MARK: - Network Error

enum NetworkError: Error, Equatable {
    case invalidURL
    case noData
    case decodingError(String)
    case serverError(statusCode: Int, message: String)
    case networkUnavailable
    case timeout
    case unauthorized
    case rateLimited
    case unknown(String)
    
    // MARK: - User-Friendly Message
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL. Please try again later."
        case .noData:
            return "No data received from server."
        case .decodingError(let message):
            return "Failed to process data: \(message)"
        case .serverError(let statusCode, let message):
            return "Server error (\(statusCode)): \(message)"
        case .networkUnavailable:
            return "Network unavailable. Please check your internet connection."
        case .timeout:
            return "Request timed out. Please try again."
        case .unauthorized:
            return "Authentication failed. Please check your API key."
        case .rateLimited:
            return "Too many requests. Please try again later."
        case .unknown(let message):
            return "An unexpected error occurred: \(message)"
        }
    }
    
    // MARK: - Retry Eligibility
    
    var isRetryable: Bool {
        switch self {
        case .networkUnavailable, .timeout, .rateLimited:
            return true
        case .serverError(let statusCode, _):
            return statusCode >= 500
        default:
            return false
        }
    }
}

// MARK: - HTTP Status Code Mapping

extension NetworkError {
    
    static func fromStatusCode(_ statusCode: Int, message: String = "") -> NetworkError {
        switch statusCode {
        case 401:
            return .unauthorized
        case 429:
            return .rateLimited
        case 400..<500:
            return .serverError(statusCode: statusCode, message: message.isEmpty ? "Client error" : message)
        case 500..<600:
            return .serverError(statusCode: statusCode, message: message.isEmpty ? "Server error" : message)
        default:
            return .unknown("Status code: \(statusCode)")
        }
    }
}


