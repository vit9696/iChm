//
//  CHMLinkItem.h
//  ichm
//
//  Created by Mark Douma on 4/19/2016.
//  Copyright © 2016 Mark Douma LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CHMLinkItem	: NSObject {
	NSString			*name;
	NSString			*path;
	NSMutableArray		*children;
	NSUInteger			pageID;
}


- (id)initWithName:(NSString *)aName path:(NSString *)aPath;

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *path;
@property (nonatomic, retain) NSMutableArray *children;
@property (nonatomic, assign) NSUInteger pageID;

@property (readonly, nonatomic, retain) NSString *uppercaseName;


- (void)purge;

- (NSUInteger)numberOfChildren;
- (CHMLinkItem *)childAtIndex:(NSInteger)n;

- (void)appendChild:(CHMLinkItem *)item;

- (CHMLinkItem *)itemForPath:(NSString *)aPath withStack:(NSMutableArray*)stack;
- (void)enumerateItemsWithSelector:(SEL)selector forTarget:(id)target;
- (void)sort;
@end


@interface CHMScoredLinkItem : CHMLinkItem {
	CGFloat			relScore;
}

@property (nonatomic, assign) CGFloat relScore;

- (id)initWithName:(NSString *)aName path:(NSString *)path score:(CGFloat)score;

@end

