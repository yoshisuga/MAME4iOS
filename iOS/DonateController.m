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
 
#import "DonateController.h"
#import "Globals.h"
#import "EmulatorController.h"
#import "Alert.h"

@implementation DonateController

- (id)init {
    
    if (self = [super init]) {
        aWebView = nil;
    }
    
    return self;
}

- (void)loadView {
	
	UIView *view= [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.view = view;
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.title = @"Donate";
    
    aWebView = [ [ UIWebView alloc ] initWithFrame: self.view.frame];
    
    aWebView.scalesPageToFit = YES;
    
    aWebView.autoresizesSubviews = YES;
    aWebView.autoresizingMask=(UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
    
    [ self.view addSubview: aWebView ];
}

-(void)viewDidLoad{
    
    [self showAlertWithTitle:@"Thanks for your support!"
                     message:[NSString stringWithFormat: @"I am releasing everything for free, in keeping with the licensing MAME terms, which is free for non-commercial use only. This is strictly something I made because I wanted to play with it and have the skills to make it so. That said, if you are thinking on ways to support my development I suggest you to check my support page of other free works for the community."]];
}

- (void)viewWillAppear:(BOOL)animated{
    
    //set the web view delegates for the web view to be itself
    [aWebView setDelegate:self];
    
    //Set the URL to go to for your UIWebView
    NSString *urlAddress = @"https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=seleuco%2enicator%40gmail%2ecom&lc=US&item_name=Seleuco%20Nicator&item_number=ixxxx4all&no_note=0&currency_code=USD&bn=PP%2dDonationsBF%3abtn_donateCC_LG%2egif%3aNonHostedGuest";
    
    
    //Create a URL object.
    NSURL *url = [NSURL URLWithString:urlAddress];
    
    //URL Requst Object
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    
    
    //load the URL into the web view.
    [aWebView loadRequest:requestObj];
}

-(void)viewWillDisappear:(BOOL)animated{
    [aWebView stopLoading];
    [aWebView setDelegate:nil];
    
}

/////

- (void)webViewDidStartLoad:(UIWebView *)webView{
    
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{

   self.title = @"Wait... Loading!";
   return YES;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    self.title = @"Error";
    if(error!=nil && error.code != NSURLErrorCancelled)
    {
        [self showAlertWithTitle:@"Connection Failed!"
                         message:[NSString stringWithFormat:@"There is no internet connection. Connect to the internet and try again. Error:%@",[error localizedDescription]]];
	}
}

- (void)webViewDidFinishLoad:(UIWebView *)webView{
    
    if(webView!=nil)
    {
        if(webView.request!=nil)
            self.title = webView.request.URL.absoluteString;
    }
}

@end
