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

struct Provider: TimelineProvider {
    
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> ()) {
        
        if context.isPreview {
            return completion(placeholder(in:context))
        }
        let games = MameGameInfo.quickGames
        let entry = WidgetEntry(games:games)
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
    var games = [MameGameInfo]()
}

struct GameView : View {
    let game:MameGameInfo
    
    var body: some View {
        Link(destination:game.playURL) {
            VStack(spacing:0) {
                Image(uiImage:game.displayImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                Spacer()
                Text(game.displayName)
                    //.font(Font.footnote.bold())
                    .font(Font.caption2)
                    .lineLimit(1)
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
            if !MameGameInfo.isSharedGroupSetup {
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
                HStack(alignment: .top) {
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
    
    // we only want to allow a widget in the widget gallery if a shared group is properly configured.
    let showWidget = MameGameInfo.isSharedGroupSetup

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WidgetEntryView(entry:entry)
        }
        .configurationDisplayName("MAME Widget")
        .description("Recent and Favorite Games.")
        .supportedFamilies(showWidget ? [.systemMedium] : [])
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
