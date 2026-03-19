//
//  CharacterCell.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 18.03.2026
//

import UIKit
import Kingfisher

// MARK: - CharacterCell

final class CharacterCell: UICollectionViewCell {

    // MARK: - UI

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .secondarySystemBackground
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Layout.labelFontSize, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Layout.statusFontSize, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
        nameLabel.text = nil
        statusLabel.text = nil
    }

    // MARK: - Configure

    /// - Parameters:
    ///   - targetSize: Display size in points derived from layout attributes.
    ///     Must match the size used by `ImagePrefetcher` to guarantee a Kingfisher cache hit.
    func configure(with viewData: CharacterCellViewData, targetSize: CGSize, pipeline: any CharacterListImagePipelineProtocol) {
        PerformanceSignpost.begin(PerformanceSignpost.Name.cellConfigure, "character")
        defer { PerformanceSignpost.end(PerformanceSignpost.Name.cellConfigure) }

        nameLabel.text = viewData.title
        statusLabel.text = viewData.subtitle
        accessibilityIdentifier = "character_cell_\(viewData.id)"

        imageView.kf.indicatorType = .activity
        imageView.kf.setImage(with: viewData.imageURL, options: pipeline.options(targetSize: targetSize))
    }

    // MARK: - Layout

    private enum Layout {
        static let cornerRadius: CGFloat = 12
        static let labelFontSize: CGFloat = 12
        static let statusFontSize: CGFloat = 10
        static let labelSpacing: CGFloat = 2
        static let contentPadding: CGFloat = 6
    }

    private func setupUI() {
        contentView.layer.cornerRadius = Layout.cornerRadius
        contentView.clipsToBounds = true
        contentView.backgroundColor = .secondarySystemBackground

        let stack = UIStackView(arrangedSubviews: [nameLabel, statusLabel])
        stack.axis = .vertical
        stack.spacing = Layout.labelSpacing
        stack.alignment = .center
        stack.distribution = .equalSpacing

        stack.translatesAutoresizingMaskIntoConstraints = false

        let labelAreaGuide = UILayoutGuide()
        contentView.addLayoutGuide(labelAreaGuide)

        contentView.addSubview(imageView)
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: contentView.widthAnchor),

            labelAreaGuide.topAnchor.constraint(equalTo: imageView.bottomAnchor),
            labelAreaGuide.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            labelAreaGuide.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            labelAreaGuide.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            stack.centerXAnchor.constraint(equalTo: labelAreaGuide.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: labelAreaGuide.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Layout.contentPadding),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Layout.contentPadding),
            stack.topAnchor.constraint(greaterThanOrEqualTo: labelAreaGuide.topAnchor, constant: Layout.contentPadding),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: labelAreaGuide.bottomAnchor, constant: -Layout.contentPadding)
        ])
    }
}

// MARK: - ReuseIdentifiable

extension CharacterCell: ReuseIdentifiable {}
