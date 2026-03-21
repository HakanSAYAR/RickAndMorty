//
//  PhotoDetailViewController.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 19.03.2026
//

import UIKit
import Combine

// MARK: - PhotoDetailViewController

final class PhotoDetailViewController: UIViewController {

    // MARK: - Properties

    private let viewModel: any PhotoDetailViewModelProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI

    private let zoomableImageView: ZoomableImageView = {
        let view = ZoomableImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Init

    init(viewModel: any PhotoDetailViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        viewModel.viewDidLoad()
    }

    // MARK: - UI Setup

    private func setupUI() {
        setupView()
        setupNavigationBar()
        setupLayout()
    }
    
    private func setupView() {
        view.backgroundColor = .black
    }
    
    private func setupNavigationBar() {
        title = viewModel.navigationTitle

        let closeButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(closeButtonTapped)
        )
        navigationItem.leftBarButtonItem = closeButton

        guard viewModel.showDownloadButton else { return }
        let saveButton = UIBarButtonItem(
            image: Images.saveToPhotos,
            style: .plain,
            target: self,
            action: #selector(saveButtonTapped)
        )
        saveButton.accessibilityIdentifier = "photo_detail_save_button"
        navigationItem.rightBarButtonItem = saveButton
    }
    
    private func setupLayout() {
        view.addSubview(zoomableImageView)
        NSLayoutConstraint.activate([
            zoomableImageView.topAnchor.constraint(equalTo: view.topAnchor),
            zoomableImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            zoomableImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            zoomableImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Bindings

    private func bindViewModel() {
        viewModel.viewState
            .sink { [weak self] state in
                self?.render(state)
            }
            .store(in: &cancellables)

        viewModel.events
            .sink { [weak self] event in
                self?.handle(event)
            }
            .store(in: &cancellables)
    }

    // MARK: - Render

    private func render(_ state: PhotoDetailState) {
        guard case .loaded(let viewData) = state else { return }
        zoomableImageView.configure(source: viewData.imageSource)
    }

    // MARK: - Actions

    @objc private func closeButtonTapped() {
        viewModel.closeTapped()
    }

    @objc private func saveButtonTapped() {
        // Capture UIImage on main thread, encode off-main to avoid blocking UI.
        let image = zoomableImageView.currentImage
        Task {
            let data = await Task.detached(priority: .userInitiated) {
                image?.jpegData(compressionQuality: 1.0)
            }.value
            guard !Task.isCancelled else { return }
            await MainActor.run { [weak self] in
                self?.viewModel.saveButtonTapped(imageData: data)
            }
        }
    }

    // MARK: - Event Handling

    private func handle(_ event: PhotoDetailEvent) {
        switch event {
        case .saveSuccess:
            showAlert(
                title: L10n.PhotoDetail.saveSuccessTitle,
                message: L10n.PhotoDetail.saveSuccessMessage,
                buttonTitle: L10n.PhotoDetail.okButton
            )
        case .alreadySaved:
            showAlert(
                title: L10n.PhotoDetail.alreadySavedTitle,
                message: L10n.PhotoDetail.alreadySavedMessage,
                buttonTitle: L10n.PhotoDetail.okButton
            )
        case .permissionDenied:
            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
            showAlert(
                title: L10n.PhotoDetail.permissionTitle,
                message: L10n.PhotoDetail.permissionMessage,
                actions: [
                    UIAlertAction(title: L10n.PhotoDetail.okButton, style: .default),
                    UIAlertAction(title: L10n.PhotoDetail.settingsButton, style: .default) { _ in
                        UIApplication.shared.open(settingsURL)
                    }
                ]
            )
        case .saveError(let message):
            showAlert(
                title: L10n.PhotoDetail.errorTitle,
                message: message,
                buttonTitle: L10n.PhotoDetail.okButton
            )
        }
    }
}
