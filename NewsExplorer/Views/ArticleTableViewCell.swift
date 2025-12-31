//
//  ArticleTableViewCell.swift
//  NewsExplorer
//
//  Created by Aagontuk on 12/31/25.
//


import UIKit
import RxSwift

// MARK: - Article Table View Cell

final class ArticleTableViewCell: UITableViewCell {
    
    // MARK: - Static Properties
    
    static let reuseIdentifier = "ArticleTableViewCell"
    
    // MARK: - UI Components
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        return view
    }()
    
    private let articleImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .tertiarySystemFill
        imageView.image = UIImage(systemName: "photo")
        imageView.tintColor = .tertiaryLabel
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.numberOfLines = 2
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        return label
    }()
    
    private let sourceLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = UIColor(named: "AccentColor") ?? .systemBlue
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 11)
        label.textColor = .tertiaryLabel
        return label
    }()
    
    private let authorLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 11)
        label.textColor = .tertiaryLabel
        return label
    }()
    
    private let metadataStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        return stack
    }()
    
    private let textStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 6
        stack.alignment = .leading
        return stack
    }()
    
    // MARK: - Properties
    
    private var disposeBag = DisposeBag()
    private var currentImageURL: URL?
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func prepareForReuse() {
        super.prepareForReuse()
        articleImageView.image = UIImage(systemName: "photo")
        articleImageView.tintColor = .tertiaryLabel
        titleLabel.text = nil
        descriptionLabel.text = nil
        sourceLabel.text = nil
        dateLabel.text = nil
        authorLabel.text = nil
        disposeBag = DisposeBag()
        
        if let url = currentImageURL {
            ImageLoader.shared.cancelLoad(for: url)
        }
        currentImageURL = nil
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.addSubview(articleImageView)
        containerView.addSubview(textStackView)
        
        // Create separator dot
        let dotLabel = UILabel()
        dotLabel.text = "·"
        dotLabel.font = .systemFont(ofSize: 11)
        dotLabel.textColor = .tertiaryLabel
        
        metadataStackView.addArrangedSubview(sourceLabel)
        metadataStackView.addArrangedSubview(dotLabel)
        metadataStackView.addArrangedSubview(dateLabel)
        
        textStackView.addArrangedSubview(titleLabel)
        textStackView.addArrangedSubview(descriptionLabel)
        textStackView.addArrangedSubview(metadataStackView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            articleImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            articleImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            articleImageView.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -12),
            articleImageView.widthAnchor.constraint(equalToConstant: 100),
            articleImageView.heightAnchor.constraint(equalToConstant: 80),
            
            textStackView.leadingAnchor.constraint(equalTo: articleImageView.trailingAnchor, constant: 12),
            textStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            textStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            textStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with article: Article) {
        titleLabel.text = article.displayTitle
        descriptionLabel.text = article.displayDescription
        sourceLabel.text = article.source.name
        dateLabel.text = article.formattedDate
        
        // Load image
        if let imageURLString = article.urlToImage,
           let imageURL = URL(string: imageURLString) {
            currentImageURL = imageURL
            loadImage(from: imageURL)
        } else {
            articleImageView.image = UIImage(systemName: "photo")
            articleImageView.tintColor = .tertiaryLabel
            articleImageView.contentMode = .scaleAspectFit
        }
    }
    
    private func loadImage(from url: URL) {
        ImageLoader.shared.loadImage(from: url)
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] image in
                guard let self = self,
                      self.currentImageURL == url else { return }
                
                if let image = image {
                    UIView.transition(
                        with: self.articleImageView,
                        duration: 0.2,
                        options: .transitionCrossDissolve,
                        animations: {
                            self.articleImageView.image = image
                            self.articleImageView.contentMode = .scaleAspectFill
                        }
                    )
                }
            })
            .disposed(by: disposeBag)
    }
}

