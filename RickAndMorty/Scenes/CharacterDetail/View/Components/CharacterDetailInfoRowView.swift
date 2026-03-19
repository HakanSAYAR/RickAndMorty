//
//  CharacterDetailInfoRowView.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 19.03.2026
//

import UIKit

// MARK: - CharacterDetailInfoRowView

final class CharacterDetailInfoRowView: UIView {

    // MARK: - Layout

    private enum Layout {
        static let verticalPadding: CGFloat = 16
        static let horizontalPadding: CGFloat = 20
        static let stackSpacing: CGFloat = 12
        static let separatorHeight: CGFloat = 0.5
    }

    // MARK: - UI

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return label
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .label
        label.numberOfLines = 0
        label.textAlignment = .right
        return label
    }()

    private let separator: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Configure

    func configure(with viewData: DetailRowViewData) {
        titleLabel.text = viewData.title
        valueLabel.text = viewData.value
    }

    // MARK: - Setup

    private func setupUI() {
        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .horizontal
        stack.spacing = Layout.stackSpacing
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)
        addSubview(separator)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: Layout.verticalPadding),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.horizontalPadding),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.horizontalPadding),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Layout.verticalPadding),

            separator.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.horizontalPadding),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: Layout.separatorHeight)
        ])
    }
}
