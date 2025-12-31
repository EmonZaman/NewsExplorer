//
//  NewsRepository.swift
//  NewsExplorer
//
//  Created by Aagontuk on 12/31/25.
//

import Foundation
import RxSwift

// MARK: - News Repository Implementation

final class NewsRepository: NewsRepositoryProtocol {
    
    // MARK: - Properties
    
    private let networkService: NetworkServiceProtocol
    
    // MARK: - Initialization
    
    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }
    
    // MARK: - NewsRepositoryProtocol
    
    func fetchNews(
        query: String,
        from: String?,
        sortBy: String?,
        page: Int?,
        pageSize: Int?
    ) -> Observable<NewsResponse> {
        let endpoint = NewsAPIEndpoint.everything(
            query: query,
            from: from,
            sortBy: sortBy,
            page: page,
            pageSize: pageSize
        )
        
        return networkService.request(endpoint)
            .do(onNext: { response in
                print("[NewsRepository] Fetched \(response.articles.count) articles")
            }, onError: { error in
                print("[NewsRepository] Error: \(error.localizedDescription)")
            })
    }
    
    func fetchTopHeadlines(
        country: String?,
        category: String?,
        page: Int?,
        pageSize: Int?
    ) -> Observable<NewsResponse> {
        let endpoint = NewsAPIEndpoint.topHeadlines(
            country: country,
            category: category,
            page: page,
            pageSize: pageSize
        )
        
        return networkService.request(endpoint)
            .do(onNext: { response in
                print("[NewsRepository] Fetched \(response.articles.count) headlines")
            }, onError: { error in
                print("[NewsRepository] Error: \(error.localizedDescription)")
            })
    }
}




