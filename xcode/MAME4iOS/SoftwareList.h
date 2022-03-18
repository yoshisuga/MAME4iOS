//
//  SoftwareList
//
//  Manage the crazy MAME software list XML files for MAME4iOS
//
//  Created by ToddLa on 4/1/21.
//

#import <Foundation/Foundation.h>
#import "GameInfo.h"

// keys used in a software list xml
#define kSoftwareListName           @"name"
#define kSoftwareListParent         @"cloneof"
#define kSoftwareListYear           @"year"
#define kSoftwareListDescription    @"description"
#define kSoftwareListPublisher      @"publisher"

NS_ASSUME_NONNULL_BEGIN

@interface SoftwareList : NSObject

// singleton, uses the document root
@property (class, readonly, strong) SoftwareList* sharedInstance NS_SWIFT_NAME(shared);

- (instancetype)initWithPath:(NSString*)root;

// get names of all software lists
- (NSArray<NSString*>*)getSoftwareListNames;

// get software list description
- (nullable NSString*)getSoftwareListDescription:(NSString*)name;

// get software list by name, filtered to only Available, first item has the description for the list itself.
- (NSArray<NSDictionary<NSString*,NSString*>*>*)getSoftwareList:(NSString*)name;

// get games for a system, filtered to only Available
- (NSArray<GameInfoDictionary*>*)getGamesForSystem:(GameInfoDictionary*)system;

// get name of software list for a romset, used to know where to install.
- (nullable NSString*)getSoftwareListNameForRomset:(NSString*)path named:(NSString*)name;

// if this a merged romset, extract clones as empty zip files so they show up as Available
- (BOOL)extractClones:(NSString*)path;

// try to find metadata for this software file.
- (BOOL)installSoftware:(NSString*)path;

// discard any cached data, forcing a re-load from disk.
- (void)reload;

@end

NS_ASSUME_NONNULL_END
