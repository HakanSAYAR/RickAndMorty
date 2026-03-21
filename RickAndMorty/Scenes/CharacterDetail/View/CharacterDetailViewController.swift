//
//  CharacterDetailViewController.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 19.03.2026
//

import UIKit
import Combine

// MARK: - CharacterDetailViewController

final class CharacterDetailViewController: UIViewController {

    // MARK: - Properties

    private let viewModel: any CharacterDetailViewModelProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = false
        sv.showsHorizontalScrollIndicator = false
        return sv
    }()

    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let headerImageView: CharacterDetailHeaderImageView = {
        let view = CharacterDetailHeaderImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let rowsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Init

    init(viewModel: any CharacterDetailViewModelProtocol) {
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
        setupHeaderImageView()
    }

    private func setupView() {
        view.backgroundColor = .systemBackground
    }

    private func setupNavigationBar() {
        title = viewModel.navigationTitle
    }

    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)

        contentStackView.addArrangedSubview(headerImageView)
        contentStackView.addArrangedSubview(rowsStackView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),

            contentStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            headerImageView.heightAnchor.constraint(equalTo: view.widthAnchor)
        ])
    }

    private func setupHeaderImageView() {
        headerImageView.onTap = { [weak self] in
            self?.viewModel.imageTapped()
        }
    }

    // MARK: - Bindings

    private func bindViewModel() {
        viewModel.viewState
            .removeDuplicates()
            .sink { [weak self] state in
                self?.render(state)
            }
            .store(in: &cancellables)
    }

    // MARK: - Render

    private func render(_ state: CharacterDetailState) {
        guard case .loaded(let viewData) = state else { return }

        headerImageView.configure(imageURL: viewData.imageURL)

        rowsStackView.arrangedSubviews.forEach {
            rowsStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        viewData.rows.forEach { row in
            let rowView = CharacterDetailInfoRowView()
            rowView.configure(with: row)
            rowsStackView.addArrangedSubview(rowView)
        }
    }
}
