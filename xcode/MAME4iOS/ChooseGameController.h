//
//  ChooseGameController.h
//  MAME4iOS
//
//  Created by Todd Laney on 10/20/19.
//

#include "GameInfo.h"

#ifndef ChooseGameController_h
#define ChooseGameController_h

@interface ChooseGameController : UICollectionViewController

- (void)setGameList:(NSArray<GameInfoDictionary*>*)games;
+ (void)reset;

#if TARGET_OS_IOS
+ (NSUserActivity*)userActivityForGame:(GameInfoDictionary*)game;
#endif

@property(nonatomic, strong) void (^selectGameCallback)(GameInfoDictionary* info);
@property(nonatomic, strong) UIImage* backgroundImage;
@property(nonatomic, assign) BOOL hideConsoles;

+(NSAttributedString*)getGameText:(GameInfoDictionary*)game;

@end


#endif /* ChooseGameController_h */
