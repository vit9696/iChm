// 
//  CHMFile.m
//  ichm
//
//  Created by Robin Lu on 8/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "CHMFile.h"

#import "CHMBookmark.h"

@implementation CHMFile 

@dynamic path;
@dynamic bookmarks;
@dynamic title;
@dynamic isValid;

+ (CHMFile *)fileByPath:(NSString*)path withContext:(NSManagedObjectContext*)context
{
	if (!path)
		return nil;
	
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	NSEntityDescription *fileEntity = [NSEntityDescription
									   entityForName:@"File" inManagedObjectContext:context];
	[request setEntity:fileEntity];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:
							  @"path == %@", path];
	[request setPredicate:predicate];
	NSError *error = nil;
	NSArray *array = [context executeFetchRequest:request error:&error];
	if (array == nil)
	{
		NSLog(@"Cannot fetch file info: %@", error);
		return nil;
	}
	if ([array count] == 0)
	{
		NSLog(@"Cannot fetch file with path: %@", path);
		return nil;
	}
	return [array objectAtIndex:0];
}

+ (NSArray*)allFileswithContext:(NSManagedObjectContext*)context
{
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	NSEntityDescription *tagEntity = [NSEntityDescription
									  entityForName:@"File" inManagedObjectContext:context];
	[request setEntity:tagEntity];
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]
										initWithKey:@"title" ascending:YES];
	[request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	[sortDescriptor release];
	NSError *error = nil;
	NSArray *array = [context executeFetchRequest:request error:&error];
	if (array == nil)
	{
		NSLog(@"Cannot fetch file info: %@", error);
	}
	return array;	
}

+ (void)purgeWithContext:(NSManagedObjectContext*)context
{
	NSArray * files = [CHMFile allFileswithContext:context];
	for ( CHMFile * file in files )
	{
		if ([[file bookmarks] count] == 0)
			[context deleteObject:file];
		else
		{
			BOOL isDirectory;
			BOOL isValid = [[NSFileManager defaultManager] fileExistsAtPath:[file path] isDirectory:&isDirectory] && !isDirectory ;
			[file setIsValid:[NSNumber numberWithBool:isValid]];
		}
	}
}
@end
