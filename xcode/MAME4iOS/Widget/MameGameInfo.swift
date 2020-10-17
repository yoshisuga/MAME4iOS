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
        return description.components(separatedBy: " (")[0]
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
        return getImage()
    }
    
    func getImage(aspect:CGFloat = 0.0, mode:UIView.ContentMode = .scaleAspectFit) -> UIImage {

        if let data = try? Data(contentsOf:self.localURL), let image = UIImage(data:data) {
            return image
        }
        
        var image:UIImage
        
        if let data = try? Data(contentsOf:self.remoteURL), let img = UIImage(data:data) {
            // make the aspect ratio exactly 4:3 or 3:4
            if img.size.width > img.size.height {
                image = img.resize(width:floor(img.size.height * (4.0/3.0)), height:img.size.height)
            }
            else {
                image = img.resize(width:img.size.width, height:floor(img.size.width * (4.0/3.0)))
            }
        }
        else {
            image = UIImage(named:"default_game_icon") ?? UIImage()
        }
        
        // then aspect fit
        if aspect != 0.0 {
            let h = max(image.size.width, image.size.height)
            image = image.resize(width:floor(h * aspect), height:h, mode:mode, color:image.color)
        }
        
        if let data = image.pngData() {
            try? data.write(to:self.localURL)
        }
        return image
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
        return "group." + (self.bundleIdentifier!).components(separatedBy:".").prefix(3).joined(separator:".")
    }
}

extension UserDefaults {
    static var shared:UserDefaults? {
        return UserDefaults(suiteName:Bundle.main.groupIdentifier)
    }
}

// MARK: UIImage resize

extension UIImage {
    func resize(width:CGFloat, height:CGFloat, mode:UIView.ContentMode = .scaleToFill, color:UIColor? = nil) -> UIImage {
        assert(mode == .scaleAspectFit || mode == .scaleAspectFill || mode == .scaleToFill)
        let size = CGSize(width:width, height:height)
        var rect = CGRect(origin:.zero, size:size)
        
        switch mode {
        case .scaleAspectFill:
            let scale = max(size.width / self.size.width, size.height / self.size.height)
            let w = floor(self.size.width*scale)
            let h = floor(self.size.height*scale)
            rect = CGRect(x:(size.width - w)/2, y:(size.height-h)/2, width:w, height:h)
        case .scaleAspectFit:
            let scale = min(size.width / self.size.width, size.height / self.size.height)
            let w = floor(self.size.width*scale)
            let h = floor(self.size.height*scale)
            rect = CGRect(x:(size.width - w)/2, y:(size.height-h)/2, width:w, height:h)
        case .scaleToFill:
            break;
        default:
            return self
        }
        
        return UIGraphicsImageRenderer(size:size).image { context in
            if let color = color {
                color.setFill()
                context.fill(CGRect(origin:.zero, size:size))
            }
            self.draw(in:rect)
        }
    }
    // return a single color representing whole image
    var color:UIColor {
        let px = 1.0 / UIScreen.main.scale
        return UIColor(patternImage:self.resize(width:px, height:px))
    }
}


