//
//  Game.swift
//  MAME4iOS
//
//  Created by Todd Laney on 10/12/20.
//  Copyright © 2020 Seleuco. All rights reserved.
//
import Foundation
import UIKit

struct MameGameInfo {
    let name:String
    let description:String
    
    init(_ dict:[String:Any]) {
        name = (dict["name"] as? String) ?? ""
        description = (dict["description"] as? String) ?? ""
    }
    
    var displayName: String {
        return description.components(separatedBy: " (").first!
    }
    
    var localURL:URL {
        let url = FileManager.default.urls(for:.cachesDirectory, in:.userDomainMask).first!
        return url.appendingPathComponent(self.name).appendingPathExtension("png")
    }
    
    var remoteURL:URL {
        let url = URL(string:"https://raw.githubusercontent.com/libretro-thumbnails/MAME/master/Named_Titles")!
        
        var file = self.description
        
        /// from [libretro docs](https://docs.libretro.com/guides/roms-playlists-thumbnails/)
        /// The following characters in titles must be replaced with _ in the corresponding filename: &*/:`<>?\|
        for str in ["&", "*", "/", ":", "`", "<", ">", "?", "\\", "|"] {
            file = file.replacingOccurrences(of:str, with:"_")
        }
        
        return url.appendingPathComponent(file).appendingPathExtension("png")
    }
    
    var playURL:URL {
        return URL(string:"mame4ios://\(name)")!
    }

    var displayImage: UIImage {

        if let data = try? Data(contentsOf:self.localURL), let image = UIImage(data:data) {
            return image
        }
        
        if let data = try? Data(contentsOf:self.remoteURL), var image = UIImage(data:data) {
            // make the aspect ratio exactly 4:3 or 3:4
            if image.size.width > image.size.height {
                image = image.resize(floor(image.size.height * (4.0/3.0)), image.size.height)
            }
            else {
                image = image.resize(image.size.width, floor(image.size.width * (4.0/3.0)))
            }
            if let data = image.pngData() {
                try? data.write(to:self.localURL)
            }
            return image
        }
        
        return UIImage(named:"default_game_icon") ?? UIImage()
    }
}

extension MameGameInfo {

    // these keys are from ChooseGameController.h
    static let FAVORITE_GAMES_KEY      = "FavoriteGames"
    static let FAVORITE_GAMES_TITLE    = "Favorite Games"
    static let RECENT_GAMES_KEY        = "RecentGames"
    static let RECENT_GAMES_TITLE      = "Recent Games"
    
    static let QUICK_GAMES_KEY         = "QuickGames"
    static let APP_GROUP_VALID_KEY     = "AppGroupValid"
    
    static var isSharedGroupSetup:Bool {
        return UserDefaults.shared?.object(forKey:APP_GROUP_VALID_KEY) != nil
    }
    
    static func games(for key:String) -> [MameGameInfo] {
        return (UserDefaults.shared?.array(forKey:key) as? [[String:Any]] ?? []).map(MameGameInfo.init)
    }
    static var quickGames : [MameGameInfo] {
        return games(for: QUICK_GAMES_KEY)
    }
    static var recentGames : [MameGameInfo] {
        return games(for: RECENT_GAMES_KEY)
    }
    static var favoriteGames : [MameGameInfo] {
        return games(for: FAVORITE_GAMES_KEY)
    }
}

// MARK: SHARED USER DEFAULTS

extension Bundle {
    var groupIdentifier:String {
        return "group." + (self.bundleIdentifier!).components(separatedBy:".").prefix(2).joined(separator:".") + ".mame4ios"
    }
}

extension UserDefaults {
    static var shared:UserDefaults? {
        return UserDefaults(suiteName:Bundle.main.groupIdentifier)
    }
}

// MARK: UIImage resize

private extension UIImage {
    func resize(_ width:CGFloat, _ height:CGFloat) -> UIImage {
        return UIGraphicsImageRenderer(size:CGSize(width:width, height:height)).image { context in
            self.draw(in:CGRect(x:0, y:0, width: width, height:height))
        }
    }
}



