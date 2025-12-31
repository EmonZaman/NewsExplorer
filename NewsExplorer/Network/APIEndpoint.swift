//
//  APIEndpoint.swift
//  NewsExplorer
//
//  Created by Aagontuk on 12/31/25.
//

import Foundation

// MARK: - HTTP Method

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

// MARK: - API Endpoint Protocol

protocol APIEndpointProtocol {
    var path: String { get }
    var method: HTTPMethod { get }
    var queryParameters: [String: String]? { get }
    var headers: [String: String]? { get }
    var body: Data? { get }
}

// MARK: - News API Endpoints

enum NewsAPIEndpoint: APIEndpointProtocol {
    case everything(query: String, from: String?, sortBy: String?, page: Int?, pageSize: Int?)
    case topHeadlines(country: String?, category: String?, page: Int?, pageSize: Int?)
    case sources(category: String?, language: String?, country: String?)
    
    // MARK: - Path
    
    var path: String {
        switch self {
        case .everything:
            return "/everything"
        case .topHeadlines:
            return "/top-headlines"
        case .sources:
            return "/top-headlines/sources"
        }
    }
    
    // MARK: - Method
    
    var method: HTTPMethod {
        return .get
    }
    
    // MARK: - Query Parameters
    
    var queryParameters: [String: String]? {
        var params: [String: String] = [:]
        
        switch self {
        case .everything(let query, let from, let sortBy, let page, let pageSize):
            params["q"] = query
            if let from = from {
                params["from"] = from
            }
            if let sortBy = sortBy {
                params["sortBy"] = sortBy
            }
            if let page = page {
                params["page"] = String(page)
            }
            if let pageSize = pageSize {
                params["pageSize"] = String(pageSize)
            }
            
        case .topHeadlines(let country, let category, let page, let pageSize):
            if let country = country {
                params["country"] = country
            }
            if let category = category {
                params["category"] = category
            }
            if let page = page {
                params["page"] = String(page)
            }
            if let pageSize = pageSize {
                params["pageSize"] = String(pageSize)
            }
            
        case .sources(let category, let language, let country):
            if let category = category {
                params["category"] = category
            }
            if let language = language {
                params["language"] = language
            }
            if let country = country {
                params["country"] = country
            }
        }
        
        return params.isEmpty ? nil : params
    }
    
    // MARK: - Headers
    
    var headers: [String: String]? {
        return [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    }
    
    // MARK: - Body
    
    var body: Data? {
        return nil
    }
}

// MARK: - URL Builder

extension APIEndpointProtocol {
    
    func buildURL(baseURL: String, apiKey: String) -> URL? {
        guard var components = URLComponents(string: baseURL + path) else {
            return nil
        }
        
        var queryItems = queryParameters?.map { URLQueryItem(name: $0.key, value: $0.value) } ?? []
        queryItems.append(URLQueryItem(name: "apiKey", value: apiKey))
        
        components.queryItems = queryItems
        
        return components.url
    }
    
    func buildRequest(baseURL: String, apiKey: String) -> URLRequest? {
        guard let url = buildURL(baseURL: baseURL, apiKey: apiKey) else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = 30
        
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        return request
    }
}




