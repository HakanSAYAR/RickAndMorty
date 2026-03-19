//
//  UICollectionView+Identifiable.swift
//  RickAndMorty
//
//  Created by Hakan SAYAR on 17.03.2026.
//

import UIKit

protocol ReuseIdentifiable {
    static var reuseIdentifier: String { get }
}

extension ReuseIdentifiable {
    static var reuseIdentifier: String { String(describing: Self.self) }
}

extension UICollectionView {

    func dequeueCell<T: UICollectionViewCell & ReuseIdentifiable>(
        _ type: T.Type = T.self,
        for indexPath: IndexPath
    ) -> T {
        guard let cell = dequeueReusableCell(withReuseIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
            fatalError("Could not dequeue cell of type \(T.self)")
        }
        return cell
    }

    func dequeueSupplementary<T: UICollectionReusableView & ReuseIdentifiable>(
        ofKind kind: String,
        _ type: T.Type = T.self,
        for indexPath: IndexPath
    ) -> T {
        guard let view = dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
            fatalError("Could not dequeue supplementary view of type \(T.self)")
        }
        return view
    }
}
