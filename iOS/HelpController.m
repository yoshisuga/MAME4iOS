/*
 * This file is part of MAME4iOS.
 *
 * Copyright (C) 2013 David Valdeita (Seleuco)
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see <http://www.gnu.org/licenses>.
 *
 * Linking MAME4iOS statically or dynamically with other modules is
 * making a combined work based on MAME4iOS. Thus, the terms and
 * conditions of the GNU General Public License cover the whole
 * combination.
 *
 * In addition, as a special exception, the copyright holders of MAME4iOS
 * give you permission to combine MAME4iOS with free software programs
 * or libraries that are released under the GNU LGPL and with code included
 * in the standard release of MAME under the MAME License (or modified
 * versions of such code, with unchanged license). You may copy and
 * distribute such a system following the terms of the GNU GPL for MAME4iOS
 * and the licenses of the other code concerned, provided that you include
 * the source code of that other code when and as the GNU GPL requires
 * distribution of source code.
 *
 * Note that people who make modified versions of MAME4iOS are not
 * obligated to grant this special exception for their modified versions; it
 * is their choice whether to do so. The GNU General Public License
 * gives permission to release a modified version without this exception;
 * this exception also makes it possible to release a modified version
 * which carries forward this exception.
 *
 * MAME4iOS is dual-licensed: Alternatively, you can license MAME4iOS
 * under a MAME license, as set out in http://mamedev.org/
 */

#import "HelpController.h"
#import <WebKit/WebKit.h>
#import "Globals.h"

@implementation HelpController {
    WKWebView *aWebView;
    NSString* html_name;
    NSString* html_title;
}

- (id)initWithName:(NSString*)name title:(NSString*)title {

    if (self = [super init]) {
        aWebView = nil;
        html_name = name;
        html_title = title;
    }

    return self;
}


- (id)init {
    return [self initWithName:@"help.html" title:@"Help"];
}

- (void)loadView {
       
    UIView *view= [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.view = view;
    
    self.title = @"Help";
    self.view.backgroundColor = [UIColor whiteColor];
    self.view.autoresizesSubviews = TRUE;
        
    aWebView =[[WKWebView alloc] initWithFrame:view.frame];
    aWebView.backgroundColor = UIColor.whiteColor;
    if (@available(iOS 12.0, *)) {
        if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            aWebView.backgroundColor = UIColor.blackColor;
            aWebView.opaque = NO;
        }
    }
    aWebView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    
    [ self.view addSubview: aWebView ];
}

-(void)viewWillAppear:(BOOL)animated
{
    aWebView.navigationDelegate = (id)self;
    [self loadHTML:html_name];
    self.title = html_title;
}

-(void)viewDidAppear:(BOOL)animated {
    if (aWebView.scrollView.contentOffset.y == 0.0 && self.navigationController != nil)
        [aWebView.scrollView setContentOffset:CGPointMake(0, -aWebView.scrollView.adjustedContentInset.top) animated:animated];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [aWebView stopLoading];
    aWebView.navigationDelegate = nil;
}

#pragma MARK - WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    
    // we only care about user clicked links
    if (navigationAction.request.URL != nil && ![navigationAction.request.URL isFileURL] && navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        [[UIApplication sharedApplication] openURL:navigationAction.request.URL options:@{} completionHandler:nil];
        return decisionHandler(WKNavigationActionPolicyCancel);
    }
    
    return decisionHandler(WKNavigationActionPolicyAllow);
}

#pragma MARK - loadHTML

static NSString* html_viewport =
@"<meta name=\"viewport\" content=\"width=device-width, shrink-to-fit=YES\">";

static NSString* html_custom_style =
@"<style>\n\
body {font-family:-apple-system,BlinkMacSystemFont,Segoe UI,Helvetica,Arial,sans-serif,Apple Color Emoji,Segoe UI Emoji; line-height:1.5}\n\
code {background-color:lightgray; width:100%; overflow-x:scroll; padding:.2em .4em; margin:0; border-radius:6px; font-size:85%; font-family:SFMono-Regular,monospace}\n\
@media (prefers-color-scheme: dark) {\n\
    html {background-color: #1e1e1e; color: white;}\n\
    table tbody tr:nth-child(2n) {background-color: #323232;}\n\
    table tbody tr:nth-child(2n-1) {background-color: #1e1e1e;}\n\
    a:link, a:visited {color: dodgerblue;}\n\
    img {opacity: .75;}\n\
    code {background-color:#404040;}\n\
}\n\
</style>\n";

- (void)loadHTML:(NSString*)name {
    
    NSString *HTMLData = [[NSString alloc] initWithContentsOfFile:[NSString stringWithUTF8String:get_resource_path([name UTF8String])] encoding:NSUTF8StringEncoding error:nil];
    
    // replace special tags in HTML....
    //
    //      $(APP_VERSION) - application version
    //      $(APP_DATE)    - file date of Info.plist, this ususally is the built-on date.
    //
    NSString* version = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleVersion"];
    HTMLData = [HTMLData stringByReplacingOccurrencesOfString:@"$(APP_VERSION)" withString:version];

    // this last date Info.plist was modifed, if you do a clean build, or change the version, it is the build date.
#if TARGET_OS_MACCATALYST
    NSString *path = [[NSBundle mainBundle] pathForResource: @"../Info" ofType: @"plist"];
#else
    NSString *path = [[NSBundle mainBundle] pathForResource: @"Info" ofType: @"plist"];
#endif
    NSDate* date = [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] fileModificationDate];
    NSString* app_date = [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterNoStyle];
    HTMLData = [HTMLData stringByReplacingOccurrencesOfString:@"$(APP_DATE)" withString:app_date];
    
    // hack in our style sheet at the end of the <head></head> only if the HTML does not have a dark-mode compatible inline style already.
    if (!([HTMLData containsString:@"<style"] && [HTMLData containsString:@"prefers-color-scheme"])) {
        HTMLData = [HTMLData stringByReplacingOccurrencesOfString:@"</head>" withString:[html_custom_style stringByAppendingString:@"</head>"]];
    }
    
    // hack in a viewport at the end of the <head></head> only if the HTML does not have one.
    if (![HTMLData containsString:@"<meta name=\"viewport\""]) {
        HTMLData = [HTMLData stringByReplacingOccurrencesOfString:@"</head>" withString:[html_viewport stringByAppendingString:@"</head>"]];
    }
    
    NSURL *aURL = [NSURL fileURLWithPath:[NSString stringWithUTF8String:get_resource_path("")]];
    
    [aWebView loadHTMLString:HTMLData baseURL: aURL];
}

@end
