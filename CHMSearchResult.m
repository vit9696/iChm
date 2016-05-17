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

@synthesize linkItem;
@synthesize score;



- (id)initWithLinkItem:(CHMLinkItem *)anItem score:(CGFloat)aScore {
	if ((self = [super init])) {
		linkItem = [anItem retain];
		score = aScore;
	}
	return self;
}

- (void)dealloc {
	[linkItem release];
	[super dealloc];
}


- (NSString *)description {
	NSMutableString *description = nil;
	if (score) {
		description = [NSMutableString stringWithFormat:@"<%@> score == %0.3f\r", NSStringFromClass([self class]), score];
	} else {
		description = [NSMutableString stringWithFormat:@"<%@>\r", NSStringFromClass([self class])];
	}
	[description appendFormat:@"          linkItem == %@\r\r", linkItem];
	
//	[description replaceOccurrencesOfString:@"\\n" withString:@"\r" options:0 range:NSMakeRange(0, description.length)];
//	[description replaceOccurrencesOfString:@"\\\"" withString:@"          " options:0 range:NSMakeRange(0, description.length)];
	return description;
}

@end
