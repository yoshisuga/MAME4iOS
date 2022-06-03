//
//  ChooseGameController+Prefetching.swift
//  MAME4iOS
//
//  Created by Yoshi Sugawara on 5/31/22.
//  Copyright © 2022 MAME4iOS Team. All rights reserved.
//

extension ChooseGameController: UICollectionViewDataSourcePrefetching {
    public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        print("ChooseGameController: Start prefetch of images for indexPaths: \(indexPaths)")
        for indexPath in indexPaths {            
            guard let game = getGameInfo(indexPath),
                  let imageUrl = game.gameImageURLs.first else {
                continue
            }
            guard ImageCache.sharedInstance().getImage(imageUrl) == nil else {
                print("image already in cache, not fetching...")
                continue
            }
            ImageCache.sharedInstance().getImage(imageUrl, localURL: game.gameLocalImageURL) { _ in
                print("Prefetch: fetched image and put in cache")
            }
        }
    }
}
