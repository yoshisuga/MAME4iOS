//
//  ChooseGameController.h
//  MAME4iOS
//
//  Created by Todd Laney on 10/20/19.
//

#include "GameInfo.h"

#ifndef ChooseGameController_h
#define ChooseGameController_h

NS_ASSUME_NONNULL_BEGIN

@interface ChooseGameController : UICollectionViewController

- (void)setGameList:(NSArray<GameInfo*>*)games;
+ (void)reset;

#if TARGET_OS_IOS
+ (NSUserActivity*)userActivityForGame:(GameInfo*)game;
#endif

@property(nonatomic, strong) void (^selectGameCallback)(GameInfo* info);
@property(nonatomic, strong) void (^settingsCallback)(id from);
@property(nonatomic, strong) void (^romsCallback)(id from);

@property(nonatomic, strong) UIImage* backgroundImage;
@property(nonatomic, assign) BOOL hideConsoles;

+(NSAttributedString*)getGameText:(GameInfo*)game;
+(UIImage*)getGameIcon:(GameInfo*)game;
-( GameInfo* _Nullable)getGameInfo:(NSIndexPath*)indexPath;

@end

NS_ASSUME_NONNULL_END

#endif /* ChooseGameController_h */
