# Rick & Morty

![Platform](https://img.shields.io/badge/platform-iOS%2015%2B-blue?logo=apple)
![Swift](https://img.shields.io/badge/swift-5.9%2B-orange?logo=swift)
![Build](https://img.shields.io/badge/build-passing-brightgreen?logo=xcode)
![Tests](https://img.shields.io/badge/tests-all%20passing-brightgreen?logo=checkmarx)
![Warnings](https://img.shields.io/badge/warnings-0-brightgreen)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

A production-grade iOS application demonstrating MVVM-C, Clean Architecture, and modern Swift concurrency — built around the public [Rick and Morty API](https://rickandmortyapi.com).

---

## Table of Contents

- [Overview](#overview)
- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [Tech Stack](#tech-stack)
- [Dependencies](#dependencies)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Scenes](#scenes)
- [Build Quality](#build-quality)
- [Testing](#testing)
- [Design Patterns](#design-patterns)
- [Design Decisions](#design-decisions)

---

## Overview

This project serves as a reference implementation for scalable iOS architecture. It combines Clean Architecture's strict layer separation with the MVVM-C pattern for presentation, making every component independently testable and easily replaceable.

The networking layer is extracted into a standalone Swift Package — **NetworkKit** — that encapsulates URL session management, interceptors, retry policies, and logging. The app itself never touches `URLSession` directly.

**App startup sequence:** `AppDelegate` initializes Firebase before any application logic runs → `SceneDelegate` creates `AppDIContainer` (composition root) and `AppCoordinator` → `AppCoordinator.start()` creates `CharacterListCoordinator` → `CharacterListBuilder.make(...)` constructs the scene and the character list appears as the root screen.

---

## Getting Started

### Requirements

- iOS 15.0+ deployment target

### Installation

```bash
git clone <repository-url>
cd RickAndMorty
open RickAndMorty.xcodeproj
```

Swift Package Manager resolves all dependencies automatically on first build. No additional steps needed.

### Run

Select the **RickAndMorty** scheme, choose a simulator or device, and press **⌘R**.

---

## Configuration

The base URL is injected at build time via an Xcode build setting:

```
// Info.plist
BASE_URL = $(BASE_URL)
```

Set `BASE_URL` in the active Xcode configuration (or scheme's environment variables) to point the app at a different backend. `AppConfiguration` validates the value at launch and will assert in debug builds if it is missing or malformed.

### Firebase Setup

Firebase Crashlytics requires a valid `GoogleService-Info.plist` to be present in the project. Obtain this file from the [Firebase Console](https://console.firebase.google.com) for your registered app and place it in the `RickAndMorty/` directory before building. The app will compile without it, but Crashlytics will not report crashes at runtime.

| Build Config | Network Logging |
|---|---|
| Debug | Verbose (full request/response bodies) |
| Release | Standard (status codes and durations only) |

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift |
| UI framework | UIKit |
| Collection layout | UICollectionViewCompositionalLayout |
| Collection data | UICollectionViewDiffableDataSource |
| Reactive | Combine |
| Concurrency | Swift async/await · Structured concurrency |
| Networking | NetworkKit (in-house SPM package) |
| Image loading | Kingfisher |
| Crash reporting | Firebase Crashlytics |
| Photo access | Photos framework (PHPhotoLibrary) |
| Dependency management | Swift Package Manager |
| Testing | Swift Testing (apple/swift-testing) |
| Localization | NSLocalizedString · Localizable.strings (EN + TR) |
| Performance | os_signpost |

---

## Dependencies

### In-House

| Package | Purpose |
|---|---|
| [NetworkKit](NetworkKit/) | Custom-built SPM package that provides the full networking stack — URLSession abstraction, interceptor chain, retry policy, request building, and structured logging |

### Third-Party

| Package | Version | Purpose |
|---|---|---|
| [Kingfisher](https://github.com/onevcat/Kingfisher) | Latest | Async image downloading and caching for character photos |
| [Firebase Crashlytics](https://github.com/firebase/firebase-ios-sdk) | Latest | Real-time crash reporting and diagnostic data collection |

---

## Architecture

### Clean Architecture

The dependency rule is strictly enforced: outer layers depend on inner layers, never the reverse.

- **Domain** — pure Swift, no UIKit or third-party dependencies. Imports only `Foundation` for core value types (`URL`, `Date`). Defines `Character`, `GalleryPhoto`, use case protocols, and repository contracts.
- **Data** — implements domain protocols. Owns DTOs, mappers, and the concrete `CharacterRepositoryImpl` / `GalleryRepositoryImpl`.
- **Presentation** — feature scenes each containing a ViewController, ViewModel, Coordinator, and Builder. No domain types leak directly into views; view-specific data structures (ViewData) carry only what the UI needs.

### MVVM-C

**Coordinator hierarchy:**
```
SceneDelegate
    └── AppDIContainer           ← creates all dependencies once
    └── AppCoordinator           ← root coordinator
            └── CharacterListCoordinator
                    ├── CharacterListBuilder.make(...)
                    │       └── CharacterListScene
                    │               ├── CharacterListViewController  ← UIKit, passive
                    │               └── CharacterListViewModel       ← owns all state
                    │
                    ├── CharacterDetailCoordinator  ← created on character tap
                    │       └── CharacterDetailScene
                    │               ├── CharacterDetailViewController
                    │               └── CharacterDetailViewModel
                    │
                    └── PhotoDetailCoordinator      ← created on image tap
                            └── PhotoDetailScene
                                    ├── PhotoDetailViewController
                                    └── PhotoDetailViewModel
```

**Data flow within a scene:**
```
User Interaction
      │
      ▼
ViewController.send(Action)          ← e.g. .selectCharacter(id:), .loadNextPage
      │
      ▼
ViewModel.send(_ action:)            ← dispatches to private handler, updates internal state
      │
      ├──▶ _state = .loaded(...)     ─▶ ViewController renders UI
      ├──▶ _events.send(.showError)  ─▶ ViewController shows alert
      └──▶ _route.send(.showDetail)  ─▶ Coordinator pushes next screen
```

**Key contracts:**
- `CharacterListAction` — all inputs from the ViewController (`.viewDidLoad`, `.refresh`, `.loadNextPage`, `.retryLoad`, `.retryPagination`, `.reloadGallery`, `.sort`, `.selectCharacter(id:)`, `.selectGalleryPhoto(localIdentifier:)`)
- `CharacterListState` — `.loading` / `.loaded(CharacterListLoadedData)` / `.error(message:)`
- `CharacterListEvent` — transient one-shot events (`.showError(String)`)
- `CharacterListRoute` — navigation triggers (`.showCharacterDetail(Character)`, `.showPhotoDetail(localIdentifier:)`)

ViewControllers never call ViewModel methods that return values — all communication flows through `send(_ action:)` and Combine subscriptions. Coordinators subscribe to the route publisher; they are the only objects that call `navigationController.pushViewController`.

### NetworkKit

An in-house Swift Package built from scratch, with its own independent test target. The application never touches `URLSession` directly — all network communication flows through `NetworkKit`'s protocol-backed abstractions.

```
NetworkKit/
├── Core/           — HTTPMethod, Endpoint protocol, NetworkConfiguration
├── Client/         — URLSessionNetworkClient (URLSessionProtocol wrapper)
├── Interceptors/   — Auth, Retry interceptor chain
├── Request/        — URLRequest builder
├── Decoding/       — JSONDecoder wrappers with typed error mapping
├── DI/             — NetworkFactory (composition root for the package)
├── Logging/        — Structured request/response logging
└── Services/       — APIService abstraction
```

**Key design points:**

- `URLSession` is hidden behind `URLSessionProtocol`, making the client fully testable without hitting the network. Tests inject `MockURLSession` to simulate any response or error scenario.
- The interceptor chain is assembled in `NetworkFactory` and executed in order on every request and response. Adding a new cross-cutting concern (e.g. analytics, rate limiting) means adding one `Interceptor` conformance — no existing code changes.
- `AuthInterceptor` handles token attachment and 401 recovery via `AuthenticationInterceptor` protocol. `RetryPolicy` re-enqueues failed requests up to a configurable limit before surfacing the error.
- All public types are protocol-backed, so the app layer depends only on abstractions (`APIServiceProtocol`, `NetworkClientProtocol`) — never on concrete implementations.

---

## Project Structure

```
RickAndMorty/
├── App/
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift
│   ├── AppCoordinator.swift          — Root coordinator
│   ├── AppDIContainer.swift          — Composition root
│   └── AppConfiguration.swift        — Info.plist reader & validator
│
├── Scenes/
│   ├── CharacterList/
│   │   ├── CharacterListBuilder.swift
│   │   ├── Coordinator/
│   │   ├── ViewModel/
│   │   └── View/
│   ├── CharacterDetail/
│   └── PhotoDetail/
│
├── Domain/
│   ├── Entities/                     — Character, GalleryPhoto, …
│   ├── UseCases/                     — FetchCharactersPageUseCase, SaveImageToGalleryUseCase, …
│   └── Repositories/                 — Protocol definitions only
│
├── Data/
│   ├── Repositories/                 — Concrete implementations
│   ├── DTOs/                         — Codable API models
│   └── Mappers/                      — DTO → Domain entity
│
├── Networking/
│   └── CharacterEndpoint.swift
│
├── Core/
│   ├── Navigation/                   — BaseCoordinator
│   ├── Configuration/
│   ├── Extensions/                   — UIKit & Swift extensions
│   ├── Photos/                       — PHPhotoLibrary integration
│   ├── Views/                        — Reusable UI components
│   ├── Constants/                    — Localization keys, image names
│   └── Performance/                  — os_signpost wrappers
│
└── Resources/
    ├── Assets.xcassets
    └── Localization/
        ├── en.lproj/Localizable.strings
        └── tr.lproj/Localizable.strings

NetworkKit/                           — Standalone Swift Package
RickAndMortyTests/
├── DomainTests/
├── DataTests/
├── CoreTests/
├── SceneTests/
├── AppTests/
└── TestDoubles/                      — Mocks, stubs, fixtures
```

---

## Scenes

### Character List Screen

| Feature | Detail |
|---|---|
| Two-section layout | **Gallery** section first, **Characters** section second — both in the same `UICollectionView` |
| Responsive grid | 2–4 adaptive columns calculated from screen width via `CharacterListLayoutMetrics` |
| Compositional layout | `UICollectionViewCompositionalLayout` with a per-section provider |
| Diffable data source | `UICollectionViewDiffableDataSource` drives all updates — no `reloadData()` calls |
| API pagination | Page number passed as query parameter; next page auto-fetches when scrolling within 4 items of the end |
| Loading spinner | `UIActivityIndicatorView` displayed during initial load and page fetches |
| Pull-to-refresh | `UIRefreshControl` resets pagination and reloads from page 1 |
| Device gallery | Photos fetched from `PHPhotoLibrary` and shown in the Gallery section alongside API characters |
| No duplicates | `GalleryPhoto` uses `localIdentifier` as its stable identity; `NSDiffableDataSourceSnapshot` deduplicates automatically |
| Gallery sort | Toggles between newest-first and oldest-first; sort executes on a background task to keep the UI responsive |
| Character image pipeline | `CharacterListImagePipeline` — Kingfisher downloads and caches API character images asynchronously with prefetching support |
| Gallery image pipeline | `CharacterListGalleryPipeline` — `PHCachingImageManager` fetches device photo thumbnails at display size; caching is prewarmed as cells scroll into view |
| Error recovery | Inline error view with a retry action; no full-screen error interruption |

### Character Detail Screen

| Feature | Detail |
|---|---|
| Large character photo | Header image fills the full screen width |
| Tap to zoom | Tapping the header photo navigates to the Photo Detail screen |
| Character name | Displayed as the navigation title |
| Name | Shown in a detail row |
| Status | Shown in a detail row (e.g. Alive, Dead, Unknown) |
| Species | Shown in a detail row |
| Gender | Shown in a detail row |
| Origin | Shown in a detail row |
| Location | Shown in a detail row |

### Photo Detail Screen

| Feature | Detail |
|---|---|
| Full-screen photo | `ZoomableImageView` fills the entire screen with pinch-to-zoom support |
| Modal presentation | Presented full-screen (`modalPresentationStyle = .fullScreen`) rather than pushed onto the navigation stack |
| Navigation title | Set to the character's name when opened from Character Detail; empty when opened from the Gallery section |
| Close button | `xmark` bar button item on the left — taps call `viewModel.closeTapped()`, which emits a `.dismiss` route handled by `PhotoDetailCoordinator` |
| Save to gallery | Bar button item downloads the photo and saves it to the device photo library via `SaveImageToGalleryUseCase` |

---

## Build Quality

### Crash Reporting

The application integrates **Firebase Crashlytics** for real-time crash monitoring. Any unhandled exception or fatal error is automatically captured and reported with a full stack trace, device context, and OS version — making post-release diagnosis fast and precise without requiring a user-reported bug.

Crashlytics is initialised at app launch in `AppDelegate` before any application logic runs, ensuring no crash goes unrecorded from the first frame.

### Zero-Warning Policy

The project compiles with **zero warnings** under the default Xcode configuration. Compiler warnings are symptoms of real problems — implicit type coercions, unused variables, deprecated APIs, unreachable code. Allowing them to accumulate normalizes noise and makes newly introduced warnings invisible. A zero-warning baseline ensures every new warning is visible and addressed immediately.

### All Tests Passing

The full test suite passes clean across all layers with no skipped, expected-failure, or disabled tests. See the [Testing](#testing) section for details.

```
Test Suite: RickAndMortyTests
├── DomainTests       ✓  all passed
├── DataTests         ✓  all passed
├── CoreTests         ✓  all passed
├── SceneTests        ✓  all passed
└── AppTests          ✓  all passed
```

Tests are written with Apple's Swift Testing framework and cover unit and integration scenarios. Test doubles (mocks, stubs, fixtures) live in a dedicated `TestDoubles/` group so they are never compiled into the production target.

### Build Configurations

| Configuration | Optimization | Logging | Assertions |
|---|---|---|---|
| Debug | None (`-Onone`) | Verbose | Enabled |
| Release | Whole-module (`-O`) | Standard | Disabled |

---

## Testing

```bash
# Run all tests from the command line
xcodebuild test \
  -scheme RickAndMorty \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Test Organisation

| Suite | What it covers |
|---|---|
| `DomainTests` | Entity invariants, use case logic |
| `DataTests` | Repository implementations, DTO mappers |
| `CoreTests` | Photo library service, permission handling, caches |
| `SceneTests` | ViewModels (state transitions), Coordinators, ViewData mappers |
| `AppTests` | DI container wiring, app initialisation |
| `TestDoubles` | Shared mocks, stubs, and fixture factories |

### Testing Philosophy

- Every test creates its subject via a `makeSUT(…)` factory — no global setup/teardown.
- Dependencies are always injected via protocols; no concrete types cross test boundaries.
- Async tests yield with `for _ in 0..<N { await Task.yield() }` rather than arbitrary sleeps, giving the Swift concurrency runtime enough scheduling cycles for async work to complete deterministically.
- `@MainActor` decorates tests that assert on main-thread UI state.
- The real `PHPhotoLibrary` is never called in tests; a stub conforming to `GalleryChangePublishing` drives reactive flows.

---

## Design Patterns

This project applies a deliberate set of design patterns, each chosen to solve a specific structural or behavioural problem. The patterns are not applied for their own sake — each one has a clear boundary, a concrete location in the codebase, and a documented reason for existence.

---

### 1. MVVM (Model — View — ViewModel)

**What it is:** Separates UI rendering (View) from state and business logic orchestration (ViewModel), with the Model representing domain data.

**Where it lives:**
```
Scenes/CharacterList/ViewModel/CharacterListViewModel.swift
Scenes/CharacterDetail/ViewModel/CharacterDetailViewModel.swift
Scenes/PhotoDetail/ViewModel/PhotoDetailViewModel.swift
```

**How it is applied:**
- ViewModels hold all mutable state as `@Published` private properties.
- They expose state and events exclusively through type-erased `AnyPublisher` — ViewControllers can observe but never mutate ViewModel state directly.
- ViewControllers are passive: they subscribe to publishers and call ViewModel input methods in response to user interaction.
- This boundary makes every ViewModel fully testable without instantiating a single UIKit type.

---

### 2. Coordinator Pattern

**What it is:** Centralises navigation logic in a dedicated object (Coordinator), removing it entirely from ViewControllers.

**Where it lives:**
```
Core/Navigation/BaseCoordinator.swift
Scenes/CharacterList/Coordinator/CharacterListCoordinator.swift
Scenes/CharacterDetail/Coordinator/CharacterDetailCoordinator.swift
Scenes/PhotoDetail/Coordinator/PhotoDetailCoordinator.swift
App/AppCoordinator.swift
```

**How it is applied:**
- `BaseCoordinator` defines the coordinator lifecycle interface and parent–child relationship management.
- A scene never calls `navigationController.push…` or `present(…)` directly. Instead, the ViewModel emits a route event (e.g. `.showCharacterDetail(character)`); the Coordinator observes it and performs the transition — push or modal, depending on the scene.
- Child coordinators are retained by their parent. When a child finishes, it calls its `onFinish` closure, which removes it from the parent's child list — preventing memory leaks automatically.
- `CharacterListCoordinator` implements `UINavigationControllerDelegate` to detect back-button taps. When the user pops the character list via the system back button — a gesture that bypasses any ViewModel route event — the coordinator intercepts `navigationController(_:didShow:animated:)`, identifies the dismissed scene, and tears down the child coordinator cleanly. No ViewController lifecycle hacks required.
- Navigation flow changes (push → modal, add an interstitial screen) require modifying only the Coordinator, leaving all other components untouched.

---

### 3. Repository Pattern

**What it is:** Provides a protocol-based abstraction over data sources, decoupling the domain layer from the specifics of how data is fetched or persisted.

**Where it lives:**
```
Domain/Repositories/CharacterRepository.swift
Domain/Repositories/GalleryRepository.swift
Data/Repositories/CharacterRepositoryImpl.swift
Data/Repositories/GalleryRepositoryImpl.swift
```

**How it is applied:**
- The domain layer defines repository protocols using only domain entity types.
- The data layer provides concrete implementations that communicate with the network or the Photos framework.
- Use cases depend solely on the protocols — they are completely unaware of whether data comes from a REST API, a local cache, or a stub in a test.
- Swapping the data source (e.g. introducing an offline cache) requires no changes above the Data layer.

---

### 4. Builder Pattern

**What it is:** Encapsulates the construction and wiring of a complex object graph in a dedicated builder, keeping the construction logic out of the objects themselves.

**Where it lives:**
```
Scenes/CharacterList/CharacterListBuilder.swift
Scenes/CharacterDetail/CharacterDetailBuilder.swift
Scenes/PhotoDetail/PhotoDetailBuilder.swift
```

**How it is applied:**
- Each scene Builder receives its dependencies through its initialiser (from `AppDIContainer`) and exposes a single `make(...)` method.
- `make(...)` creates the ViewController and ViewModel, wires all dependencies, and returns a typed `Scene` object containing both — never a raw `UIViewController`. The Coordinator unpacks the scene, subscribes to `scene.viewModel.route`, then presents or pushes `scene.viewController` depending on the navigation style of that scene.
- The Coordinator never knows how its ViewController was constructed; the ViewController never knows which concrete dependencies its ViewModel received.

---

### 5. Dependency Injection (Composition Root)

**What it is:** All concrete dependencies are constructed in a single location and injected into consumers through protocols, rather than being created ad hoc or accessed through singletons.

**Where it lives:**
```
App/AppDIContainer.swift
NetworkKit/Sources/NetworkKit/DI/NetworkFactory.swift
```

**How it is applied:**
- `AppDIContainer` is the single composition root for the application. It creates all services (network client, repositories, use cases) once and passes them down through Builders to ViewModels.
- `NetworkFactory` is the equivalent composition root inside NetworkKit, constructing the full interceptor chain, decoder, and `APIService` instance.
- No type in the Domain or Data layer creates its own dependencies. Every dependency is received through an initialiser parameter typed as a protocol.
- This makes the dependency graph explicit, acyclic, and entirely replaceable in tests by substituting protocol conformances with test doubles.

---

### 6. Use Case (Interactor) Pattern

**What it is:** Encapsulates a single, well-defined business operation in its own type, preventing ViewModels from growing into orchestration hubs.

**Where it lives:**
```
Domain/UseCases/FetchCharactersPageUseCase.swift
Domain/UseCases/FetchGalleryPhotosUseCase.swift
Domain/UseCases/SaveImageToGalleryUseCase.swift
```

**How it is applied:**
- Each use case owns exactly one public method (typically `execute(…)`).
- It coordinates one or more repositories, applies domain logic (e.g. pagination math), and returns a domain entity or throws a domain error.
- ViewModels call use cases; they never call repositories directly. This keeps ViewModels as thin coordinators of state rather than data-fetching logic.
- Because use cases are protocol-backed, a ViewModel test can replace the real implementation with a `MockFetchCharactersUseCase` in a single line.

---

### 7. Interceptor Pattern

**What it is:** Composes a chain of handlers around an HTTP request/response cycle, each interceptor having a single responsibility (authentication, retry, logging).

**Where it lives:**
```
NetworkKit/Sources/NetworkKit/Interceptors/AuthInterceptor.swift
NetworkKit/Sources/NetworkKit/Interceptors/AuthenticationInterceptor.swift
NetworkKit/Sources/NetworkKit/Interceptors/RetryPolicy.swift
```

**How it is applied:**
- `NetworkClient` passes every outgoing request through an ordered interceptor chain before dispatch, and every response through the same chain on receipt.
- `AuthInterceptor` appends credentials and handles 401 recovery via `AuthenticationInterceptor` protocol. `RetryPolicy` re-enqueues failed requests up to a configurable limit before surfacing the error.
- Adding a new cross-cutting concern (rate limiting, analytics tagging) means adding one interceptor — no existing code changes.
- The interceptor chain is assembled in `NetworkFactory`, making the composition visible in a single place.

---

### 8. Factory Pattern

**What it is:** Encapsulates object creation logic behind a factory interface, hiding the specifics of how a complex object (or graph) is instantiated.

**Where it lives:**
```
NetworkKit/Sources/NetworkKit/DI/NetworkFactory.swift
```

**How it is applied:**
- `NetworkFactory.make(configuration:logLevel:)` constructs the full network stack — interceptors, `URLSessionNetworkClient`, `URLRequestBuilder`, `JSONResponseDecoder`, and `APIService` — and returns a `NetworkStack` value type that exposes only the `apiService` property to the caller.
- `AppDIContainer` receives `NetworkStack.apiService` typed as `APIServiceProtocol` — the concrete types involved are an implementation detail of the package and never leak into the application layer.

---

### 9. Observer Pattern

**What it is:** Establishes a one-to-many dependency so that when one object changes state, all registered dependents are notified automatically.

**Where it lives:**
```
Core/Photos/GalleryChangeObserverProxy.swift    — PHPhotoLibraryChangeObserver
Scenes/CharacterList/ViewModel/CharacterListViewModel.swift — Combine subscriptions
```

**How it is applied in two forms:**

**System observer:** `GalleryChangeObserverProxy` implements `PHPhotoLibraryChangeObserver` and bridges library change notifications into a Combine `Publisher`. Downstream subscribers receive a new `PHFetchResult` whenever the device photo library mutates.

**Reactive streams:** ViewControllers observe ViewModel state exclusively through Combine publishers. `sink` subscriptions on `state` and `events` eliminate all polling and delegate callbacks from the UI layer. Change notifications are debounced (300 ms) to prevent redundant reload cycles during burst mutations.

---

### 10. Mapper Pattern

**What it is:** Isolates the transformation logic between two data representations in a dedicated mapper type, keeping both the source and target models free of conversion code.

**Where it lives:**
```
Data/Mappers/CharacterDTOMapper.swift
Scenes/CharacterList/ViewModel/CharacterListViewDataMapper.swift
```

**How it is applied at two boundaries:**

**Data → Domain:** `CharacterDTOMapper` transforms `CharacterDTO` (a `Codable` API model) into the `Character` domain entity. DTOs can change shape with API versions without touching domain code.

**Domain → ViewData:** `CharacterListViewDataMapper` converts domain entities into flat `CharacterListViewData` structs that contain only what the cell needs (formatted strings, image URLs). ViewControllers never access domain entities directly, keeping the presentation layer decoupled from business logic changes.

---

### 11. Strategy Pattern

**What it is:** Defines a family of interchangeable algorithms behind a common interface, allowing the algorithm to be selected at runtime.

**Where it lives:**
```
NetworkKit/Sources/NetworkKit/Interceptors/       — Swappable interceptor implementations
Scenes/CharacterList/ViewModel/CharacterListViewModel.swift — Gallery sort strategy
```

**How it is applied:**
- The interceptor chain in NetworkKit is a strategy composition: each `Interceptor` implementation is an interchangeable strategy for pre/post-processing requests. Debug builds use the verbose logging strategy; release builds use the standard one.
- Gallery sort order is a runtime strategy: the ViewModel holds a `GallerySortOrder` value (`.newestFirst` / `.oldestFirst`) and applies the corresponding sort algorithm on a detached background task. Toggling sort order requires no conditional logic in the ViewModel — only the strategy value changes.

---

### 12. State Pattern

**What it is:** Encodes an object's possible states as explicit values, making illegal state transitions unrepresentable and removing boolean flag proliferation.

**Where it lives:**
```
Scenes/CharacterList/ViewModel/CharacterListState.swift
Scenes/CharacterList/ViewModel/CharacterListViewModel.swift
```

**How it is applied:**
- `CharacterListState` is a Swift enum with associated values:
  - `.loading` — spinner visible, list hidden
  - `.loaded(CharacterListLoadedData)` — list populated, pagination enabled
  - `.error(message: String)` — error view visible with retry action
- The ViewModel publishes a single `state: AnyPublisher<CharacterListState, Never>`. The ViewController switches on the emitted value and configures the entire UI accordingly — no boolean flags, no possibility of contradictory state (spinner + error simultaneously).
- Gallery state uses a private internal enum (`InternalGalleryState`) with `.hidden`, `.content([GalleryPhoto])`, and `.permissionDenied` cases, ensuring the permission-denied UI can only appear when the gallery section is active. Being `private` to the ViewModel, it is never observable from outside — the public state output is always `CharacterListState`, keeping the gallery implementation detail fully encapsulated.

---

### Pattern Interaction Map

```
ViewController.send(.selectCharacter(id:))
      │
      ▼
ViewModel.handleSelectCharacter(id:)
      │
      ├── finds Character in internal array
      └── _route.send(.showCharacterDetail(character))
                │
                ▼
      CharacterListCoordinator (Combine sink on route publisher)
                │
                └── creates CharacterDetailCoordinator
                          │
                          └── CharacterDetailBuilder.make(character:)
                                    │
                                    └── pushViewController(scene.viewController)


ViewController.send(.viewDidLoad)
      │
      ▼
ViewModel.makeInitialLoadTask()          ← async Task
      │
      ├── concurrent:
      │     ├── FetchCharactersPageUseCase.execute(page: 1)
      │     │         │
      │     │         └── CharacterRepositoryImpl.fetchPage(1)
      │     │                   │
      │     │                   └── APIService.fetch(CharacterEndpoint.characters(page: 1))
      │     │                             │
      │     │                             └── URLSessionNetworkClient
      │     │                                       │
      │     │                                       ├── Interceptor chain (Auth, Retry)
      │     │                                       └── URLSession.data(for:)
      │     │                                                 │
      │     │                                       CharacterPageDTO → CharacterDTOMapper → CharacterPage
      │     │
      │     └── FetchGalleryPhotosUseCase.execute()
      │               │
      │               └── GalleryRepositoryImpl.fetchPhotos()
      │                         │
      │                         ├── GalleryPermissionService.requestAuthorization()
      │                         └── GalleryAssetService.fetchPhotos()  ← background Task
      │                                   │
      │                                   └── PHAsset.fetchAssets(with: .image, options:)
      │                                             │
      │                                   GalleryPhoto[] (localIdentifier, creationDate)
      │
      └── _state = .loaded(CharacterListLoadedData(...))
                │
                ▼
      ViewController.render(.loaded(data))
                │
                └── CharacterListSnapshotFactory.makeSnapshot(from: data.sections)
                          │
                          └── listDataSource.apply(snapshot, animated:)
                                    │
                                    └── UICollectionView renders cells
```

---

## Design Decisions

### Why NetworkKit as a separate package?

Isolating networking into its own SPM package enforces the boundary between infrastructure and application code at the compiler level. It also makes the package reusable across future targets (widgets, extensions) without copying code.

### Why use cases instead of calling repositories directly from ViewModels?

Use cases keep ViewModels thin and free of orchestration logic. A ViewModel that calls `FetchCharactersPageUseCase` is easier to test than one that coordinates repository calls, error mapping, and pagination math itself.

### Why Coordinators?

Coordinators give each navigation transition an explicit, testable representation. The entire UI is built programmatically — no storyboards, no nibs. Replacing a push with a modal or inserting an A/B test screen requires changing one line in the coordinator, leaving all other components untouched.

### Why NSDiffableDataSourceSnapshot over manual reloading?

Diffable data source eliminates index-path bookkeeping and provides animated, crash-free updates when gallery photos arrive or sort order changes — both of which alter the section layout dynamically.

### Why `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`?

Setting `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` at the build level makes the main actor the implicit isolation domain for every type in the module unless explicitly opted out. This removes the need for repetitive `@MainActor` annotations on every ViewController and ViewModel, and — more importantly — it is a deliberate forward-looking decision: the entire codebase is structured to be compatible with Swift 6 strict concurrency checking from day one. When the project eventually moves to Swift 6 language mode, no architectural changes will be required to satisfy the compiler's data-race safety rules.

### Why `SavedPhotoStore` is a Swift `actor`

The set of saved photo identifiers is shared mutable state accessed concurrently from multiple tasks (gallery load, save operation, deduplication check). Implementing `SavedPhotoStore` as a Swift `actor` gives it built-in data isolation — no serial `DispatchQueue`, no manual locking, and the compiler enforces correct access at every call site automatically. It is the idiomatic Swift 6 solution for protecting shared mutable state.

### Why `@Published` + `AnyPublisher` instead of exposing `@Published` directly?

Erasing to `AnyPublisher` prevents ViewControllers from writing back into ViewModel state. It makes the data flow unidirectional and explicit, which simplifies debugging and avoids accidental coupling.

### Concurrency model

Long-running tasks (sort, gallery load, API fetch) are tracked by reference in the ViewModel and cancelled before a replacement task starts. This prevents stale results from racing and keeps memory usage flat during rapid user interactions.

---

## License

This project is available under the MIT License.
