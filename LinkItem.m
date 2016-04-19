//
//  LinkItem.m
//  ichm
//
//  Created by Mark Douma on 4/19/2016.
//  Copyright © 2016 Mark Douma LLC. All rights reserved.
//

#import "LinkItem.h"

@implementation LinkItem
@synthesize pageID;

- (id)init
{
	if ((self = [super init])) {
		_children = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) dealloc
{
	[_children release];
	[_path release];
	[_name release];
	[super dealloc];
}

- (id)initWithName:(NSString *)name Path:(NSString *)path
{
	if ((self = [super init])) {
		_name = [name retain];
		_path = [path retain];
	}
	return self;
}

- (void)setName:(NSString *)name
{
	[name retain];
	[_name release];
	_name = name;
}

- (void)setPath:(NSString *)path
{
	[path retain];
	[_path release];
	_path = path;
}

- (void)setPageID:(NSUInteger)pid
{
	pageID = pid;
}

- (NSInteger)numberOfChildren
{
	return _children ? [_children count] : 0;
}

- (LinkItem *)childAtIndex:(NSInteger)n
{
	return [_children objectAtIndex:n];
}

- (NSString *)name
{
	return _name;
}

- (NSString *)uppercaseName
{
	return [_name uppercaseString];
}

- (NSString *)path
{
	return _path;
}

- (NSMutableArray*)children
{
	return _children;
}

- (void)appendChild:(LinkItem *)item
{
	if(!_children)
		_children = [[NSMutableArray alloc] init];
	[_children addObject:item];
}

- (LinkItem*)find_by_path:(NSString *)path withStack:(NSMutableArray*)stack
{
	if ([_path isEqualToString:path])
		return self;
	
	if(!_children)
		return nil;
	
	for (LinkItem* item in _children) {
		LinkItem * rslt = [item find_by_path:path withStack:stack];
		if (rslt != nil)
		{
			if(stack)
				[stack addObject:self];
			return rslt;
		}
	}
	
	return nil;
}

- (void)enumerateItemsWithSEL:(SEL)selector ForTarget:(id)target
{
	if (![_path isEqualToString:@"/"])
		[target performSelector:selector withObject:self];
		
	for (LinkItem* item in _children)
	{
		[item enumerateItemsWithSEL:selector ForTarget:target];
	}
}

- (void)sort
{
	NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"uppercaseName" ascending:YES];
	NSMutableArray * sda = [[NSMutableArray alloc] init];
	[sda addObject:sd];
	[_children sortUsingDescriptors:sda];
	[sda release];
	[sd release];	
}

- (void)purge
{
	NSMutableIndexSet *set = [[NSMutableIndexSet alloc] init];
	for (LinkItem * item in _children) {
		if ([item name] == nil && [item path] == nil && [item numberOfChildren] == 0)
			[set addIndex:[_children indexOfObject:item]];
		else
			[item purge];
	}
	
	[_children removeObjectsAtIndexes:set];
	[set release];
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"{\n\tname:%@\n\tpath:%@\n\tchildren:%@\n}", _name, _path, _children];
}
@end



@implementation ScoredLinkItem

@synthesize relScore;

- (void)sort
{
	NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"relScore" ascending:NO];
	NSMutableArray * sda = [[NSMutableArray alloc] init];
	[sda addObject:sd];
	[_children sortUsingDescriptors:sda];
	[sda release];
	[sd release];
}

- (id)initWithName:(NSString *)name Path:(NSString *)path Score:(float)score
{
	if ((self = [super initWithName:name Path:path])) {
		relScore = score;
	}
	return self;
}

@end

