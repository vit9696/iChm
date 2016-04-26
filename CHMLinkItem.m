//
//  CHMLinkItem.m
//  ichm
//
//  Created by Mark Douma on 4/19/2016.
//  Copyright © 2016 Mark Douma LLC. All rights reserved.
//

#import "CHMLinkItem.h"

@implementation CHMLinkItem
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


- (NSUInteger)numberOfChildren {
	return children.count;
}

- (CHMLinkItem *)childAtIndex:(NSInteger)n {
	return [children objectAtIndex:n];
}

- (NSString *)uppercaseName {
	return [name uppercaseString];
}


- (void)appendChild:(CHMLinkItem *)item {
	if (children == nil) children = [[NSMutableArray alloc] init];
	[children addObject:item];
}


- (CHMLinkItem *)itemForPath:(NSString *)aPath withStack:(NSMutableArray *)stack {
	if ([path isEqualToString:aPath])
		return self;
	
	if (!children)
		return nil;
	
	for (CHMLinkItem* item in children) {
		CHMLinkItem * rslt = [item itemForPath:aPath withStack:stack];
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
		
	for (CHMLinkItem* item in children) {
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
	NSUInteger i = 0;
	for (CHMLinkItem *item in children) {
		if (item.name == nil && item.path == nil && item.numberOfChildren == 0)
			[set addIndex:i];
		else
			[item purge];
		
		i++;
	}
	
	[children removeObjectsAtIndexes:set];
	[set release];
}


-(NSString *)description {
//    return [NSString stringWithFormat:@"{\n\tname:%@\n\tpath:%@\n\tchildren:%@\n}", name, path, children];
	NSMutableString *description = [NSMutableString stringWithFormat:@"<%@> %@\r", NSStringFromClass([self class]), self.name];
	[description appendFormat:@"          path == %@\r\r", path];
	if (children.count)[description appendFormat:@"          children (%lu) == %@\r\r", (unsigned long)children.count, children];
	
	[description replaceOccurrencesOfString:@"\\n" withString:@"\r" options:0 range:NSMakeRange(0, description.length)];
	[description replaceOccurrencesOfString:@"\\\"" withString:@"          " options:0 range:NSMakeRange(0, description.length)];
	return description;
}

@end



@implementation CHMScoredLinkItem

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

