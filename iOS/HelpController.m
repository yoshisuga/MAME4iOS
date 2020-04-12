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
#import "Globals.h"

@implementation HelpController {
    UIWebView *aWebView;
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
        
    aWebView =[ [ UIWebView alloc ] initWithFrame: view.frame];
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
    aWebView.delegate = self;
    [self loadHTML:html_name];
    self.title = html_title;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [aWebView stopLoading];
    aWebView.delegate = nil;
}

-(BOOL) webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)type {
    if ( type == UIWebViewNavigationTypeLinkClicked && !request.URL.isFileURL) {
        [[UIApplication sharedApplication] openURL:request.URL options:@{} completionHandler:nil];
        return NO;
    }
    
    return YES;
}

static NSString* dark_mode_style =
@"<style>\n\
@media (prefers-color-scheme: dark) {\n\
    html {background-color: black; color: white;}\n\
    table tbody tr:nth-child(2n) {background-color: #333333;}\n\
    table tbody tr:nth-child(2n-1) {background-color: #222222;}\n\
    a:link, a:visited {color: dodgerblue;}\n\
    img {opacity: .75;}\n\
}\n\
</style>\n";

- (void)loadHTML:(NSString*)name {
    
    NSString *HTMLData = [[NSString alloc] initWithContentsOfFile:[NSString stringWithUTF8String:get_resource_path([name UTF8String])] encoding:NSUTF8StringEncoding error:nil];
    
    // hack in our dark-mode style sheet at the end of the <head></head> only if the HTML does not have a inline style for dark mode already.
    if (aWebView.backgroundColor == UIColor.blackColor && !([HTMLData containsString:@"<style"] && [HTMLData containsString:@"prefers-color-scheme"])) {
        HTMLData = [HTMLData stringByReplacingOccurrencesOfString:@"</head>" withString:[dark_mode_style stringByAppendingString:@"</head>"]];
    }
    
    NSURL *aURL = [NSURL fileURLWithPath:[NSString stringWithUTF8String:get_resource_path("")]];
    
    [aWebView loadHTMLString:HTMLData baseURL: aURL];
}

@end
