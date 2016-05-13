//
//  CHMTableOfContents.h
//  ichm
//
//  Created by Robin Lu on 7/18/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CHMLinkItem;


@interface CHMTableOfContents : NSObject {
	CHMLinkItem				*items;
	NSMutableArray			*pageList;
	NSMutableDictionary		*itemsAndPaths;
	
	NSMutableArray			*itemStack;
	CHMLinkItem				*curItem;
	
}

@property (readonly, retain) CHMLinkItem *items;
@property (readonly, retain) NSArray *pageList;



- (CHMLinkItem *)pageAfterPage:(CHMLinkItem *)item;
- (CHMLinkItem *)pageBeforePage:(CHMLinkItem *)item;

@end


