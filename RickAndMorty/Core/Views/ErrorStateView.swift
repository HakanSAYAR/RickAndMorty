//
//  ErrorStateView.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import UIKit

// MARK: - ErrorStateView
//
// Shared full-screen error view

final class ErrorStateView: UIView {

    // MARK: - Callbacks

    var onRetry: (() -> Void)?

    // MARK: - UI

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let retryButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        setupLayout()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Configure

    func configure(message: String, retryTitle: String) {
        messageLabel.text = message
        var config = retryButton.configuration ?? .filled()
        config.title = retryTitle
        retryButton.configuration = config
    }

    // MARK: - Private

    private func setupLayout() {
        let stack = UIStackView(
            axis: .vertical,
            spacing: 16,
            alignment: .center,
            arrangedSubviews: [messageLabel, retryButton]
        )

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -32)
        ])
    }

    @objc private func retryTapped() {
        onRetry?()
    }
}
