//
//  SoftwareList
//
//  Manage the crazy MAME software list XML files for MAME4iOS
//
//  Created by ToddLa on 4/1/21.
//

#import <Foundation/Foundation.h>

// keys used in a software list xml
#define kSoftwareListName           @"name"
#define kSoftwareListParent         @"cloneof"
#define kSoftwareListYear           @"year"
#define kSoftwareListDescription    @"description"
#define kSoftwareListPublisher      @"publisher"

NS_ASSUME_NONNULL_BEGIN

@interface SoftwareList : NSObject

- (instancetype)initWithPath:(NSString*)root;

// get names of all software lists
- (NSArray<NSString*>*)getSoftwareListNames;

// get software list by name, filtered to only Available
- (NSArray<NSDictionary*>*)getSoftwareList:(NSString*)name;

// get games for a system, filtered to only Available
- (NSArray<NSDictionary*>*)getGamesForSystem:(NSDictionary*)system;

// get name of software list for a romset, used to know where to install.
- (nullable NSString*)getSoftwareListNameForRomset:(NSString*)path named:(NSString*)name;

// if this a merged romset, extract clones as empty zip files so they show up as Available
- (BOOL)extractClones:(NSString*)path;

// discard any cached data, forcing a re-load from disk.
- (void)reload;

@end

NS_ASSUME_NONNULL_END
