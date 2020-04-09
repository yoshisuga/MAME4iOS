//
//  FileItemProvider.m
//  MAME4iOS 64-bit
//
//  Created by Todd Laney on 3/12/20.
//  Copyright © 2020 Seleuco. All rights reserved.
//

#import "FileItemProvider.h"
#import "Alert.h"
#import <MobileCoreServices/MobileCoreServices.h>

@implementation FileItemProvider {
    NSString* _title;
    NSString* _typeIdentifier;
    __weak UIActivityViewController* _activityViewController;
    UIAlertController* _progressAlert;
    NSURL* _tempURL;
    FileItemProviderSaveHandler _saveHandler;
    double _progress;
    NSTimeInterval _progressUpdateTime;
}

// create a file based, on-demand UIActivityItemProvider
// the data will not be created until asked for.
-(instancetype)initWithTitle:(NSString*)title typeIdentifier:(NSString*)typeIdentifier saveHandler:(FileItemProviderSaveHandler)saveHandler {

    _title = title;
    _typeIdentifier = typeIdentifier;
    _saveHandler = saveHandler;
    
    // create a temporary URL using the title as the name, this is the only way I know to give the exported file a title.
    NSString* temp = NSTemporaryDirectory();
    temp = [temp stringByAppendingPathComponent:[[NSUUID UUID] UUIDString]];
    [[NSFileManager defaultManager] createDirectoryAtPath:temp withIntermediateDirectories:YES attributes:nil error:nil];
    temp = [temp stringByAppendingPathComponent:title];

    if ([typeIdentifier length] > 0 && [[temp pathExtension] length] == 0) {
        NSString* ext = CFBridgingRelease(UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)typeIdentifier, kUTTagClassFilenameExtension));
        temp = [temp stringByAppendingPathExtension:ext];
    }
    
    [[NSFileManager defaultManager] createFileAtPath:temp contents:nil attributes:nil];
    
    _tempURL = [NSURL fileURLWithPath:temp];
    return [super initWithPlaceholderItem:_tempURL];
}

-(void)dealloc {
    // delete our temp file, we are all done with it.
    [[NSFileManager defaultManager] removeItemAtURL:[_tempURL URLByDeletingLastPathComponent] error:nil];
}

// called on secondary thread when user selects an activity. go ahead and call handler to create the file
- (id)item {
    
    BOOL result = _saveHandler(_tempURL, ^BOOL(double progress) {
        self->_progress = progress;
        NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
        if (now - self->_progressUpdateTime > 2.5) {
            self->_progressUpdateTime = now;
            [self performSelectorOnMainThread:@selector(updateProgress) withObject:nil waitUntilDone:NO];
        }
        return [self isCancelled];
    });
    _progress = 1.0;
    [self performSelectorOnMainThread:@selector(updateProgress) withObject:nil waitUntilDone:NO];
    
    if (!result) {
        NSLog(@"ERROR WRITING: %@", _tempURL);
    }
    
    return (result && ![self isCancelled]) ? _tempURL : nil;
}

#pragma mark Progress

-(void)updateProgress {
    double progress = MAX(0.0, MIN(1.0, _progress));
    
    if (_progressAlert == nil && progress < 1.0 && ![self isCancelled]) {
        if (_activityViewController == nil)
            return;
        _progressAlert = [UIAlertController alertControllerWithTitle:_title message:nil preferredStyle:UIAlertControllerStyleAlert];
        [_progressAlert setProgress:progress];
        [_progressAlert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [self cancel];
        }]];
        [_activityViewController.topViewController presentViewController:_progressAlert animated:NO completion:nil];
        return;
    }
    
    if (_progressAlert == nil)
        return;
    
    [_progressAlert setProgress:progress];

    if (progress >= 1.0) {
        [_progressAlert.presentingViewController dismissViewControllerAnimated:NO completion:nil];
        _progressAlert = nil;
    }
}

#pragma mark UIActivityItemSource

- (NSString *)activityViewController:(UIActivityViewController *)activityViewController subjectForActivityType:(nullable UIActivityType)activityType {
    return _title;
}

- (NSString *)activityViewController:(UIActivityViewController *)activityViewController dataTypeIdentifierForActivityType:(nullable UIActivityType)activityType {
    _activityViewController = activityViewController;   // save this for later to show progress dialog
    return _typeIdentifier;
}

@end
