//
//  CHMTableOfContent.h
//  ichm
//
//  Created by Robin Lu on 7/18/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class LinkItem;


@interface CHMTableOfContents : NSObject <NSOutlineViewDataSource> {
	LinkItem			*rootItems;
	NSMutableArray		*pageList;
	
	NSMutableArray		*itemStack;
	LinkItem			*curItem;
	
}

@property (readonly) LinkItem *rootItems;
@property (readonly) NSArray *pageList;

- (id)initWithData:(NSData *)data encodingName:(NSString *)encodingName;

- (id)initWithTableOfContents:(CHMTableOfContents *)toc filterByPredicate:(NSPredicate *)predicate;


- (LinkItem *)itemForPath:(NSString *)path withStack:(NSMutableArray *)stack;

- (void)sort;

- (LinkItem *)pageAfterPage:(LinkItem *)item;
- (LinkItem *)pageBeforePage:(LinkItem *)item;

@end


@interface CHMSearchResults : CHMTableOfContents <NSOutlineViewDataSource> {
	CHMTableOfContents *tableOfContents;
	CHMTableOfContents *indexContents;
}

- (id)initWithTableOfContents:(CHMTableOfContents *)toc indexContents:(CHMTableOfContents *)index;
- (void)addPath:(NSString *)path score:(CGFloat)score;
@end



