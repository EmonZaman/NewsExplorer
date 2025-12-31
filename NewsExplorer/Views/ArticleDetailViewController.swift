//
//  ArticleDetailViewController.swift
//  NewsExplorer
//
//  Created by Aagontuk on 12/31/25.
//


import UIKit
import RxSwift
import RxCocoa
import SafariServices

// MARK: - Article Detail View Controller

final class ArticleDetailViewController: UIViewController {
    
    // MARK: - UI Components
    
    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsVerticalScrollIndicator = true
        scroll.alwaysBounceVertical = true
        return scroll
    }()
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var headerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .tertiarySystemFill
        imageView.image = UIImage(systemName: "photo")
        imageView.tintColor = .tertiaryLabel
        return imageView
    }()
    
    private lazy var sourceLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = UIColor(named: "AccentColor") ?? .systemBlue
        return label
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var authorDateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var separatorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .separator
        return view
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 15)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var readMoreButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Read Full Article", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = UIColor(named: "AccentColor") ?? .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        return button
    }()
    
    private lazy var shareBarButton: UIBarButtonItem = {
        let button = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: nil,
            action: nil
        )
        return button
    }()
    
    // MARK: - Properties
    
    private let viewModel: ArticleDetailViewModelProtocol
    private let disposeBag = DisposeBag()
    
    // MARK: - Initialization
    
    init(viewModel: ArticleDetailViewModelProtocol) {
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
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        contentView.addSubview(headerImageView)
        contentView.addSubview(sourceLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(authorDateLabel)
        contentView.addSubview(separatorView)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(contentLabel)
        contentView.addSubview(readMoreButton)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            headerImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            headerImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            headerImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            headerImageView.heightAnchor.constraint(equalToConstant: 250),
            
            sourceLabel.topAnchor.constraint(equalTo: headerImageView.bottomAnchor, constant: 20),
            sourceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            sourceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            titleLabel.topAnchor.constraint(equalTo: sourceLabel.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            authorDateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            authorDateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            authorDateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            separatorView.topAnchor.constraint(equalTo: authorDateLabel.bottomAnchor, constant: 20),
            separatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            separatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            separatorView.heightAnchor.constraint(equalToConstant: 1),
            
            descriptionLabel.topAnchor.constraint(equalTo: separatorView.bottomAnchor, constant: 20),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            contentLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 16),
            contentLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            contentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            readMoreButton.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 32),
            readMoreButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            readMoreButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            readMoreButton.heightAnchor.constraint(equalToConstant: 50),
            readMoreButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }
    
    private func setupNavigationBar() {
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = shareBarButton
    }
    
    // MARK: - Bindings
    
    private func bindViewModel() {
        // Bind article data
        viewModel.article
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] article in
                self?.configureUI(with: article)
            })
            .disposed(by: disposeBag)
        
        // Read more button action
        readMoreButton.rx.tap
            .bind(to: viewModel.openInBrowserAction)
            .disposed(by: disposeBag)
        
        // Share button action
        shareBarButton.rx.tap
            .bind(to: viewModel.shareAction)
            .disposed(by: disposeBag)
        
        // Handle open in browser (MVVM - navigation handled in ViewController)
        viewModel.openInBrowser
            .subscribe(onNext: { [weak self] url in
                self?.openInSafari(url: url)
            })
            .disposed(by: disposeBag)
        
        // Handle share (MVVM - navigation handled in ViewController)
        viewModel.shareArticle
            .subscribe(onNext: { [weak self] article in
                self?.shareArticle(article)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Configuration
    
    private func configureUI(with article: Article) {
        sourceLabel.text = article.source.name.uppercased()
        titleLabel.text = article.displayTitle
        
        var authorDateText = ""
        if let author = article.author, !author.isEmpty {
            authorDateText = "By \(author)"
        }
        if !article.formattedDate.isEmpty {
            if !authorDateText.isEmpty {
                authorDateText += " • "
            }
            authorDateText += article.formattedDate
        }
        authorDateLabel.text = authorDateText
        
        descriptionLabel.text = article.displayDescription
        
        
        if let content = article.content {
            let cleanContent = content.replacingOccurrences(
                of: "\\[\\+\\d+ chars\\]",
                with: "",
                options: .regularExpression
            )
            contentLabel.text = cleanContent
        } else {
            contentLabel.text = "Read the full article for more details."
        }
        
        // Load image
        if let imageURLString = article.urlToImage,
           let imageURL = URL(string: imageURLString) {
            loadImage(from: imageURL)
        }
    }
    
    private func loadImage(from url: URL) {
        ImageLoader.shared.loadImage(from: url)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] image in
                if let image = image {
                    UIView.transition(
                        with: self?.headerImageView ?? UIImageView(),
                        duration: 0.3,
                        options: .transitionCrossDissolve,
                        animations: {
                            self?.headerImageView.image = image
                            self?.headerImageView.contentMode = .scaleAspectFill
                        }
                    )
                }
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Actions (MVVM - handled directly in ViewController)
    
    private func openInSafari(url: URL) {
        let safariVC = SFSafariViewController(url: url)
        safariVC.preferredControlTintColor = UIColor(named: "AccentColor") ?? .systemBlue
        present(safariVC, animated: true)
    }
    
    private func shareArticle(_ article: Article) {
        var items: [Any] = [article.displayTitle]
        
        if let url = URL(string: article.url) {
            items.append(url)
        }
        
        let activityVC = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        
        // iPad support
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(
                x: UIScreen.main.bounds.midX,
                y: UIScreen.main.bounds.midY,
                width: 0,
                height: 0
            )
            popover.permittedArrowDirections = []
        }
        
        present(activityVC, animated: true)
    }
}
