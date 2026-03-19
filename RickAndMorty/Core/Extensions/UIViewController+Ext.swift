//
//  UIViewController+Ext.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import UIKit

extension UIViewController {

    func showAlert(
        title: String,
        message: String? = nil,
        actions: [UIAlertAction]
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        actions.forEach { alert.addAction($0) }
        present(alert, animated: true)
    }

    func showAlert(
        title: String,
        message: String? = nil,
        buttonTitle: String = "OK",
        action: (() -> Void)? = nil
    ) {
        let alertAction = UIAlertAction(title: buttonTitle, style: .default) { _ in action?() }
        showAlert(title: title, message: message, actions: [alertAction])
    }
}
