//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import "libmame.h"
#import "GameInfo.h"
#import "InfoDatabase.h"
#import "ChooseGameController.h"
#import "EmulatorController.h"
#import "ImageCache.h"

// Globals.h stuff needed from Swift
NS_ASSUME_NONNULL_BEGIN
extern NSString* getResourcePath(NSString* str);
extern NSString* getDocumentPath(NSString* str);
NS_ASSUME_NONNULL_END
