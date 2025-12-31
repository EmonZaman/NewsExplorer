//
//  NewsRepositoryProtocol.swift
//  NewsExplorer
//
//  Created by Aagontuk on 12/31/25.
//

import Foundation
import RxSwift

// MARK: - News Repository Protocol

protocol NewsRepositoryProtocol {
    
    func fetchNews(
        query: String,
        from: String?,
        sortBy: String?,
        page: Int?,
        pageSize: Int?
    ) -> Observable<NewsResponse>
    
   
    func fetchTopHeadlines(
        country: String?,
        category: String?,
        page: Int?,
        pageSize: Int?
    ) -> Observable<NewsResponse>
}

// MARK: - Default Parameters Extension

extension NewsRepositoryProtocol {
    
    func fetchNews(
        query: String,
        from: String? = nil,
        sortBy: String? = "publishedAt",
        page: Int? = 1,
        pageSize: Int? = 20
    ) -> Observable<NewsResponse> {
        return fetchNews(
            query: query,
            from: from,
            sortBy: sortBy,
            page: page,
            pageSize: pageSize
        )
    }
    
    func fetchTopHeadlines(
        country: String? = "us",
        category: String? = nil,
        page: Int? = 1,
        pageSize: Int? = 20
    ) -> Observable<NewsResponse> {
        return fetchTopHeadlines(
            country: country,
            category: category,
            page: page,
            pageSize: pageSize
        )
    }
}


