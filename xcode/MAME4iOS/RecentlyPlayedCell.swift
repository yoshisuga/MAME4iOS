//
//  RecentlyPlayedCell.swift
//  MAME4iOS
//
//  Created by Yoshi Sugawara on 5/29/22.
//  Copyright © 2022 MAME4iOS Team. All rights reserved.
//

import UIKit

@objcMembers class RecentlyPlayedCell: UICollectionViewCell {
    static let identifier = "RecentlyPlayedCell"
    
    var items = [GameInfo]() {
        didSet {
            collectionView.reloadData()
        }
    }
    
    let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        return collectionView
    }()
    
    var itemSize = CGSize.zero {
        didSet {
            guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
                return
            }
            layout.itemSize = itemSize
        }
    }
    var setupCellClosure: ((GameInfoCell, IndexPath) -> Void)?
    var selectItemClosure: ((IndexPath) -> Void)?
    var contextMenuClosure: ((IndexPath) -> UIContextMenuConfiguration?)?
    var heightForGameInfoClosure: ((GameInfo, UICollectionViewLayout) -> CGPoint)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        backgroundColor = .clear
        contentView.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(GameInfoCell.self, forCellWithReuseIdentifier: Self.identifier)
    }
}

extension RecentlyPlayedCell: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Self.identifier, for: indexPath) as? GameInfoCell else {
            return UICollectionViewCell()
        }
        setupCellClosure?(cell, indexPath)
        return cell
    }
}

extension RecentlyPlayedCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectItemClosure?(indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return contextMenuClosure?(indexPath)
    }
}

extension RecentlyPlayedCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout,
              let heightForGameInfoClosure = heightForGameInfoClosure,
              let game = items[safe: indexPath.row] else {
            return .zero
        }        
        let heightInfo = heightForGameInfoClosure(game, layout)
        let height = heightInfo.x + heightInfo.y
        return CGSize(width: layout.itemSize.width, height: height)
    }
}
