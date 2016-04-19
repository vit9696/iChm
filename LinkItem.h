//
//  LinkItem.h
//  ichm
//
//  Created by Mark Douma on 4/19/2016.
//  Copyright © 2016 Mark Douma LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface LinkItem	: NSObject {
	NSString *_name;
	NSString *_path;
	NSMutableArray *_children;
	NSUInteger pageID;
}
@property (readonly) NSUInteger pageID;

- (id)initWithName:(NSString *)name Path:(NSString *)path;
- (NSInteger)numberOfChildren;
- (LinkItem *)childAtIndex:(NSInteger)n;
- (NSString *)name;
- (NSString *)uppercaseName;
- (NSString *)path;
- (NSMutableArray*)children;
- (void)purge;
- (void)setName:(NSString *)name;
- (void)setPath:(NSString *)path;
- (void)setPageID:(NSUInteger)pid;
- (void)appendChild:(LinkItem *)item;
- (LinkItem*)find_by_path:(NSString *)path withStack:(NSMutableArray*)stack;
- (void)enumerateItemsWithSEL:(SEL)selector ForTarget:(id)target;
- (void)sort;
@end


@interface ScoredLinkItem : LinkItem {
	float relScore;
}

@property (readwrite, assign) float relScore;

- (id)initWithName:(NSString *)name Path:(NSString *)path Score:(float)score;
@end

