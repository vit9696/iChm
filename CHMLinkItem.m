//
//  CHMLinkItem.m
//  ichm
//
//  Created by Mark Douma on 4/19/2016.
//  Copyright © 2016 Mark Douma LLC. All rights reserved.
//

#import "CHMLinkItem.h"
#import "CHMKitPrivateInterfaces.h"


#define MD_DEBUG 0

#if MD_DEBUG
#define MDLog(...) NSLog(__VA_ARGS__)
#else
#define MDLog(...)
#endif



@implementation CHMLinkItem
@synthesize name;
@synthesize path;
@synthesize children;
@synthesize pageID;
@synthesize parent;
@synthesize container;
@dynamic uppercaseName;

- (id)init {
	if ((self = [super init])) {
		
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


- (NSArray *)children {
	return [[children copy] autorelease];
}


- (NSUInteger)numberOfChildren {
	return children.count;
}

- (CHMLinkItem *)childAtIndex:(NSUInteger)n {
	return [children objectAtIndex:n];
}

- (NSString *)uppercaseName {
	return [name uppercaseString];
}


- (void)appendChild:(CHMLinkItem *)item {
	if (children == nil) children = [[NSMutableArray alloc] init];
	[children addObject:item];
	item.parent = self;
}


- (NSArray *)ancestors {
	if (parent == nil) return nil;
	NSMutableArray *ancestors = [NSMutableArray array];
	[ancestors addObject:parent];
	NSArray *parentsAncestors = [parent ancestors];
	
	if (parentsAncestors.count) {
		[ancestors insertObjects:parentsAncestors atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, parentsAncestors.count)]];
	}
	return ancestors;
}


- (void)enumerateItemsWithSelector:(SEL)selector forTarget:(id)target {
	if (![path isEqualToString:@"/"])
		[target performSelector:selector withObject:self];
		
	for (CHMLinkItem* item in children) {
		[item enumerateItemsWithSelector:selector forTarget:target];
	}
}

- (void)sort {
	static NSArray *sortDescriptors = nil;
	
	if (sortDescriptors == nil) {
		NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"uppercaseName" ascending:YES] autorelease];
		sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	}
	[children sortUsingDescriptors:sortDescriptors];
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
	[description appendFormat:@"          path == \"%@\"\r\r", path];
	if (children.count) [description appendFormat:@"          children (%lu)\r\r", (unsigned long)children.count];
//	if (children.count) [description appendFormat:@"          children (%lu) == %@\r\r", (unsigned long)children.count, children];
	
	[description replaceOccurrencesOfString:@"\\n" withString:@"\r" options:0 range:NSMakeRange(0, description.length)];
	[description replaceOccurrencesOfString:@"\\\"" withString:@"          " options:0 range:NSMakeRange(0, description.length)];
	return description;
}

@end

