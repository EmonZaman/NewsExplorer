//
//  Article.swift
//  NewsExplorer
//
//  Created by Aagontuk on 12/31/25.
//


import Foundation

// MARK: - News API Response

struct NewsResponse: Codable, Equatable {
    let status: String
    let totalResults: Int
    let articles: [Article]
}

// MARK: - Article Model

struct Article: Codable, Equatable, Hashable {
    let source: Source
    let author: String?
    let title: String
    let description: String?
    let url: String
    let urlToImage: String?
    let publishedAt: String
    let content: String?
    
    // MARK: - Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
    
    static func == (lhs: Article, rhs: Article) -> Bool {
        return lhs.url == rhs.url
    }
}

// MARK: - Source Model

struct Source: Codable, Equatable {
    let id: String?
    let name: String
}

// MARK: - Article Extensions

extension Article {
    
   
    var formattedDate: String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Try with fractional seconds first
        if let date = isoFormatter.date(from: publishedAt) {
            return formatDate(date)
        }
        
        // Try without fractional seconds
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: publishedAt) {
            return formatDate(date)
        }
        
        return publishedAt
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    /// Display title (never nil)
    var displayTitle: String {
        return title.isEmpty ? "No Title" : title
    }
    
    /// Display description (with fallback)
    var displayDescription: String {
        return description ?? "No description available"
    }
    
    /// Display author (with fallback)
    var displayAuthor: String {
        return author ?? source.name
    }
}

// MARK: - API Error Response

struct APIErrorResponse: Codable {
    let status: String
    let code: String
    let message: String
}




