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

// get software list names
- (NSArray<NSString*>*)getSoftwareListNames;

// get software list
- (NSArray<NSDictionary*>*)getSoftwareList:(NSString*)name;

// get games for a system
- (NSArray<NSDictionary*>*)getGamesForSystem:(NSString*)system fromList:(NSString*)list;

// install a XML or ZIP file
- (BOOL)installFile:(NSString*)path;

// if this a merged romset, extract clones as empty zip files so they show up as Available
- (BOOL)extractClones:(NSString*)path;

// discard any cached data, forcing a re-load from disk.
- (void)reload;

// delete all software lists
- (void)reset;

@end

NS_ASSUME_NONNULL_END
