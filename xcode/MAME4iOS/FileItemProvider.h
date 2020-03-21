//
//  FileItemProvider.h
//  MAME4iOS 64-bit
//
//  Created by Todd Laney on 3/12/20.
//  Copyright © 2020 Seleuco. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef BOOL (^FileItemProviderProgressHandler)(double progress);   // return TRUE to cancel, FALSE for keep going
typedef BOOL (^FileItemProviderSaveHandler)(NSURL* url, FileItemProviderProgressHandler progressHandler); // return TRUE on success

@interface FileItemProvider : UIActivityItemProvider

-(instancetype)initWithTitle:(NSString*)title typeIdentifier:(NSString*)typeIdentifier saveHandler:(FileItemProviderSaveHandler)saveHandler;

@end

NS_ASSUME_NONNULL_END
