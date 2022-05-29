//
//  GameInfo
//  MAME4iOS
//
//  Created by ToddLa on 4/5/21.
//  Copyright © 2021 Seleuco. All rights reserved.
//

import Foundation

// TODO: where to put these so that ObjC and Swift can see them?
// keys used in a NSUserDefaults
let FAVORITE_GAMES_KEY      = "FavoriteGames"
let FAVORITE_GAMES_TITLE    = "Favorite Games"
let RECENT_GAMES_KEY        = "RecentGames"
let RECENT_GAMES_TITLE      = "Recently Played"

let kGameInfoScreenHorizontal   = "Horizontal"
let kGameInfoScreenVertical     = "Vertical"
let kGameInfoScreenVector       = "Vector"
let kGameInfoScreenLCD          = "LCD"

// MARK: GameInfoType
@objc enum GameInfoType : Int {
    case arcade         // standalone Arcade game, ie pacman
    case console        // console based game (or system), ie a2600
    case computer       // computer based game (or syster), ie apple2
    case bios           // non-playable bios
    case snapshot       // a PNG image snapshot (located in `snaps` dir)
    case software       // a non-software-list rom file. (located in `software` dir)
}

// MARK: Document root

#if os(iOS)
    private let root = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
#else
    private let root = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
#endif

// MARK: GameInfo
// TODO: this class will eventualy replace the ObjC version, work in-progress
// TODO: ...main issue is how  (or if) to expose the dictionary keys to both Swift and ObjC

@objcMembers
final class XGameInfo : NSObject {

    var gameType = GameInfoType.arcade
    var gameSystem = ""
    var gameName = ""
    var gameParent = ""
    var gameYear = ""
    var gameDescription = ""
    var gameManufacturer = ""
    var gameDriver = ""
    var gameScreen = ""
    var gameCategory = ""
    var gameSoftwareMedia = ""
    var gameSoftwareList = ""
    var gameFile = ""
    var gameMediaType = ""
    var gameCustomCmdline = ""
    
    // special "fake" (aka built-in) games
    enum FakeNames {
        static let mame = "mameui"
    }
    
    enum DictionaryKeys {
       static let gameType          = "type"
       static let gameSystem        = "system"
       static let gameName          = "name"
       static let gameParent        = "parent"
       static let gameYear          = "year"
       static let gameDescription   = "description"
       static let gameManufacturer  = "manufacturer"
       static let gameScreen        = "screen"
       static let gameDriver        = "driver"
       static let gameCategory      = "category"
       static let gameSoftwareMedia = "software"         // list of supported software, and media for system
       static let gameSoftwareList  = "softlist"         // this game is *from* a software list
       static let gameFile          = "file"
       static let gameMediaType     = "media"
       static let gameCustomCmdline = "cmdline"
    }
    
    // keys used in a NSUserDefaults
    enum UserDefaultsKeys {
        static let favoriteGames = "FavoriteGames"
        static let recentGames   = "RecentGames"
    }
    
    // titles used in a NSUserDefaults
    enum Titles {
        static let favoriteGames = "Favorite Games"
        static let recentGames   = "Recently Played"
    }
    
    init(type:GameInfoType = .arcade, system:String = "", name:String = "", description:String = "", year:String = "", manufacturer:String = "") {
        self.gameType = type
        self.gameSystem = system
        self.gameName = name
        self.gameYear = year
        self.gameManufacturer = manufacturer
        self.gameDescription = description
    }
    
    @objc(initWithDictionary:)
    init(_ dict:[String:String]) {
        self.gameType          = GameInfoType(rawValue: dict[DictionaryKeys.gameType] ?? "") ?? .arcade
        self.gameSystem        = dict[DictionaryKeys.gameSystem        ] ?? ""
        self.gameName          = dict[DictionaryKeys.gameName          ] ?? ""
        self.gameParent        = dict[DictionaryKeys.gameParent        ] ?? ""
        self.gameYear          = dict[DictionaryKeys.gameYear          ] ?? ""
        self.gameDescription   = dict[DictionaryKeys.gameDescription   ] ?? ""
        self.gameManufacturer  = dict[DictionaryKeys.gameManufacturer  ] ?? ""
        self.gameScreen        = dict[DictionaryKeys.gameScreen        ] ?? ""
        self.gameDriver        = dict[DictionaryKeys.gameDriver        ] ?? ""
        self.gameCategory      = dict[DictionaryKeys.gameCategory      ] ?? ""
        self.gameSoftwareMedia = dict[DictionaryKeys.gameSoftwareMedia ] ?? ""
        self.gameSoftwareList  = dict[DictionaryKeys.gameSoftwareList  ] ?? ""
        self.gameFile          = dict[DictionaryKeys.gameFile          ] ?? ""
        self.gameMediaType     = dict[DictionaryKeys.gameMediaType     ] ?? ""
        self.gameCustomCmdline = dict[DictionaryKeys.gameCustomCmdline ] ?? ""
    }

    var dictionaryRepresentation : [String:String] {
        return [
            DictionaryKeys.gameType          : gameType.rawValue,
            DictionaryKeys.gameSystem        : gameSystem,
            DictionaryKeys.gameName          : gameName,
            DictionaryKeys.gameParent        : gameParent,
            DictionaryKeys.gameYear          : gameYear,
            DictionaryKeys.gameDescription   : gameDescription,
            DictionaryKeys.gameManufacturer  : gameManufacturer,
            DictionaryKeys.gameScreen        : gameScreen,
            DictionaryKeys.gameDriver        : gameDriver,
            DictionaryKeys.gameCategory      : gameCategory,
            DictionaryKeys.gameSoftwareMedia : gameSoftwareMedia,
            DictionaryKeys.gameSoftwareList  : gameSoftwareList,
            DictionaryKeys.gameFile          : gameFile,
            DictionaryKeys.gameMediaType     : gameMediaType,
            DictionaryKeys.gameCustomCmdline : gameCustomCmdline
        ].filter {!$0.value.isEmpty}
    }
    
    var gameIsSnapshot : Bool {
        return gameType == .snapshot
    }
    var gameIsSoftware : Bool {
        return gameType == .software
    }
    var gameIsConsole : Bool {
        return gameType == .console
    }
    var gameIsClone : Bool {
        return gameParent.count > 1  // parent can be "0"
    }
    var gameIsMame : Bool {
        return gameName == FakeNames.mame
    }
    var gameTitle : String {
        var title = gameDescription
        if title.isEmpty {
            title = gameName
        }
        title = title.components(separatedBy:" (")[0]
        title = title.components(separatedBy:" [")[0]
        return title
    }
}

// MARK: image URLs

extension XGameInfo {
    
    var gameLocalImageURL : URL? {
        
        let name = gameName
        
        if name.isEmpty {
            return nil
        }
        
        if (self.gameIsMame) {
            return Bundle.main.url(forResource:name, withExtension:"png")
        }
        
        if gameIsSnapshot {
            return URL(fileURLWithPath: "\(root)/\(gameFile)")
        }
        else if gameIsSoftware {
            return URL(fileURLWithPath: "\(root)/\(gameFile).png")
        }
        else if !gameSoftwareList.isEmpty {
            return URL(fileURLWithPath: "\(root)/titles/\(gameSoftwareList)/\(name).png")
        }
        else {
            return URL(fileURLWithPath: "\(root)/titles/\(name).png")
        }
    }
    
    var gameImageURLs : [URL] {
        
        let name = gameName
        
        if name.isEmpty {
            return []
        }
        
        if gameIsMame || self.gameIsSnapshot {
            return [gameLocalImageURL!]
        }
        else if !gameSoftwareList.isEmpty {
            /// MESS style title url
            /// http://adb.arcadeitalia.net/media/mess.current/titles/a2600/adventur.png
            /// http://adb.arcadeitalia.net/media/mess.current/ingames/a2600/pitfall.png
            
            let base = "http://adb.arcadeitalia.net/media/mess.current"
            let list = gameSoftwareList
            let name = gameName.lowercased().addingPercentEncoding(withAllowedCharacters:.urlPathAllowed)!
                
            return [
                URL(string: "\(base)/covers/\(list)/\(name).png")!,
                URL(string: "\(base)/titles/\(list)/\(name).png")!,
                URL(string: "\(base)/ingames/\(list)/\(name).png")!
            ]
        }
        else if gameIsConsole {
            /// MESS style title url
            /// http://adb.arcadeitalia.net/media/mame.current/cabinets/n64.png
            /// http://adb.arcadeitalia.net/media/mame.current/titles/n64.png
            
            let base = "http://adb.arcadeitalia.net/media/mess.current"
            let name = gameName.lowercased().addingPercentEncoding(withAllowedCharacters:.urlPathAllowed)!

            return [
                URL(string: "\(base)/cabinets/\(name).png")!,
                URL(string: "\(base)/titles/\(name).png")!,
            ]
        }
        else if gameIsSoftware {
            return [gameLocalImageURL!]
        }
        else {
            /// libretro title url
            /// https://raw.githubusercontent.com/libretro-thumbnails/MAME/master/Named_Titles/pacman.png

            /// MAME title url
            /// http://adb.arcadeitalia.net/media/mame.current/titles/n64.png

            let libretro_base = "https://raw.githubusercontent.com/libretro-thumbnails/MAME/master/Named_Titles"
            let arcadeitalia_base = "http://adb.arcadeitalia.net/media/mame.current/titles"

            let name = gameName.lowercased().addingPercentEncoding(withAllowedCharacters:.urlPathAllowed)!
            var desc = gameDescription

            /// from [libretro docs](https://docs.libretro.com/guides/roms-playlists-thumbnails/)
            /// The following characters in titles must be replaced with _ in the corresponding filename: &*:/`<>?\|
            for str in ["&", "*", "/", ":", "`", "<", ">", "?", "\\", "|"] {
                desc = desc.replacingOccurrences(of:str, with:"_")
            }
            
            desc = desc.addingPercentEncoding(withAllowedCharacters:.urlPathAllowed)!
            
            return [
                URL(string: "\(libretro_base)/\(desc).png")!,
                URL(string: "\(arcadeitalia_base)/\(name).png")!,
            ]
        }
    }
}

// MARK: play URLs

extension XGameInfo {

    // URL syntax is `mame4ios://name` OR `mame4ios://system/name` OR `mame4ios://system/media:file`

    @objc(initWithURL:)
    convenience init?(_ url:URL) {
        guard url.scheme == "mame4ios" else { return nil }
        guard let host = url.host, !host.isEmpty else { return nil }
        let path = url.path
        
        // mame4ios://name
        if path.isEmpty {
            self.init(name:host)
        }
        // mame4ios://system/media:file
        else if path.contains(":") {
            self.init(type:.console, system:host)
            self.gameMediaType = path.components(separatedBy:":")[0]
            self.gameFile = path.components(separatedBy:":")[1]
        }
        // mame4ios://system/name
        else {
            self.init(type:.console, system:host, name:path)
        }
    }
    
    var gamePlayURL : URL? {
        if (gameIsSoftware) {
            return URL(string: "mame4ios://\(gameSystem)/\(gameMediaType):\(gameFile)")
        }
        else if !gameSystem.isEmpty {
            return URL(string: "mame4ios://\(gameSystem)/\(gameName)")
        }
        else {
            return URL(string: "mame4ios://\(gameName)")
        }
    }
    
}

// MARK: Metadata

extension XGameInfo {
    
    // get the sidecar file used to store custom metadata/info
    var gameMetadataURL : URL? {
        
        // only do custom metadata for "software" (aka non-MESS, non-Arcade)
        // TODO: maybe have a sidecar for Arcade and MESS
        if gameFile.isEmpty {
            return nil
        }
        
        return URL(string:"\(root)/(gameFile).json")
    }
    
    // load any on-disk metadata json
    var gameMetadata : [String:String]?
    {
        guard let url = gameMetadataURL else { return nil }
        guard let data = try? Data(contentsOf:url) else { return nil }
        let info = try? JSONSerialization.jsonObject(with: data)
        return info as? [String:String]
    }
    
    // modify custom metadata key, and save to sidecar
    func setValue(value:String, forKey key:String)
    {
        if (self.value(forKey:key) as? String) == value {
            return
        }
        /*
        guard let url = gameMetadataURL else {
            return self.setValue(value, forKey:key)
        }
        
        self.setValue(value, forKey:key)
        
        var info = gameMetadata ?? [:]
        info[key] = value
        if info.isEmpty {
            try? FileManager.default.removeItem(at:url)
        }
        else if let data = try? JSONSerialization.data(withJSONObject:info, options:.prettyPrinted) {
            try? data.write(to:url)
        }
        */
        
        self.setValue(value, forKey:key)
    }
    
    // load and merge any on-disk metadata for this game
    func gameLoadMetadata()
    {
        /*
        GameInfoDictionary* info = self.gameMetadata;
        if (info.count == 0)
            return self;
        NSMutableDictionary* game = [self mutableCopy];
        [game addEntriesFromDictionary:info];
        return [game copy];
        */
    }

}


// MARK: Codable

// support Codable for *pure* Swift use, but based on ObjC and PropertyList friendly `dictionaryRepresentation`
// ...and if we add or remove keys later, we will get a default value not a failure
extension XGameInfo : Codable {
    convenience init(from decoder: Decoder) throws {
        let dict = try [String:String](from: decoder)
        self.init(dict)
    }
    func encode(to encoder: Encoder) throws {
        try self.dictionaryRepresentation.encode(to: encoder)
    }
}

// MARK: GameInfoType : RawRepresentable
// NOTE: do String RawRepresentable by hand so the enum type can be exported to ObjC

extension GameInfoType : RawRepresentable {

    public var rawValue: String {
        switch self {
        case .arcade:    return "Arcade"
        case .console:   return "Console"
        case .computer:  return "Computer"
        case .bios:      return "BIOS"
        case .snapshot:  return "Snapshot"
        case .software:  return "Software"
        }
    }

    public init?(rawValue: String) {
        switch rawValue {
        case "Arcade":  self = .arcade
        case "Console": self = .console
        case "Computer":self = .computer
        case "BIOS":    self = .bios
        case "Snapshot":self = .snapshot
        case "Software":self = .software
        default: return nil
        }
    }
}
