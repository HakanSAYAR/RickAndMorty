//
//  CharacterDetailHeaderImageView.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 19.03.2026
//

import UIKit
import Kingfisher

// MARK: - CharacterDetailHeaderImageView

final class CharacterDetailHeaderImageView: UIView {

    // MARK: - Callback

    var onTap: (() -> Void)?

    // MARK: - UI

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .secondarySystemBackground
        iv.accessibilityIdentifier = "character_detail_image"
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Configure

    func configure(imageURL: URL?) {
        imageView.kf.setImage(
            with: imageURL,
            options: [.transition(.fade(0.2))]
        )
    }

    // MARK: - Setup

    private func setupUI() {
        isUserInteractionEnabled = true
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapFired))
        addGestureRecognizer(tap)
    }

    // MARK: - Actions

    @objc private func tapFired() {
        onTap?()
    }
}
