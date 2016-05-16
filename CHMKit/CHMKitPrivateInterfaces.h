//
//  CHMKitPrivateInterfaces.h
//  CHMKit
//
//  Created by Mark Douma on 5/4/2016.
//  Copyright © 2016 Mark Douma.
//

#import "CHMLinkItem.h"
#import "CHMTableOfContents.h"
#import "CHMSearchResult.h"


@interface CHMLinkItem ()

- (id)initWithName:(NSString *)aName path:(NSString *)aPath;


@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *path;
@property (nonatomic, retain) NSArray *children;
@property (nonatomic, assign) NSUInteger pageID;


@property (nonatomic, assign) CHMLinkItem *parent;

@property (nonatomic, assign) CHMTableOfContents *container;

@property (readonly, nonatomic, retain) NSString *uppercaseName;

- (void)purge;

- (void)appendChild:(CHMLinkItem *)item;

- (void)enumerateItemsWithSelector:(SEL)selector forTarget:(id)target;

- (void)sort;

@end



@interface CHMTableOfContents ()

- (id)initWithData:(NSData *)data encodingName:(NSString *)encodingName;

@property (assign) CHMDocumentFile *documentFile;


- (CHMLinkItem *)itemAtPath:(NSString *)aPath;

- (void)push_item;
- (void)pop_item;
- (void)new_item;

- (CHMLinkItem *)curItem;

- (void)addToPageList:(CHMLinkItem *)item;

- (void)sort;

@end



@interface CHMSearchResult ()

+ (id)searchResultWithItem:(CHMLinkItem *)anItem score:(CGFloat)aScore;
- (id)initWithItem:(CHMLinkItem *)anItem score:(CGFloat)aScore;

@end



@interface NSString (CHMKitPrivateInterfaces)

- (NSString *)chm__stringByDeletingLeadingSlashes;

@end
