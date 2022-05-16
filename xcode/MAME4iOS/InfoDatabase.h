//
//  InfoDatabase.h
//  MAME4iOS
//
//  Created by Todd Laney on 4/24/20.
//  Copyright © 2020 Seleuco. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

//
// InfoDatabase
//
// class to read a text file based info databases used by MAME and MAME frontends.
//
// the database is a UTF8 text file
//      $info=key1,key2,key3,....
//      $bio, $mame, ....
//      <text info>
//      $end
//
//  the text info is just a arbitary blob of text, with a markdown *like* syntax.
//
@interface InfoDatabase : NSObject

// open file and create a index.
- (instancetype)initWithPath:(NSString*)path;

// return all the keys found in the file.
- (NSArray<NSString*>*)allKeys;

// return TRUE if the key exists in the file without loading the text data.
- (BOOL)boolForKey:(NSString*)key;

// return non-zero if key exits in the file.
- (uint64_t)intForKey:(NSString*)key;

// load and return the raw text data for the key
- (nullable NSString*)stringForKey:(NSString*)key;

// load and return the text data with basic formating applied.
- (nullable NSAttributedString*)attributedStringForKey:(NSString*)key attributes:(nullable NSDictionary<UIFontTextStyle, NSDictionary<NSAttributedStringKey, id> *> *)attrs;

@end

NS_ASSUME_NONNULL_END
