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
	
	NSMutableArray		*itemStack;
	NSMutableArray		*pageList;
	LinkItem			*curItem;
	
}

@property (readonly) LinkItem *rootItems;
@property (readonly) NSArray *pageList;

- (id)initWithData:(NSData *)data encodingName:(NSString *)encodingName;
- (id)initWithTOC:(CHMTableOfContents*)toc filterByPredicate:(NSPredicate*)predicate;

- (LinkItem *)curItem;

- (LinkItem *)itemForPath:(NSString*)path withStack:(NSMutableArray*)stack;

- (NSInteger)rootChildrenCount;

- (void)sort;

- (LinkItem*)getNextPage:(LinkItem*)item;
- (LinkItem*)getPrevPage:(LinkItem*)item;

@end


@interface CHMSearchResult : CHMTableOfContents <NSOutlineViewDataSource> {
	CHMTableOfContents *tableOfContent;
	CHMTableOfContents *indexContent;
}

- (id)initwithTOC:(CHMTableOfContents*)toc withIndex:(CHMTableOfContents*)index;
- (void)addPath:(NSString*)path score:(CGFloat)score;
@end



