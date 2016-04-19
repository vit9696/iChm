//
//  LinkItem.m
//  ichm
//
//  Created by Mark Douma on 4/19/2016.
//  Copyright © 2016 Mark Douma LLC. All rights reserved.
//

#import "LinkItem.h"

@implementation LinkItem
@synthesize name;
@synthesize path;
@synthesize children;
@synthesize pageID;

@dynamic uppercaseName;

- (id)init {
	if ((self = [super init])) {
		children = [[NSMutableArray alloc] init];
	}
	return self;
}

- (id)initWithName:(NSString *)aName path:(NSString *)aPath {
	if ((self = [super init])) {
		name = [aName retain];
		path = [aPath retain];
	}
	return self;
}

- (void)dealloc {
	[children release];
	[path release];
	[name release];
	[super dealloc];
}


- (NSInteger)numberOfChildren {
	return children ? [children count] : 0;
}

- (LinkItem *)childAtIndex:(NSInteger)n {
	return [children objectAtIndex:n];
}

- (NSString *)uppercaseName {
	return [name uppercaseString];
}


- (void)appendChild:(LinkItem *)item {
	if (children == nil) children = [[NSMutableArray alloc] init];
	[children addObject:item];
}


- (LinkItem*)itemForPath:(NSString *)aPath withStack:(NSMutableArray*)stack {
	if ([path isEqualToString:aPath])
		return self;
	
	if (!children)
		return nil;
	
	for (LinkItem* item in children) {
		LinkItem * rslt = [item itemForPath:aPath withStack:stack];
		if (rslt != nil) {
			if(stack)
				[stack addObject:self];
			return rslt;
		}
	}
	
	return nil;
}

- (void)enumerateItemsWithSelector:(SEL)selector forTarget:(id)target {
	if (![path isEqualToString:@"/"])
		[target performSelector:selector withObject:self];
		
	for (LinkItem* item in children) {
		[item enumerateItemsWithSelector:selector forTarget:target];
	}
}

- (void)sort {
	NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"uppercaseName" ascending:YES];
	NSMutableArray * sda = [[NSMutableArray alloc] init];
	[sda addObject:sd];
	[children sortUsingDescriptors:sda];
	[sda release];
	[sd release];
}

- (void)purge {
	NSMutableIndexSet *set = [[NSMutableIndexSet alloc] init];
	for (LinkItem * item in children) {
		if ([item name] == nil && [item path] == nil && [item numberOfChildren] == 0)
			[set addIndex:[children indexOfObject:item]];
		else
			[item purge];
	}
	
	[children removeObjectsAtIndexes:set];
	[set release];
}


-(NSString *)description {
    return [NSString stringWithFormat:@"{\n\tname:%@\n\tpath:%@\n\tchildren:%@\n}", name, path, children];
}

@end



@implementation ScoredLinkItem

@synthesize relScore;

- (void)sort {
	NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"relScore" ascending:NO];
	NSMutableArray * sda = [[NSMutableArray alloc] init];
	[sda addObject:sd];
	[children sortUsingDescriptors:sda];
	[sda release];
	[sd release];
}

- (id)initWithName:(NSString *)aName path:(NSString *)aPath score:(CGFloat)score {
	if ((self = [super initWithName:aName path:aPath])) {
		relScore = score;
	}
	return self;
}

@end

