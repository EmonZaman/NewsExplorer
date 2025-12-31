//
//  ArticleDetailViewModel.swift
//  NewsExplorer
//
//  Created by Aagontuk on 12/31/25.
//


import Foundation
import RxSwift
import RxCocoa

// MARK: - Article Detail ViewModel Protocol

protocol ArticleDetailViewModelProtocol {
    // Inputs
    var openInBrowserAction: PublishRelay<Void> { get }
    var shareAction: PublishRelay<Void> { get }
    
    // Outputs
    var article: Observable<Article> { get }
    var openInBrowser: Observable<URL> { get }
    var shareArticle: Observable<Article> { get }
}

// MARK: - Article Detail ViewModel

final class ArticleDetailViewModel: ArticleDetailViewModelProtocol {
    
    // MARK: - Inputs
    
    let openInBrowserAction = PublishRelay<Void>()
    let shareAction = PublishRelay<Void>()
    
    // MARK: - Outputs
    
    var article: Observable<Article> {
        return articleRelay.asObservable()
    }
    
    var openInBrowser: Observable<URL> {
        return openInBrowserSubject.asObservable()
    }
    
    var shareArticle: Observable<Article> {
        return shareSubject.asObservable()
    }
    
    // MARK: - Private Properties
    
    private let articleRelay: BehaviorRelay<Article>
    private let openInBrowserSubject = PublishSubject<URL>()
    private let shareSubject = PublishSubject<Article>()
    private let disposeBag = DisposeBag()
    
    // MARK: - Initialization
    
    init(article: Article) {
        self.articleRelay = BehaviorRelay(value: article)
        setupBindings()
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        openInBrowserAction
            .withLatestFrom(articleRelay)
            .compactMap { URL(string: $0.url) }
            .bind(to: openInBrowserSubject)
            .disposed(by: disposeBag)
        
        shareAction
            .withLatestFrom(articleRelay)
            .bind(to: shareSubject)
            .disposed(by: disposeBag)
    }
}
