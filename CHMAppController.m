//
//  CHMAppController.m
//  ichm
//
//  Created by Robin Lu on 7/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "CHMAppController.h"
#import "ITSSProtocol.h"
#import "BookmarkController.h"

@implementation CHMAppController

@synthesize textEncodingMenu;

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    [NSURLProtocol registerClass:[ITSSProtocol class]];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    [NSURLProtocol unregisterClass:[ITSSProtocol class]];
}

#pragma mark links
- (IBAction)donate:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=iamawalrus%40gmail%2ecom&item_name=iCHM&amount=4%2e99&no_shipping=0&no_note=1&tax=0&currency_code=USD&lc=US&bn=PP%2dDonationsBF&charset=UTF%2d8"]];
}

- (IBAction)homepage:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.robinlu.com/blog/ichm"]];
}

#pragma mark bookmark
- (BookmarkController*) bookmarkController
{
	if(!bookmarkController)
	{
		bookmarkController = [[BookmarkController alloc] init];
	}
	
	return bookmarkController;
}
@end
