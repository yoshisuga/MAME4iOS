//
//  ChooseGameController.h
//  MAME4iOS
//
//  Created by Todd Laney on 10/20/19.
//

#ifndef ChooseGameController_h
#define ChooseGameController_h

// keys used in a NSUserDefaults
#define FAVORITE_GAMES_KEY      @"FavoriteGames"
#define FAVORITE_GAMES_TITLE    @"Favorite Games"
#define RECENT_GAMES_KEY        @"RecentGames"
#define RECENT_GAMES_TITLE      @"Recently Played"
#define QUICK_GAMES_KEY         @"QuickGames"
#define APP_GROUP_VALID_KEY     @"AppGroupValid"

// keys used in a GameInfo dictionary
#define kGameInfoDriver         @"driver"
#define kGameInfoName           @"name"
#define kGameInfoParent         @"parent"
#define kGameInfoYear           @"year"
#define kGameInfoDescription    @"description"
#define kGameInfoManufacturer   @"manufacturer"
#define kGameInfoCategory       @"category"
#define kGameInfoHistory        @"history"
#define kGameInfoMameInfo       @"mameinfo"

// special "system" games
#define kGameInfoNameSettings   @"settings"
#define kGameInfoNameMameMenu   @"mameui"

@interface ChooseGameController : UICollectionViewController

- (void)setGameList:(NSArray*)games;
+ (void)reset;

#if TARGET_OS_IOS
+ (NSUserActivity*)userActivityForGame:(NSDictionary*)game;
#endif

@property(nonatomic, strong) void (^selectGameCallback)(NSDictionary* info);
@property(nonatomic, strong) UIImage* backgroundImage;

@end


#endif /* ChooseGameController_h */
