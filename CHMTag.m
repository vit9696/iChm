// 
//  CHMTag.m
//  ichm
//
//  Created by Robin Lu on 8/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "CHMTag.h"

#import "CHMBookmark.h"

@implementation CHMTag 

@dynamic tag;
@dynamic bookmarks;

+ (CHMTag*)getTagByString:(NSString*)tagstr OnCreate:(BOOL)shouldCreate withContext:(NSManagedObjectContext*)context
{
	if (!tagstr)
		return nil;
	
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	NSEntityDescription *tagEntity = [NSEntityDescription
									   entityForName:@"Tag" inManagedObjectContext:context];
	[request setEntity:tagEntity];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:
							  @"tag == %@", tagstr];
	[request setPredicate:predicate];
	NSError *error = nil;
	NSArray *array = [context executeFetchRequest:request error:&error];
	if (array == nil)
	{
		NSLog(@"Cannot fetch tag info: %@", error);
		return nil;
	}
	if ([array count] != 0)
		return [array objectAtIndex:0];;

	if (shouldCreate)
	{
		CHMTag *tag = [NSEntityDescription
			insertNewObjectForEntityForName:@"Tag"
			inManagedObjectContext:context];
		tag.tag = tagstr;
		if ( ![context save:&error] )
		{
			NSLog(@"Cannot create tag: %@", error);
			return nil;
		}
		return tag;
	}
	return nil;
}

+ (NSArray*)allTagswithContext:(NSManagedObjectContext*)context
{
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	NSEntityDescription *tagEntity = [NSEntityDescription
									  entityForName:@"Tag" inManagedObjectContext:context];
	[request setEntity:tagEntity];
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]
										initWithKey:@"tag" ascending:YES];
	[request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	[sortDescriptor release];
	NSError *error = nil;
	NSArray *array = [context executeFetchRequest:request error:&error];
	if (array == nil)
	{
		NSLog(@"Cannot fetch tag info: %@", error);
	}
	return array;
}

@end