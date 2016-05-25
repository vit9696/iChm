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
#import "CHMDocumentFile.h"


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

- (NSString *)actualPathForItemWithCaseInsensitivePath:(NSString *)aPath;

@end


@interface CHMDocumentFile ()

@property (nonatomic, retain) NSString *filePath;

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *homePath;
@property (nonatomic, retain) NSString *tableOfContentsPath;
@property (nonatomic, retain) NSString *indexPath;

@property (assign) NSStringEncoding encoding;
@property (retain) NSString *encodingName;
@property (assign) NSStringEncoding customEncoding;
@property (retain) NSString *customEncodingName;

@property (assign) BOOL hasPreparedSearchIndex;
@property (assign) BOOL isPreparingSearchIndex;


@property (nonatomic, retain) CHMArchiveItem *archiveItems;
@property (nonatomic, retain) NSArray *allArchiveItems;

- (BOOL)loadMetadata;
- (void)setupTableOfContentsAndIndex;

- (void)buildSearchIndexInBackgroundThread;
- (void)addToSearchIndex:(const char *)path;
- (void)notifyDelegateSearchIndexIsPrepared:(id)sender;

- (BOOL)hasObjectAtPath:(NSString *)absolutePath;
- (NSData *)dataForObjectAtPath:(NSString *)absolutePath;
- (NSString *)actualAbsolutePathForRelativeCaseInsensitivePath:(NSString *)aPath;

@end


@interface CHMLinkItem ()

- (id)initWithName:(NSString *)aName path:(NSString *)aPath;

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *path;
@property (nonatomic, retain) NSArray *children;
@property (nonatomic, assign) NSUInteger pageID;
@property (nonatomic, retain) CHMArchiveItem *archiveItem;
@property (nonatomic, assign) CHMLinkItem *parent;
@property (nonatomic, assign) CHMTableOfContents *container;
@property (readonly, nonatomic, retain) NSString *uppercaseName;

- (void)purge;
- (void)appendChild:(CHMLinkItem *)item;
- (void)enumerateItemsWithSelector:(SEL)selector forTarget:(id)target;
- (void)sort;

@end


@interface CHMTableOfContents ()

- (id)initWithData:(NSData *)data encodingName:(NSString *)encodingName documentFile:(CHMDocumentFile *)aDocumentFile;

@property (assign) CHMDocumentFile *documentFile;

- (CHMLinkItem *)linkItemAtPath:(NSString *)absolutePath;
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

// adds a leading slash, if necessary
// e.g.: "HTML/file.html" becomes "/HTML/file.html"

- (NSString *)chm__stringByAssuringAbsolutePath;

@end
