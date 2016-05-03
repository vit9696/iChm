//
//  CHMTableOfContents.h
//  ichm
//
//  Created by Robin Lu on 7/18/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class CHMLinkItem;


@interface CHMTableOfContents : NSObject {
	CHMLinkItem				*items;
	NSMutableArray			*pageList;
	NSMutableDictionary		*itemsAndPaths;
	
	NSMutableArray			*itemStack;
	CHMLinkItem				*curItem;
	
}

@property (readonly) CHMLinkItem *items;
@property (readonly) NSArray *pageList;

- (id)initWithData:(NSData *)data encodingName:(NSString *)encodingName;


- (CHMLinkItem *)itemAtPath:(NSString *)aPath;


- (void)sort;

- (CHMLinkItem *)pageAfterPage:(CHMLinkItem *)item;
- (CHMLinkItem *)pageBeforePage:(CHMLinkItem *)item;

@end


