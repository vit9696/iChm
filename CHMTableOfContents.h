//
//  CHMTableOfContent.h
//  ichm
//
//  Created by Robin Lu on 7/18/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class CHMLinkItem;


@interface CHMTableOfContents : NSObject {
	CHMLinkItem			*rootItems;
	NSMutableArray		*pageList;
	
	NSMutableArray		*itemStack;
	CHMLinkItem			*curItem;
	
}

@property (readonly) CHMLinkItem *rootItems;
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
	CHMTableOfContents *indexContents;
}

- (id)initWithTableOfContents:(CHMTableOfContents *)toc indexContents:(CHMTableOfContents *)index;
- (void)addPath:(NSString *)path score:(CGFloat)score;
@end



