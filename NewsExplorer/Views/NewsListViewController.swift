//
//  NewsListViewController.swift
//  NewsExplorer
//
//  Created by Aagontuk on 12/31/25.
//



import UIKit
import RxSwift
import RxCocoa

// MARK: - News List View Controller

final class NewsListViewController: UIViewController {
    
    // MARK: - UI Components
    
    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.register(ArticleTableViewCell.self, forCellReuseIdentifier: ArticleTableViewCell.reuseIdentifier)
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 120
        table.separatorStyle = .singleLine
        table.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        table.backgroundColor = .systemBackground
        return table
    }()
    
    private lazy var refreshControl: UIRefreshControl = {
        let refresh = UIRefreshControl()
        refresh.tintColor = UIColor(named: "AccentColor") ?? .systemBlue
        return refresh
    }()
    
    private lazy var searchController: UISearchController = {
        let search = UISearchController(searchResultsController: nil)
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = "Search news..."
        search.searchBar.tintColor = UIColor(named: "AccentColor") ?? .systemBlue
        return search
    }()
    
    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        indicator.color = UIColor(named: "AccentColor") ?? .systemBlue
        return indicator
    }()
    
    private lazy var emptyStateView: EmptyStateView = {
        let view = EmptyStateView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    private lazy var errorView: ErrorStateView = {
        let view = ErrorStateView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    // MARK: - Properties
    
    private let viewModel: NewsListViewModelProtocol
    private let disposeBag = DisposeBag()
    
    // MARK: - Initialization
    
    init(viewModel: NewsListViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        bindViewModel()
        viewModel.viewDidLoad.accept(())
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(tableView)
        view.addSubview(loadingIndicator)
        view.addSubview(emptyStateView)
        view.addSubview(errorView)
        
        tableView.refreshControl = refreshControl
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            errorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            errorView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }
    
    private func setupNavigationBar() {
        title = "News Explorer"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }
    
    // MARK: - Bindings
    
    private func bindViewModel() {
        // Bind articles to table view
        viewModel.articles
            .bind(to: tableView.rx.items(
                cellIdentifier: ArticleTableViewCell.reuseIdentifier,
                cellType: ArticleTableViewCell.self
            )) { _, article, cell in
                cell.configure(with: article)
            }
            .disposed(by: disposeBag)
        
        // Handle article selection
        tableView.rx.modelSelected(Article.self)
            .bind(to: viewModel.articleSelected)
            .disposed(by: disposeBag)
        
        // Deselect row after selection
        tableView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                self?.tableView.deselectRow(at: indexPath, animated: true)
            })
            .disposed(by: disposeBag)
        
        // Navigate to detail (MVVM - navigation handled in ViewController)
        viewModel.navigateToDetail
            .subscribe(onNext: { [weak self] article in
                self?.navigateToArticleDetail(article)
            })
            .disposed(by: disposeBag)
        
        // Pull to refresh
        refreshControl.rx.controlEvent(.valueChanged)
            .bind(to: viewModel.refreshTrigger)
            .disposed(by: disposeBag)
        
        // Stop refresh control
        viewModel.isRefreshing
            .bind(to: refreshControl.rx.isRefreshing)
            .disposed(by: disposeBag)
        
        // Search query binding
        searchController.searchBar.rx.text
            .orEmpty
            .bind(to: viewModel.searchQuery)
            .disposed(by: disposeBag)
        
        // View state handling
        viewModel.viewState
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] state in
                self?.handleViewState(state)
            })
            .disposed(by: disposeBag)
        
        // Load more when scrolling near bottom
        tableView.rx.contentOffset
            .filter { [weak self] offset in
                guard let self = self else { return false }
                let contentHeight = self.tableView.contentSize.height
                let tableHeight = self.tableView.frame.height
                let threshold: CGFloat = 200
                return offset.y > contentHeight - tableHeight - threshold && contentHeight > 0
            }
            .throttle(.milliseconds(500), scheduler: MainScheduler.instance)
            .map { _ in () }
            .bind(to: viewModel.loadMoreTrigger)
            .disposed(by: disposeBag)
        
        // Error retry
        errorView.retryButton.rx.tap
            .bind(to: viewModel.refreshTrigger)
            .disposed(by: disposeBag)
    }
    
    // MARK: - Navigation (MVVM - handled directly in ViewController)
    
    private func navigateToArticleDetail(_ article: Article) {
//        let detailViewModel = ArticleDetailViewModel(article: article)
//        let detailVC = ArticleDetailViewController(viewModel: detailViewModel)
//        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    // MARK: - State Handling
    
    private func handleViewState(_ state: ViewState) {
        switch state {
        case .idle:
            loadingIndicator.stopAnimating()
            emptyStateView.isHidden = true
            errorView.isHidden = true
            tableView.isHidden = false
            
        case .loading:
            if viewModel.searchQuery.value.isEmpty || tableView.numberOfRows(inSection: 0) == 0 {
                loadingIndicator.startAnimating()
            }
            emptyStateView.isHidden = true
            errorView.isHidden = true
            
        case .loaded:
            loadingIndicator.stopAnimating()
            emptyStateView.isHidden = true
            errorView.isHidden = true
            tableView.isHidden = false
            
        case .empty:
            loadingIndicator.stopAnimating()
            emptyStateView.isHidden = false
            errorView.isHidden = true
            tableView.isHidden = true
            
        case .error(let message):
            loadingIndicator.stopAnimating()
            emptyStateView.isHidden = true
            errorView.isHidden = false
            errorView.configure(with: message)
            tableView.isHidden = tableView.numberOfRows(inSection: 0) == 0
        }
    }
}

// MARK: - Empty State View

final class EmptyStateView: UIView {
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "newspaper")
        imageView.tintColor = .secondaryLabel
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "No Articles Found"
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Try adjusting your search to find what you're looking for."
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(imageView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 80),
            imageView.heightAnchor.constraint(equalToConstant: 80),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

// MARK: - Error State View

final class ErrorStateView: UIView {
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "exclamationmark.triangle")
        imageView.tintColor = .systemRed
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Something Went Wrong"
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    let retryButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Try Again", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = UIColor(named: "AccentColor") ?? .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(imageView)
        addSubview(titleLabel)
        addSubview(messageLabel)
        addSubview(retryButton)
        
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 60),
            imageView.heightAnchor.constraint(equalToConstant: 60),
            
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            
            retryButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 24),
            retryButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            retryButton.widthAnchor.constraint(equalToConstant: 140),
            retryButton.heightAnchor.constraint(equalToConstant: 44),
            retryButton.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func configure(with message: String) {
        messageLabel.text = message
    }
}

