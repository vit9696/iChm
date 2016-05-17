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
#import "CHMArchiveItem.h"

@class CHMDocumentFile;
struct chmFile;

@interface CHMArchiveItem ()

+ (id)rootArchiveItemWithDocumentFile:(CHMDocumentFile *)aDocumentFile chmFileHandle:(struct chmFile *)aChmFileHandle;
- (id)initDirectoryArchiveItemWithPath:(NSString *)aPath childNodePaths:(NSArray *)childNodePaths documentFile:(CHMDocumentFile *)aDocumentFile;
- (id)initLeafArchiveItemWithPath:(NSString *)aPath documentFile:(CHMDocumentFile *)aDocumentFile;

@property (nonatomic, assign) CHMDocumentFile *documentFile;
@property (nonatomic, assign) CHMArchiveItem *parent;
@property (nonatomic, assign, setter=setLeaf:) BOOL isLeaf;
@property (nonatomic, assign) BOOL isRootNode;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *path;

- (void)insertChildNode:(CHMArchiveItem *)aChildNode;
- (void)insertChildNodes:(NSArray *)newChildren;
- (void)sortWithSortDescriptors:(NSArray *)sortDescriptors recursively:(BOOL)recursively;

@end


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

- (CHMLinkItem *)linkItemAtPath:(NSString *)aPath;
- (void)push_item;
- (void)pop_item;
- (void)new_item;
- (CHMLinkItem *)curItem;
- (void)addToPageList:(CHMLinkItem *)item;
- (void)sort;

@end


@interface CHMSearchResult ()

- (id)initWithLinkItem:(CHMLinkItem *)anItem score:(CGFloat)aScore;

@end


@interface NSString (CHMKitPrivateInterfaces)

- (NSString *)chm__stringByDeletingLeadingSlashes;

@end
