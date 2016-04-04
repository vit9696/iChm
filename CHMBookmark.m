// 
//  CHMBookmark.m
//  ichm
//
//  Created by Robin Lu on 8/11/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "CHMBookmark.h"

#import "CHMFile.h"
#import "CHMTag.h"

@implementation CHMBookmark 

@dynamic url;
@dynamic title;
@dynamic createdAt;
@dynamic file;
@dynamic tags;

- (NSString*)tagsString
{
	NSMutableString *str = [[[NSMutableString alloc] initWithString:@""] autorelease];
	for (CHMTag * tag in self.tags) {
		[str appendFormat:@"%@, ", tag.tag];
	}
	if ([str length] > 2)
	{
		NSRange range = {[str length] - 2, 2};
		[str deleteCharactersInRange:range];
	}
	return str;
}

- (void)setTagsString:(NSString*)tags
{
	if (!tags || [tags length] == 0)
		return;
	NSManagedObjectContext*context = [self managedObjectContext];
	
	NSArray* taglist = [tags componentsSeparatedByString:@","];
	NSMutableSet *set = [[NSMutableSet alloc] init];
	for (NSString* tag in taglist) {
		NSString* trimmed = [tag  stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if ( [trimmed length] > 0 )
		{
			CHMTag *tag = [CHMTag getTagByString:trimmed OnCreate:YES withContext:context];
			if ( ![self.tags containsObject:tag] )
				[set addObject:tag];
		}
	}
	if ([set count] != 0)
		[self addTags:set];
	[set release];
}

+ (CHMBookmark *)bookmarkByURL:(NSString*)url withContext:(NSManagedObjectContext*)context
{
	if (!url)
		return nil;
	
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	NSEntityDescription *bookmarkEntity = [NSEntityDescription
										   entityForName:@"Bookmark" inManagedObjectContext:context];
	[request setEntity:bookmarkEntity];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:
							  @"url == %@", url];
	[request setPredicate:predicate];
	NSError *error = nil;
	NSArray *array = [context executeFetchRequest:request error:&error];
	if (array == nil)
	{
		NSLog(@"Cannot fetch bookmark info: %@", error);
		return nil;
	}
	if ([array count] == 0)
	{
		return nil;
	}
	return [array objectAtIndex:0];	
}

@end
