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
	CHMLinkItem			*items;
	NSMutableArray		*pageList;
	
	NSMutableArray		*itemStack;
	CHMLinkItem			*curItem;
	
}

@property (readonly) CHMLinkItem *items;
@property (readonly) NSArray *pageList;

- (id)initWithData:(NSData *)data encodingName:(NSString *)encodingName;

- (id)initWithTableOfContents:(CHMTableOfContents *)toc filterByPredicate:(NSPredicate *)predicate;


- (CHMLinkItem *)itemForPath:(NSString *)path withStack:(NSMutableArray *)stack;

- (void)sort;

- (CHMLinkItem *)pageAfterPage:(CHMLinkItem *)item;
- (CHMLinkItem *)pageBeforePage:(CHMLinkItem *)item;

@end


@interface CHMSearchResults : CHMTableOfContents {
	CHMTableOfContents *tableOfContents;
	CHMTableOfContents *index;
}

- (id)initWithTableOfContents:(CHMTableOfContents *)toc index:(CHMTableOfContents *)anIndex;
- (void)addPath:(NSString *)path score:(CGFloat)score;
@end



