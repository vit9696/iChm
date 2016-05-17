//
//  CHMTableOfContents.h
//  ichm
//
//  Created by Robin Lu on 7/18/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CHMLinkItem;
@class CHMDocumentFile;


@interface CHMTableOfContents : NSObject {
	CHMLinkItem				*linkItems;
	NSMutableArray			*pageList;
	NSMutableDictionary		*itemsAndPaths;
	
	CHMDocumentFile			*documentFile;	// non-retained
	
	NSMutableArray			*itemStack;
	CHMLinkItem				*curItem;
	
}

@property (readonly, retain) CHMLinkItem *linkItems;
@property (readonly, retain) NSArray *pageList;

// Returns the CHMDocumentFile instance this table of contents is a part of.
@property (readonly, assign) CHMDocumentFile *documentFile;


- (CHMLinkItem *)pageAfterPage:(CHMLinkItem *)item;
- (CHMLinkItem *)pageBeforePage:(CHMLinkItem *)item;

@end


