//
//  Widget.swift
//  Widget
//
//  Created by Todd Laney on 10/8/20.
//  Copyright © 2020 Seleuco. All rights reserved.
//
#if canImport(WidgetKit)
import WidgetKit
import SwiftUI

// this is from ChooseGameController.h
let QUICK_GAMES_KEY = "QuickGames"

struct Game {
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
    
    var widgetURL:URL {
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

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> ()) {
        
        guard !context.isPreview, let games = (UserDefaults.shared?.array(forKey: QUICK_GAMES_KEY) as? [[String:Any]]) else {
            return completion(placeholder(in:context))
        }
        
        let entry = WidgetEntry(games:games.map(Game.init))
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        getSnapshot(in: context) { entry in
            let timeline = Timeline(entries:[entry], policy:.never)
            completion(timeline)
        }
    }
}

struct WidgetEntry: TimelineEntry {
    let date = Date()
    var games = [Game]()
}

struct GameView : View {
    let game:Game
    
    var body: some View {
        Link(destination:game.widgetURL) {
            VStack {
                Image(uiImage:game.displayImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                Text(game.displayName)
                    .font(Font.footnote.bold())
                    .lineLimit(2)
                    .minimumScaleFactor(0.25)
                    .foregroundColor(Color("AccentColor"))
            }
        }
    }
}


struct WidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        Group {
            if UserDefaults.shared?.object(forKey:QUICK_GAMES_KEY) == nil {
                VStack {
                    Image(systemName:"nosign").font(Font.system(.largeTitle).bold())
                        .foregroundColor(.red)
                    Divider()
                    Text(Bundle.main.groupIdentifier)
                        .foregroundColor(.white)
                }
            }
            else if entry.games.isEmpty {
                Image(uiImage:UIImage(named:"mame_logo") ?? UIImage())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .unredacted()
            }
            else {
                HStack {
                    ForEach(0..<min(3, entry.games.count)) {
                        GameView(game:entry.games[$0])
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth:.infinity, maxHeight:.infinity, alignment:.center)
        .background(Color("WidgetBackground"))
    }
}

@main
struct Widget: SwiftUI.Widget {
    let kind: String = Bundle.main.bundleIdentifier!
    
    // we only want to allow a widget in te widget gallery if a shared group is properly configured.
    let showWidget = UserDefaults.shared?.object(forKey:QUICK_GAMES_KEY) != nil

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WidgetEntryView(entry:entry)
        }
        .configurationDisplayName("MAME Widget")
        .description("Recent and Favorite Games.")
        .supportedFamilies(showWidget ? [.systemMedium] : [])
    }
}

// MARK: SHARED USER DEFAULTS

private extension Bundle {
    var groupIdentifier:String {
        return "group." + (self.bundleIdentifier!).components(separatedBy:".").prefix(3).joined(separator:".")
    }
}

private extension UserDefaults {
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

// MARK: Preview

#if DEBUG
struct Widget_Previews: PreviewProvider {
    static var previews: some View {
        WidgetEntryView(entry: WidgetEntry())
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
#endif

#endif  // canImport(WidgetKit)
