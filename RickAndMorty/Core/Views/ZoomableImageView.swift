//
//  ZoomableImageView.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import UIKit
import Photos
import Kingfisher

// MARK: - ZoomableImageView

final class ZoomableImageView: UIView {

    // MARK: - Public Surface

    /// The currently displayed image. Used by the VC to extract data for save actions.
    var currentImage: UIImage? { imageView.image }

    // MARK: - Private

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.minimumZoomScale = 1.0
        sv.maximumZoomScale = 4.0
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator = false
        sv.contentInsetAdjustmentBehavior = .never
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.accessibilityIdentifier = "photo_detail_image"
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private var imageRequestID: PHImageRequestID?
    private var localImageTask: Task<Void, Never>?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit {
        if let id = imageRequestID {
            PHImageManager.default().cancelImageRequest(id)
        }
        localImageTask?.cancel()
    }

    // MARK: - Public API

    func configure(source: PhotoImageSource) {
        imageView.kf.cancelDownloadTask()
        localImageTask?.cancel()
        localImageTask = nil
        if let id = imageRequestID {
            PHImageManager.default().cancelImageRequest(id)
            imageRequestID = nil
        }
        imageView.image = nil
        scrollView.setZoomScale(1.0, animated: false)
        switch source {
        case .remote(let url):
            imageView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
        case .local(let identifier):
            loadLocalImage(identifier: identifier)
        }
    }

    // MARK: - Setup

    private func setupUI() {
        scrollView.delegate = self

        addSubview(scrollView)
        scrollView.addSubview(imageView)

        let contentGuide = scrollView.contentLayoutGuide
        let frameGuide = scrollView.frameLayoutGuide

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            imageView.topAnchor.constraint(equalTo: contentGuide.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentGuide.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: frameGuide.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: frameGuide.heightAnchor)
        ])

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.accessibilityLabel = "photo_detail_double_tap_zoom"
        scrollView.addGestureRecognizer(doubleTap)
    }

    // MARK: - Local Image Loading

    private func loadLocalImage(identifier: String) {
        localImageTask = Task {
            let asset = await Task.detached(priority: .userInitiated) {
                PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject
            }.value
            guard !Task.isCancelled, let asset else { return }

            await MainActor.run { [weak self] in
                guard !Task.isCancelled, let self else { return }

                let options = PHImageRequestOptions()
                options.deliveryMode = .highQualityFormat
                options.isNetworkAccessAllowed = true

                var capturedID: PHImageRequestID?
                let requestID = PHImageManager.default().requestImage(
                    for: asset,
                    targetSize: PHImageManagerMaximumSize,
                    contentMode: .aspectFit,
                    options: options
                ) { [weak self] image, info in
                    if let cancelled = info?[PHImageCancelledKey] as? Bool, cancelled { return }
                    guard let image else { return }
                    Task { @MainActor [weak self] in
                        guard let self, self.imageRequestID == capturedID else { return }
                        self.imageView.image = image
                        self.imageRequestID = nil
                    }
                }
                capturedID = requestID
                self.imageRequestID = requestID
            }
        }
    }

    // MARK: - Zoom Actions

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            let location = gesture.location(in: imageView)
            scrollView.zoom(to: zoomRect(for: scrollView.maximumZoomScale, center: location), animated: true)
        }
    }

    private func zoomRect(for scale: CGFloat, center: CGPoint) -> CGRect {
        let size = CGSize(
            width: scrollView.frame.width / scale,
            height: scrollView.frame.height / scale
        )
        let origin = CGPoint(
            x: center.x - size.width / 2,
            y: center.y - size.height / 2
        )
        return CGRect(origin: origin, size: size)
    }
}

// MARK: - UIScrollViewDelegate

extension ZoomableImageView: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = max((scrollView.frame.width - scrollView.contentSize.width) / 2, 0)
        let offsetY = max((scrollView.frame.height - scrollView.contentSize.height) / 2, 0)
        scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: 0, right: 0)
    }
}
