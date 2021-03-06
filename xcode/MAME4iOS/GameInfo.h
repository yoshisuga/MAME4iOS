//
//  GameInfo.h
//  MAME4iOS
//
//  Created by ToddLa on 4/5/21.
//  Copyright © 2021 Seleuco. All rights reserved.
//

#import <Foundation/Foundation.h>

// keys used in a NSUserDefaults
#define FAVORITE_GAMES_KEY      @"FavoriteGames"
#define FAVORITE_GAMES_TITLE    @"Favorite Games"
#define RECENT_GAMES_KEY        @"RecentGames"
#define RECENT_GAMES_TITLE      @"Recently Played"

// keys used in a GameInfo dictionary
#define kGameInfoType           @"type"
#define kGameInfoSystem         @"system"
#define kGameInfoName           @"name"
#define kGameInfoParent         @"parent"
#define kGameInfoYear           @"year"
#define kGameInfoDescription    @"description"
#define kGameInfoManufacturer   @"manufacturer"
#define kGameInfoScreen         @"screen"
#define kGameInfoDriver         @"driver"
#define kGameInfoCategory       @"category"
#define kGameInfoHistory        @"history"
#define kGameInfoMameInfo       @"mameinfo"
#define kGameInfoSoftware       @"software"         // list of supported software for system
#define kGameInfoSoftwareList   @"softlist"         // this game is *from* a software list
#define kGameInfoFile           @"file"

#define kGameInfoTypeArcade     @"Arcade"
#define kGameInfoTypeConsole    @"Console"
#define kGameInfoTypeComputer   @"Computer"
#define kGameInfoTypeBIOS       @"BIOS"
#define kGameInfoTypeSnapshot   @"Snapshot"

#define kGameInfoScreenHorizontal   @"Horizontal"
#define kGameInfoScreenVertical     @"Vertical"
#define kGameInfoScreenVector       @"Vector"
#define kGameInfoScreenLCD          @"LCD"

// special "fake" (aka built-in) games
#define kGameInfoNameSettings   @"settings"
#define kGameInfoNameMameMenu   @"mameui"

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (GameInfo)

@property (nonatomic, strong, readonly) NSString* gameType;
@property (nonatomic, strong, readonly) NSString* gameSystem;
@property (nonatomic, strong, readonly) NSString* gameName;
@property (nonatomic, strong, readonly) NSString* gameParent;
@property (nonatomic, strong, readonly) NSString* gameYear;
@property (nonatomic, strong, readonly) NSString* gameDescription;
@property (nonatomic, strong, readonly) NSString* gameManufacturer;
@property (nonatomic, strong, readonly) NSString* gameDriver;
@property (nonatomic, strong, readonly) NSString* gameScreen;
@property (nonatomic, strong, readonly) NSString* gameCategory;
@property (nonatomic, strong, readonly) NSString* gameSoftware;
@property (nonatomic, strong, readonly) NSString* gameSoftwareList;
@property (nonatomic, strong, readonly) NSString* gameFile;

@property (nonatomic, strong, readonly) NSString* gameTitle;
@property (nonatomic, strong, readonly) NSURL* gameImageURL;
@property (nonatomic, strong, readonly) NSURL* gameLocalImageURL;
@property (nonatomic, strong, readonly) NSURL* gamePlayURL;
@property (nonatomic, strong, readonly) NSArray<NSURL*>* gameImageURLs;

@property (nonatomic, readonly) BOOL gameIsFake;
@property (nonatomic, readonly) BOOL gameIsMame;
@property (nonatomic, readonly) BOOL gameIsSnapshot;
@property (nonatomic, readonly) BOOL gameIsClone;

@end

NS_ASSUME_NONNULL_END
