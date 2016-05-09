//
//  CHMAppController.m
//  ichm
//
//  Created by Robin Lu on 7/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "CHMAppController.h"
#import <CHMKit/CHMKit.h>
#import "BookmarkController.h"


#define MD_DEBUG 0

#if MD_DEBUG
#define MDLog(...) NSLog(__VA_ARGS__)
#else
#define MDLog(...)
#endif


@implementation CHMAppController

+ (void)initialize {
    [NSURLProtocol registerClass:[ITSSProtocol class]];
}


- (void)awakeFromNib {
	MDLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
	NSString *path = [[NSBundle mainBundle] pathForResource:@"textEncodings" ofType:@"plist"];
	
	if (path == nil) {
		NSBeep();
		NSLog(@"[%@ %@] failed to find textEncodings.plist!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		return;
	}
	
	NSArray *plist = [NSArray arrayWithContentsOfFile:path];
	if (plist == nil) {
		NSBeep();
		NSLog(@"[%@ %@] failed to load textEncodings.plist!", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		return;
	}
	
	NSUInteger sectionCount = plist.count;
	NSUInteger sectionIndex = 0;
	
	NSUInteger itemIndex = 0;
	
	for (NSArray *section in plist) {
		
		itemIndex = 0;
		
		for (NSDictionary *item in section) {
			NSString *title = [item objectForKey:@"title"];
			NSString *encodingName = [item objectForKey:@"name"];
			
			MDLog(@"[%@ %@] encodingName == \"%@\"", NSStringFromClass([self class]), NSStringFromSelector(_cmd), encodingName);
			
			CFStringEncoding cfStringEncoding = kCFStringEncodingInvalidId;
			NSStringEncoding nsStringEncoding = 0;
			
			if (encodingName.length) {
				cfStringEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)encodingName);
				
				if (cfStringEncoding == kCFStringEncodingInvalidId) {
					NSLog(@"[%@ %@] *** WARNING: CFStringConvertIANACharSetNameToEncoding() returned kCFStringEncodingInvalidId for \"%@\"", NSStringFromClass([self class]), NSStringFromSelector(_cmd), encodingName);
					
				} else {
					MDLog(@"cfStringEncoding == %lu", (unsigned long)cfStringEncoding);
					MDLog(@"cfStringEncoding == \"%@\"", CFStringGetNameOfEncoding(cfStringEncoding));
					
				}
				
				nsStringEncoding = CFStringConvertEncodingToNSStringEncoding(cfStringEncoding);
				MDLog(@"nsStringEncoding == %lu", (unsigned long)nsStringEncoding);
				MDLog(@"locDescrp == %@", [NSString localizedNameOfStringEncoding:nsStringEncoding]);
				
			}
			
			if (cfStringEncoding != kCFStringEncodingInvalidId || encodingName.length == 0) {
				NSMenuItem *newItem = [[[NSMenuItem alloc] init] autorelease];
				[newItem setTitle:title];
				[newItem setAction:@selector(changeEncoding:)];
				[newItem setTarget:nil];
				[newItem setTag:(encodingName.length == 0 ? 0 : nsStringEncoding)];
				if (encodingName.length) [newItem setRepresentedObject:encodingName];
				
				[textEncodingMenu addItem:newItem];
				itemIndex++;
			}
		}
		if (itemIndex) sectionIndex++;
		if (sectionIndex < sectionCount) {
			[textEncodingMenu addItem:[NSMenuItem separatorItem]];
		}
	}
}


- (void)applicationWillTerminate:(NSNotification *)notification {
    [NSURLProtocol unregisterClass:[ITSSProtocol class]];
}

#pragma mark links
- (IBAction)donate:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=iamawalrus%40gmail%2ecom&item_name=iCHM&amount=4%2e99&no_shipping=0&no_note=1&tax=0&currency_code=USD&lc=US&bn=PP%2dDonationsBF&charset=UTF%2d8"]];
}


- (IBAction)homepage:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.robinlu.com/blog/ichm"]];
}

#pragma mark bookmark
- (BookmarkController *)bookmarkController {
	if (bookmarkController == nil) bookmarkController = [[BookmarkController alloc] init];
	return bookmarkController;
}

@end


