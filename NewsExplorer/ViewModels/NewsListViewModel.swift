//
//  NewsListViewModel.swift
//  NewsExplorer
//
//  Created by Aagontuk on 12/31/25.
//


import Foundation
import RxSwift
import RxCocoa

// MARK: - View State

enum ViewState: Equatable {
    case idle
    case loading
    case loaded
    case empty
    case error(String)
}

// MARK: - News List ViewModel Protocol

protocol NewsListViewModelProtocol {
    // Inputs
    var viewDidLoad: PublishRelay<Void> { get }
    var refreshTrigger: PublishRelay<Void> { get }
    var loadMoreTrigger: PublishRelay<Void> { get }
    var articleSelected: PublishRelay<Article> { get }
    var searchQuery: BehaviorRelay<String> { get }
    
    // Outputs
    var articles: Observable<[Article]> { get }
    var viewState: Observable<ViewState> { get }
    var errorMessage: Observable<String> { get }
    var isRefreshing: Observable<Bool> { get }
    var navigateToDetail: Observable<Article> { get }
}

// MARK: - News List ViewModel

final class NewsListViewModel: NewsListViewModelProtocol {
    
    // MARK: - Inputs
    
    let viewDidLoad = PublishRelay<Void>()
    let refreshTrigger = PublishRelay<Void>()
    let loadMoreTrigger = PublishRelay<Void>()
    let articleSelected = PublishRelay<Article>()
    let searchQuery = BehaviorRelay<String>(value: "apple")
    
    // MARK: - Outputs
    
    var articles: Observable<[Article]> {
        return articlesRelay.asObservable()
    }
    
    var viewState: Observable<ViewState> {
        return viewStateRelay.asObservable()
    }
    
    var errorMessage: Observable<String> {
        return errorMessageRelay.asObservable()
    }
    
    var isRefreshing: Observable<Bool> {
        return isRefreshingRelay.asObservable()
    }
    
    var navigateToDetail: Observable<Article> {
        return articleSelected.asObservable()
    }
    
    // MARK: - Private Properties
    
    private let repository: NewsRepositoryProtocol
    private let disposeBag = DisposeBag()
    
    private let articlesRelay = BehaviorRelay<[Article]>(value: [])
    private let viewStateRelay = BehaviorRelay<ViewState>(value: .idle)
    private let errorMessageRelay = PublishRelay<String>()
    private let isRefreshingRelay = BehaviorRelay<Bool>(value: false)
    
    private var currentPage = 1
    private var totalResults = 0
    private var isLoadingMore = false
    private let pageSize = 10
    
    // MARK: - Initialization
    
    init(repository: NewsRepositoryProtocol) {
        self.repository = repository
        setupBindings()
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Initial load - only triggered by viewDidLoad
        viewDidLoad
            .take(1) // Ensure only fires once
            .subscribe(onNext: { [weak self] in
                self?.fetchNews(isRefresh: true)
            })
            .disposed(by: disposeBag)
        
        // Pull to refresh
        refreshTrigger
            .throttle(.seconds(1), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.fetchNews(isRefresh: true)
            })
            .disposed(by: disposeBag)
        
        // Load more (pagination)
        loadMoreTrigger
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.loadMoreNews()
            })
            .disposed(by: disposeBag)
        
        // Search query changes with debounce - skip initial + empty values
        searchQuery
            .skip(1) // Skip initial value
            .debounce(.milliseconds(800), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .filter { !$0.isEmpty } // Don't search for empty strings
            .subscribe(onNext: { [weak self] _ in
                self?.fetchNews(isRefresh: true)
            })
            .disposed(by: disposeBag)
    }
    
    private func fetchNews(isRefresh: Bool) {
        if isRefresh {
            currentPage = 1
            isRefreshingRelay.accept(true)
        }
        
        viewStateRelay.accept(.loading)
        
        let query = searchQuery.value.isEmpty ? "apple" : searchQuery.value
        
        // Calculate from date (last 30 days to avoid API limitations)
        let fromDate = Calendar.current.date(byAdding: .day, value: -30, to: Date())
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let fromDateString = fromDate.map { dateFormatter.string(from: $0) }
        
        repository.fetchNews(
            query: query,
            from: fromDateString,
            sortBy: "publishedAt",
            page: currentPage,
            pageSize: pageSize
        )
        .subscribe(
            onNext: { [weak self] response in
                guard let self = self else { return }
                
                self.totalResults = response.totalResults
                
                // Filter out invalid articles (null titles, empty URLs)
                let validArticles = response.articles.filter { $0.isValid }
                
                if isRefresh {
                    self.articlesRelay.accept(validArticles)
                } else {
                    var currentArticles = self.articlesRelay.value
                    currentArticles.append(contentsOf: validArticles)
                    self.articlesRelay.accept(currentArticles)
                }
                
                if self.articlesRelay.value.isEmpty {
                    self.viewStateRelay.accept(.empty)
                } else {
                    self.viewStateRelay.accept(.loaded)
                }
                
                self.isRefreshingRelay.accept(false)
                self.isLoadingMore = false
            },
            onError: { [weak self] error in
                guard let self = self else { return }
                
                let errorMessage: String
                if let networkError = error as? NetworkError {
                    errorMessage = networkError.localizedDescription
                } else {
                    errorMessage = error.localizedDescription
                }
                
                self.viewStateRelay.accept(.error(errorMessage))
                self.errorMessageRelay.accept(errorMessage)
                self.isRefreshingRelay.accept(false)
                self.isLoadingMore = false
            }
        )
        .disposed(by: disposeBag)
    }
    
    private func loadMoreNews() {
        guard !isLoadingMore else { return }
        
        let currentCount = articlesRelay.value.count
        guard currentCount < totalResults else { return }
        
        isLoadingMore = true
        currentPage += 1
        fetchNews(isRefresh: false)
    }
}
