//
//  ChooseGameController.h
//  MAME4iOS
//
//  Created by Todd Laney on 10/20/19.
//

#ifndef ChooseGameController_h
#define ChooseGameController_h

@interface ChooseGameController : UICollectionViewController

- (void)setGameList:(NSArray*)games;
+ (void)reset;

#if TARGET_OS_IOS
+ (NSUserActivity*)userActivityForGame:(NSDictionary*)game;
#endif

@property(nonatomic, strong) void (^selectGameCallback)(NSDictionary* info);
@property(nonatomic, strong) UIImage* backgroundImage;

+(NSAttributedString*)getGameText:(NSDictionary*)game;

@end


#endif /* ChooseGameController_h */
