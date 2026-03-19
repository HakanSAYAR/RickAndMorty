//
//  L10n.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 17.03.2026.
//

// MARK: - L10n
// Type-safe wrappers over localized string keys; nonisolated for cross-context access.
nonisolated enum L10n {

    // MARK: CharacterList

    nonisolated enum CharacterList {
        static let title             = "character_list.title".localized
        static let gallerySection    = "character_list.gallery_section".localized
        static let charactersSection = "character_list.characters_section".localized
        static let errorAlertTitle   = "character_list.error_alert_title".localized
        static let errorAlertButton  = "character_list.error_alert_button".localized
        static let sortNewestFirst      = "character_list.sort_newest_first".localized
        static let sortOldestFirst      = "character_list.sort_oldest_first".localized
        static let loadErrorRetryButton = "character_list.load_error_retry_button".localized
    }

    // MARK: CharacterDetail

    nonisolated enum CharacterDetail {
        static let rowStatus   = "character_detail.row_status".localized
        static let rowSpecies  = "character_detail.row_species".localized
        static let rowGender   = "character_detail.row_gender".localized
        static let rowOrigin   = "character_detail.row_origin".localized
        static let rowLocation = "character_detail.row_location".localized
    }

    // MARK: PhotoDetail

    nonisolated enum PhotoDetail {
        static let saveSuccessTitle    = "photo_detail.save_success_title".localized
        static let saveSuccessMessage  = "photo_detail.save_success_message".localized
        static let alreadySavedTitle   = "photo_detail.already_saved_title".localized
        static let alreadySavedMessage = "photo_detail.already_saved_message".localized
        static let permissionTitle    = "photo_detail.permission_title".localized
        static let permissionMessage  = "photo_detail.permission_message".localized
        static let errorTitle         = "photo_detail.error_title".localized
        static let okButton           = "photo_detail.ok_button".localized
        static let settingsButton     = "photo_detail.settings_button".localized
    }

    // MARK: Gallery

    nonisolated enum Gallery {
        static let permissionDenied = "gallery.permission_denied".localized
    }

    // MARK: LoadingFooter

    nonisolated enum LoadingFooter {
        static let retryButton = "loading_footer.retry_button".localized
    }

    // MARK: Errors

    nonisolated enum Errors {
        static let noInternetConnection = "errors.no_internet_connection".localized
        static let requestTimedOut      = "errors.request_timed_out".localized
        static let networkError         = "errors.network_error".localized
        static let generic              = "errors.generic".localized
    }
}
