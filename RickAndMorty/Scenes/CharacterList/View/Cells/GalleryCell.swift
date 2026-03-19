//
//  GalleryCell.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 18.03.2026
//

import UIKit
import Photos

// MARK: - GalleryCell

final class GalleryCell: UICollectionViewCell {

    // MARK: - UI

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .secondarySystemBackground
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    // MARK: - Private

    private var requestID: PHImageRequestID?
    private weak var imageManager: PHImageManager?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        if let id = requestID {
            (imageManager ?? .default()).cancelImageRequest(id)
            requestID = nil
        }
        imageManager = nil
        imageView.image = nil
    }

    // MARK: - Configure

    /// - Parameters:
    ///   - viewData: View data carrying the localIdentifier.
    ///   - asset: Pre-resolved PHAsset from PHAssetCache. If nil the cell shows a placeholder.
    ///   - targetSize: Display size in points derived from layout attributes.
    ///     Multiplied by screen scale internally for PHImageManager pixel request.
    ///   - imageManager: Shared PHCachingImageManager injected from the ViewController.
    func configure(
        with viewData: GalleryCellViewData,
        asset: PHAsset?,
        targetSize: CGSize,
        imageManager: PHImageManager,
        optionsFactory: any PHImageRequestOptionsFactoryProtocol
    ) {
        PerformanceSignpost.begin(PerformanceSignpost.Name.cellConfigure, "gallery")
        defer { PerformanceSignpost.end(PerformanceSignpost.Name.cellConfigure) }

        self.imageManager = imageManager
        accessibilityIdentifier = "gallery_cell_\(viewData.localIdentifier)"

        // Cancel any in-flight request and reset before potentially returning early.
        // This guards against stale image/request if configure is called on a
        // visible cell (e.g. DiffableDataSource reconfigure) without a prepareForReuse cycle.
        if let id = requestID {
            imageManager.cancelImageRequest(id)
            requestID = nil
        }
        imageView.image = nil

        guard let asset else { return }

        let scale = UIScreen.main.scale
        let pixelSize = CGSize(width: max(targetSize.width, 1) * scale, height: max(targetSize.height, 1) * scale)
        let options = optionsFactory.makeVisibleOptions()

        PerformanceSignpost.event(PerformanceSignpost.Name.imageRequest, "gallery_request_start")
        var capturedID: PHImageRequestID?
        let id = imageManager.requestImage(
            for: asset,
            targetSize: pixelSize,
            contentMode: .aspectFill,
            options: options
        ) { [weak self] image, info in
            if let cancelled = info?[PHImageCancelledKey] as? Bool, cancelled { return }
            guard let image else { return }
            Task { @MainActor [weak self] in
                guard let self, self.requestID == capturedID else { return }
                self.imageView.image = image
            }
        }
        capturedID = id
        requestID = id
    }

    // MARK: - Layout

    private enum Layout {
        static let cornerRadius: CGFloat = 12
    }

    private func setupUI() {
        contentView.layer.cornerRadius = Layout.cornerRadius
        contentView.clipsToBounds = true
        contentView.backgroundColor = .secondarySystemBackground

        contentView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
}

// MARK: - ReuseIdentifiable

extension GalleryCell: ReuseIdentifiable {}
