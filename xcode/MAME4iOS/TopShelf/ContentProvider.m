//
//  ContentProvider.m
//  TopShelf
//
//  Created by ToddLa on 2/2/21.
//  Copyright © 2021 Seleuco. All rights reserved.
//
#import "ContentProvider.h"
#import "GameInfo.h"

#pragma mark tvOS TopShelf ContentProvider

@implementation ContentProvider

// get the shared UserDefaults based on our bundle id
// because we are in an extension, we need to remove the last component of the bundle ident, and add "group." at the start.
-(NSUserDefaults*)sharedUserDefaults {
    NSMutableArray* items = [[NSBundle.mainBundle.bundleIdentifier componentsSeparatedByString:@"."] mutableCopy];
    [items removeLastObject];
    [items insertObject:@"group" atIndex:0];
    NSString* name = [items componentsJoinedByString:@"."];
    return [[NSUserDefaults alloc] initWithSuiteName:name];
}

// get a TopSelf item from game info
-(TVTopShelfSectionedItem*)getGameItem:(NSDictionary*)game {

    if (![game isKindOfClass:[NSDictionary class]] || game[kGameInfoName] == nil || game[kGameInfoDescription] == nil)
        return nil;

    // the MAME UI does not have a Title image, so exclude it.
    if ([game.gameName isEqualToString:kGameInfoNameMameMenu])
        return nil;

    TVTopShelfSectionedItem* item = [[TVTopShelfSectionedItem alloc] initWithIdentifier:game.gameName];
    item.title = game.gameTitle;

    item.imageShape = TVTopShelfSectionedItemImageShapePoster;
    [item setImageURL:game.gameImageURL forTraits:TVTopShelfItemImageTraitScreenScale1x];
     
    item.playAction = [[TVTopShelfAction alloc] initWithURL:game.gamePlayURL];
    item.displayAction = item.playAction;

    return item;
}

-(TVTopShelfItemCollection*)getSection:(NSString*)title games:(NSArray<NSDictionary*>*)games {

    NSMutableArray* items = [games mutableCopy];
    
    for (int i=0; i<items.count; i++)
        items[i] = [self getGameItem:items[i]] ?: NSNull.null;
    
    [items removeObjectIdenticalTo:NSNull.null];
     
    TVTopShelfItemCollection* section = [[TVTopShelfItemCollection alloc] initWithItems:items];
    section.title = title;
    return section;
}

- (void)loadTopShelfContentWithCompletionHandler:(void (^) (id<TVTopShelfContent> content))completionHandler {
    NSUserDefaults* defaults = [self sharedUserDefaults];
    
    NSArray* recent_games = [defaults objectForKey:RECENT_GAMES_KEY];
    NSArray* favorite_games = [defaults objectForKey:FAVORITE_GAMES_KEY];
    
    // if we dont have any content to show, let tvOS show the default image.
    if (![recent_games isKindOfClass:[NSArray class]] || ![favorite_games isKindOfClass:[NSArray class]] || (recent_games.count + favorite_games.count) == 0) {
        return completionHandler(nil);
    }
    
    // limit the recent games to only 4 if we have favorites
    if (favorite_games.count > 0 && recent_games.count > 4)
        recent_games = [recent_games subarrayWithRange:NSMakeRange(0, 4)];
    
    NSMutableArray* sections = [[NSMutableArray alloc] init];
    
    if (recent_games.count > 0)
        [sections addObject:[self getSection:RECENT_GAMES_TITLE games:recent_games]];
    
    if (favorite_games.count > 0)
        [sections addObject:[self getSection:FAVORITE_GAMES_TITLE games:favorite_games]];

    TVTopShelfSectionedContent* content = [[TVTopShelfSectionedContent alloc] initWithSections:sections];
    completionHandler(content);
}

@end
