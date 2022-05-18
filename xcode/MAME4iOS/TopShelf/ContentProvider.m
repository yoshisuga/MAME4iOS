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

// see if a URL is home (ie non 404)
- (BOOL)testURL:(NSURL*)url {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"HEAD"];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block NSInteger status_code = 404;
    [[NSURLSession.sharedSession dataTaskWithRequest:request completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
        if (error == nil && [response isKindOfClass:[NSHTTPURLResponse class]])
            status_code = [(NSHTTPURLResponse*)response statusCode];
        dispatch_semaphore_signal(semaphore);
    }] resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return status_code == 200;
}

// get a TopSelf item from game info
-(TVTopShelfSectionedItem*)getGameItem:(NSDictionary*)dict {
    
    if (![dict isKindOfClass:[NSDictionary class]])
        return nil;

    GameInfo* game = [[GameInfo alloc] initWithDictionary:dict];

    if (game.gameName.length == 0 || game.gameDescription.length == 0 || game.gameIsMame)
        return nil;

    if (game.gameImageURLs.count == 0 || game.gamePlayURL == nil)
        return nil;
    
    NSString* identifier = game.gamePlayURL.absoluteString;
    TVTopShelfSectionedItem* item = [[TVTopShelfSectionedItem alloc] initWithIdentifier:identifier];
    item.title = game.gameTitle;
    
    for (NSURL* url in game.gameImageURLs) {
        if ([self testURL:url]) {
            item.imageShape = TVTopShelfSectionedItemImageShapePoster;
            [item setImageURL:url forTraits:TVTopShelfItemImageTraitScreenScale1x];
            break;
        }
    }

    item.playAction = [[TVTopShelfAction alloc] initWithURL:game.gamePlayURL];
    item.displayAction = item.playAction;

    return item;
}

-(TVTopShelfItemCollection*)getSection:(NSString*)title games:(NSArray<NSDictionary*>*)games {

    NSMutableArray* items = [games mutableCopy];
    
    // do the equiv of a compactMap
    for (int i=0; i<items.count; i++)
        items[i] = [self getGameItem:items[i]] ?: NSNull.null;
    [items removeObjectIdenticalTo:NSNull.null];
     
    TVTopShelfItemCollection* section = [[TVTopShelfItemCollection alloc] initWithItems:items];
    section.title = title;
    return section;
}

- (void)loadTopShelfContentWithCompletionHandler:(void (^) (id<TVTopShelfContent> content))completionHandler {
    NSUserDefaults* defaults = [self sharedUserDefaults];
    
    NSArray* recent_games = [defaults arrayForKey:RECENT_GAMES_KEY] ?: @[];
    NSArray* favorite_games = [defaults arrayForKey:FAVORITE_GAMES_KEY] ?: @[];
    
    // if we dont have any content to show, let tvOS show the default image.
    if (recent_games.count + favorite_games.count == 0) {
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
