//
//  XmlFile.h
//  Wombat
//
//  Created by ToddLa on 4/4/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XmlFile : NSObject

+ (NSDictionary *)dictionaryWithData:(NSData *)data error:(NSError **)errorPointer;
+ (NSDictionary *)dictionaryWithURL:(NSURL *)url error:(NSError **)errorPointer;
+ (NSDictionary *)dictionaryWithPath:(NSString *)path error:(NSError **)errorPointer;

+ (void)loadUrl:(NSURL*)url completionHandler:(void (^)(NSDictionary* dict, NSError* error)) handler;

@end

NS_ASSUME_NONNULL_END
