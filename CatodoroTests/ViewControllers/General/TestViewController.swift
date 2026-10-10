//
//  TestViewController.swift
//  Catodoro
//
//  Created by Suguru Tokuda on 5/13/25.
//

import UIKit

class TestableCollectionViewHost: UIViewController {

    let collectionView: UICollectionView
    var dataSource: UICollectionViewDiffableDataSource<Int, String>!
    var cellProviderCalled = false

    init() {
        // Set up layout
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 100, height: 100)

        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        super.init(nibName: nil, bundle: nil)

        // Register cell
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "Cell")

        // Set up data source
        dataSource = UICollectionViewDiffableDataSource<Int, String>(collectionView: collectionView) { [weak self] collectionView, indexPath, itemIdentifier in
            self?.cellProviderCalled = true
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
            return cell
        }

        collectionView.dataSource = dataSource
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTestSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, String>()
        snapshot.appendSections([0])
        snapshot.appendItems(["Test1", "Test2"])
        dataSource.apply(snapshot, animatingDifferences: false)
        collectionView.layoutIfNeeded()
    }
}
