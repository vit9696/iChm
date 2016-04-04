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
	initialized = NO;
	encodingNames = [[NSMutableArray alloc] init];
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
	NSData *plistData;
	NSString *error;
	NSPropertyListFormat format;
	NSArray * plist;
	plistData = [NSData dataWithContentsOfFile:path];
	
	plist = [NSPropertyListSerialization propertyListFromData:plistData
											 mutabilityOption:NSPropertyListImmutable
													   format:&format
											 errorDescription:&error];
	if(!plist)
	{
		NSLog(@"%@",error);
		[error release];
		return;
	}
	
	NSMenu * submenu = [menu submenu];
	NSInteger lastitem;
	for(NSArray *section in plist)
	{
		for(NSDictionary *item in section)
		{
			NSString *title = [item objectForKey:@"title"];
			NSMenuItem *newitem = [[NSMenuItem alloc] init];
			[newitem setTitle:title];
			int tag = [encodingNames count];
			NSString *name = [item objectForKey:@"name"];
			[encodingNames addObject:name];
			[newitem setTag:tag];
			[submenu addItem:newitem];
			[newitem autorelease];
		}
		NSMenuItem *seperator = [NSMenuItem separatorItem];
		[submenu addItem:seperator];
		lastitem = [submenu indexOfItem:seperator];
	}
	[submenu removeItemAtIndex:lastitem];
	initialized = YES;
}

- (NSString*)getEncodingByTag:(NSInteger)tag
{
	if(0==tag)
		return nil;
	return [encodingNames objectAtIndex:tag];
}
@end
