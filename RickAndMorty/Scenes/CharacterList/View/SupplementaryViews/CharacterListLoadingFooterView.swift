//
//  CharacterListLoadingFooterView.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 18.03.2026
//

import UIKit

// MARK: - CharacterListLoadingFooterView

final class CharacterListLoadingFooterView: UICollectionReusableView {

    // MARK: - Callback

    var onRetry: (() -> Void)?

    // MARK: - UI

    private let spinner: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private lazy var retryButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = L10n.LoadingFooter.retryButton
        config.image = Images.refresh
        config.imagePadding = 6
        config.baseForegroundColor = .systemBlue
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = "loading_footer_retry_button"
        button.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(spinner)
        addSubview(retryButton)

        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor),

            retryButton.centerXAnchor.constraint(equalTo: centerXAnchor),
            retryButton.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        onRetry = nil
    }

    // MARK: - Configure

    func configure(state: PaginationState) {
        switch state {
        case .idle:
            spinner.stopAnimating()
            retryButton.isHidden = true
        case .loading:
            spinner.startAnimating()
            retryButton.isHidden = true
        case .error:
            spinner.stopAnimating()
            retryButton.isHidden = false
        }
    }

    // MARK: - Actions

    @objc private func retryTapped() {
        onRetry?()
    }
}

// MARK: - ReuseIdentifiable

extension CharacterListLoadingFooterView: ReuseIdentifiable {}
