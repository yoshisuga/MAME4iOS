//
//  ContentProvider.swift
//  TopShelf
//
//  Created by Todd Laney on 10/12/20.
//  Copyright © 2020 Seleuco. All rights reserved.
//
import UIKit
import TVServices

@available(tvOSApplicationExtension 13.0, *)
extension MameGameInfo {
    var topShelfItem:TVTopShelfSectionedItem {

        let item = TVTopShelfSectionedItem(identifier:self.name)
        item.title = self.displayName
        
        // load image to localURL
        let image = self.displayImage
        
        item.imageShape = (image.size.width > image.size.height) ? .square : .poster
        item.setImageURL(self.localURL, for:.screenScale1x)
        item.displayAction = TVTopShelfAction(url:self.playURL)
        item.playAction = item.displayAction

        return item
    }
}

@available(tvOSApplicationExtension 13.0, *)
class ContentProvider: TVTopShelfContentProvider {

    override func loadTopShelfContent(completionHandler: @escaping (TVTopShelfContent?) -> Void) {
        
        var recent = MameGameInfo.recentGames.map({$0.topShelfItem})
        let favorite = MameGameInfo.favoriteGames.map({$0.topShelfItem})
        
        if recent.isEmpty && favorite.isEmpty {
            return completionHandler(nil);
        }
        
        // limit the recent games to only 4 if we have favorites
        if !favorite.isEmpty {
            recent = Array(recent.prefix(4))
        }
        
        func Section(title:String, items:[TVTopShelfSectionedItem]) -> TVTopShelfItemCollection<TVTopShelfSectionedItem> {
            let section = TVTopShelfItemCollection(items:items)
            section.title = title
            return section
        }
        
        let content = TVTopShelfSectionedContent(sections:[
            Section(title:MameGameInfo.RECENT_GAMES_TITLE, items:recent),
            Section(title:MameGameInfo.FAVORITE_GAMES_TITLE, items:favorite),
        ])
        completionHandler(content);
    }

}
