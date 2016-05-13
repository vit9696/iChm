//
//  CHMLinkItem.h
//  ichm
//
//  Created by Mark Douma on 4/19/2016.
//  Copyright © 2016 Mark Douma LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CHMTableOfContents;


@interface CHMLinkItem	: NSObject {
	NSString				*name;
	NSString				*path;
	NSMutableArray			*children;
	NSUInteger				pageID;
	
	CHMLinkItem				*parent;		// non-retained
	
	CHMTableOfContents		*container;		// non-retained
}


@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *path;
@property (nonatomic, retain) NSMutableArray *children;
@property (nonatomic, assign) NSUInteger pageID;

@property (readonly, nonatomic, assign) CHMLinkItem *parent;

@property (readonly, nonatomic, assign) CHMTableOfContents *container;

@property (readonly, nonatomic, retain) NSString *uppercaseName;


- (NSUInteger)numberOfChildren;
- (CHMLinkItem *)childAtIndex:(NSUInteger)n;

- (NSArray *)ancestors;

@end

