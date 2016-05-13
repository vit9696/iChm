//
//  CHMSearchResult.m
//  ichm
//
//  Created by Mark Douma on 4/27/2016.
//  Copyright © 2016 Mark Douma LLC. All rights reserved.
//

#import "CHMSearchResult.h"
#import "CHMLinkItem.h"
#import "CHMKitPrivateInterfaces.h"


@implementation CHMSearchResult

@synthesize item;
@synthesize score;

+ (id)searchResultWithItem:(CHMLinkItem *)anItem score:(CGFloat)aScore {
	return [[[[self class] alloc] initWithItem:anItem score:aScore] autorelease];
}


- (id)initWithItem:(CHMLinkItem *)anItem score:(CGFloat)aScore {
	if ((self = [super init])) {
		item = [anItem retain];
		score = aScore;
	}
	return self;
}

- (void)dealloc {
	[item release];
	[super dealloc];
}


- (NSString *)description {
	NSMutableString *description = nil;
	if (score) {
		description = [NSMutableString stringWithFormat:@"<%@> score == %0.3f\r", NSStringFromClass([self class]), score];
	} else {
		description = [NSMutableString stringWithFormat:@"<%@>\r", NSStringFromClass([self class])];
	}
	[description appendFormat:@"          item == %@\r\r", item];
	
//	[description replaceOccurrencesOfString:@"\\n" withString:@"\r" options:0 range:NSMakeRange(0, description.length)];
//	[description replaceOccurrencesOfString:@"\\\"" withString:@"          " options:0 range:NSMakeRange(0, description.length)];
	return description;
}

@end
