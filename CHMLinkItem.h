//
//  CHMLinkItem.h
//  ichm
//
//  Created by Mark Douma on 4/19/2016.
//  Copyright © 2016 Mark Douma LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CHMTableOfContents;
@class CHMArchiveItem;


@interface CHMLinkItem	: NSObject {
	NSString				*name;
	NSString				*path;
	NSMutableArray			*children;
	NSUInteger				pageID;
	
	CHMArchiveItem			*archiveItem;
	
	CHMLinkItem				*parent;		// non-retained
	
	CHMTableOfContents		*container;		// non-retained
}


@property (readonly, nonatomic, retain) NSString *name;
@property (readonly, nonatomic, retain) NSString *path;
@property (readonly, nonatomic, retain) NSArray *children;

@property (readonly, nonatomic, retain) CHMArchiveItem *archiveItem;

@property (readonly, nonatomic, assign) CHMLinkItem *parent;

@property (readonly, nonatomic, assign) CHMTableOfContents *container;


- (NSUInteger)numberOfChildren;
- (CHMLinkItem *)childAtIndex:(NSUInteger)n;

- (NSArray *)ancestors;

@end

