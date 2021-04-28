//
//  SoftwareList
//
//  Manage the crazy MAME software list XML files for MAME4iOS
//
//  Created by ToddLa on 4/1/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SoftwareList : NSObject

- (instancetype)initWithPath:(NSString*)root;

// get names of all installed softlists
- (NSArray<NSString*>*)getNames;

// get full softlist data
- (NSArray<NSDictionary*>*)getList:(NSString*)name;

// get installed software list
- (NSArray<NSDictionary*>*)getInstalledList:(NSString*)name;

// get games for a system
- (NSArray<NSDictionary*>*)getGamesForSystem:(NSString*)system fromList:(NSString*)list;

// install a XML or ZIP file
- (BOOL)installFile:(NSString*)file;

// discard any cached data, forcing a re-load from disk.
- (void)flush;

@end

NS_ASSUME_NONNULL_END
