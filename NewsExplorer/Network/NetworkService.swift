//
//  NetworkService.swift
//  NewsExplorer
//
//  Created by Aagontuk on 12/31/25.
//

import Foundation
import RxSwift

// MARK: - Network Service Protocol

protocol NetworkServiceProtocol {
    func request<T: Decodable>(_ endpoint: APIEndpointProtocol) -> Observable<T>
    func request(_ endpoint: APIEndpointProtocol) -> Observable<Data>
}

// MARK: - Network Service Implementation

final class NetworkService: NetworkServiceProtocol {
    
    // MARK: - Properties
    
    private let session: URLSession
    private let configuration: AppConfiguration
    private let decoder: JSONDecoder
    
    // MARK: - Initialization
    
    init(
        session: URLSession = .shared,
        configuration: AppConfiguration = .shared
    ) {
        self.session = session
        self.configuration = configuration
        self.decoder = JSONDecoder()
    }
    
    // MARK: - Public Methods
    
    func request<T: Decodable>(_ endpoint: APIEndpointProtocol) -> Observable<T> {
        return request(endpoint)
            .map { [weak self] data -> T in
                guard let self = self else {
                    throw NetworkError.unknown("Service deallocated")
                }
                
                do {
                    let decoded = try self.decoder.decode(T.self, from: data)
                    return decoded
                } catch let decodingError {
                    self.logError("Decoding error: \(decodingError)")
                    throw NetworkError.decodingError(decodingError.localizedDescription)
                }
            }
    }
    
    func request(_ endpoint: APIEndpointProtocol) -> Observable<Data> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onError(NetworkError.unknown("Service deallocated"))
                return Disposables.create()
            }
            
            guard let request = endpoint.buildRequest(
                baseURL: self.configuration.baseURL,
                apiKey: self.configuration.apiKey
            ) else {
                observer.onError(NetworkError.invalidURL)
                return Disposables.create()
            }
            
            self.log("Request: \(request.url?.absoluteString ?? "nil")")
            
            let task = self.session.dataTask(with: request) { [weak self] data, response, error in
                if let error = error {
                    let nsError = error as NSError
                    if nsError.code == NSURLErrorNotConnectedToInternet {
                        observer.onError(NetworkError.networkUnavailable)
                    } else if nsError.code == NSURLErrorTimedOut {
                        observer.onError(NetworkError.timeout)
                    } else {
                        observer.onError(NetworkError.unknown(error.localizedDescription))
                    }
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    observer.onError(NetworkError.unknown("Invalid response"))
                    return
                }
                
                self?.log("Response status: \(httpResponse.statusCode)")
                
                guard let data = data else {
                    observer.onError(NetworkError.noData)
                    return
                }
                
                // Handle HTTP status codes
                switch httpResponse.statusCode {
                case 200..<300:
                    observer.onNext(data)
                    observer.onCompleted()
                    
                case 401:
                    observer.onError(NetworkError.unauthorized)
                    
                case 429:
                    observer.onError(NetworkError.rateLimited)
                    
                default:
                    // Try to parse error message from response
                    let errorMessage = self?.parseErrorMessage(from: data) ?? "Unknown error"
                    observer.onError(NetworkError.fromStatusCode(httpResponse.statusCode, message: errorMessage))
                }
            }
            
            task.resume()
            
            return Disposables.create {
                task.cancel()
            }
        }
        .observe(on: MainScheduler.instance)
    }
    
    // MARK: - Private Methods
    
    private func parseErrorMessage(from data: Data) -> String? {
        do {
            let errorResponse = try decoder.decode(APIErrorResponse.self, from: data)
            return errorResponse.message
        } catch {
            return String(data: data, encoding: .utf8)
        }
    }
    
    private func log(_ message: String) {
        if configuration.isLoggingEnabled {
            print("[NetworkService] \(message)")
        }
    }
    
    private func logError(_ message: String) {
        if configuration.isLoggingEnabled {
            print("[NetworkService] \(message)")
        }
    }
}




