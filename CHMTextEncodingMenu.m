//
//  CHMTextEncodingMenu.m
//  ichm
//
//  Created by Robin Lu on 8/1/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "CHMTextEncodingMenu.h"
#import "CHMDocument.h"

@implementation CHMTextEncodingMenu
- (id)init
{
	if ((self = [super init])) {
		initialized = NO;
		encodingNames = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) dealloc
{
	[encodingNames release];
	[super dealloc];
}

- (void)menuNeedsUpdate:(NSMenu *)menu
{
	if(!initialized)
		[self initEncodingMenu];
	
	NSDocumentController * controller = [NSDocumentController sharedDocumentController];
	CHMDocument *doc = [controller currentDocument];
	[doc setupEncodingMenu];
}

- (void)initEncodingMenu
{
	if(initialized)
		return;
	
	NSString *path = [[NSBundle mainBundle] pathForResource:@"textencoding" ofType:@"plist"];
	
	NSArray *plist = [NSArray arrayWithContentsOfFile:path];
	if(!plist)
	{
		NSLog(@"[%@ %@] failed to load textencoding.plist", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		return;
	}
	
	NSMenu * submenu = [menu submenu];
	
	NSUInteger sectionCount = plist.count;
	NSUInteger sectionIndex = 0;
	
	for (NSArray *section in plist) {
		
		for (NSDictionary *item in section) {
			NSString *title = [item objectForKey:@"title"];
			NSMenuItem *newitem = [[[NSMenuItem alloc] init] autorelease];
			[newitem setTitle:title];
			NSInteger tag = [encodingNames count];
			NSString *name = [item objectForKey:@"name"];
			[encodingNames addObject:name];
			[newitem setTag:tag];
			
			[submenu addItem:newitem];
		}
		sectionIndex++;
		if (sectionIndex < sectionCount) {
			[submenu addItem:[NSMenuItem separatorItem]];
		}
	}
	initialized = YES;
}

- (NSString*)getEncodingByTag:(NSInteger)tag
{
	if(0==tag)
		return nil;
	return [encodingNames objectAtIndex:tag];
}
@end
