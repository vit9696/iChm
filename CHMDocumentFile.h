//
//  CHMDocumentFile.h
//  ichm
//
//  Created by Mark Douma on 4/15/2016.
//
//  Copyright © 2016 Mark Douma.

#import <Foundation/Foundation.h>


struct chmFile;
@class CHMTableOfContents;
@class CHMDocumentFile;
@class CHMLinkItem;
@class CHMArchiveItem;


@protocol CHMDocumentFileSearchDelegate <NSObject>

@optional

- (void)documentFileDidPrepareSearchIndex:(CHMDocumentFile *)aDocumentFile;

// `aSearchResults` is an NSArray of `CHMSearchResult`s
- (void)documentFile:(CHMDocumentFile *)aDocumentFile didUpdateSearchResults:(NSArray *)aSearchResults;

@end


enum {
	CHMDocumentFileDefaultStringEncoding	= 0,
};

enum {
	CHMDocumentFileSearchInFile		= 1,
	CHMDocumentFileSearchInIndex	= 2,
};
typedef NSUInteger CHMDocumentFileSearchMode;


@interface CHMDocumentFile : NSObject {
	NSString								*filePath;
	
	struct chmFile							*chmFileHandle;
	
    NSString								*title;
	
    NSString								*homePath;
    NSString								*tableOfContentsPath;
    NSString								*indexPath;
	
	CHMTableOfContents						*tableOfContents;
	CHMTableOfContents						*index;
	NSMutableArray							*searchResults;
	
	CHMArchiveItem							*archiveItems;
	NSMutableArray							*allArchiveItems;
	
	SKIndexRef								skIndex;
	NSMutableData							*searchIndexData;
	BOOL									hasPreparedSearchIndex;
	BOOL									isPreparingSearchIndex;
	NSCondition								*searchIndexCondition;
	
	NSStringEncoding						encoding;
	NSString								*encodingName;
	
	NSStringEncoding						customEncoding;
	NSString								*customEncodingName;
	
	id <CHMDocumentFileSearchDelegate>		searchDelegate;	// non-retained
	
}

// NOTE: error reporting isn't yet implemented
+ (id)documentFileWithContentsOfFile:(NSString *)path error:(NSError **)outError;
- (id)initWithContentsOfFile:(NSString *)path error:(NSError **)outError;


@property (readonly, nonatomic, retain) NSString *filePath;

@property (readonly, nonatomic, retain) NSString *title;

@property (readonly, nonatomic, retain) NSString *homePath;
@property (readonly, nonatomic, retain) NSString *tableOfContentsPath;
@property (readonly, nonatomic, retain) NSString *indexPath;


@property (readonly, retain) CHMTableOfContents *tableOfContents;
@property (readonly, retain) CHMTableOfContents *index;


// returns the root-level CHMArchiveItem
@property (readonly, nonatomic, retain) CHMArchiveItem *archiveItems;

// returns an array of all CHMArchiveItem, including the root item and all its descendants
@property (readonly, nonatomic, retain) NSArray *allArchiveItems;



- (BOOL)hasObjectAtPath:(NSString *)path;
- (NSData *)dataForObjectAtPath:(NSString *)path;

- (NSData *)dataForObjectAtPath:(NSString *)aRelativePath relativeToLinkItem:(CHMLinkItem *)anItem;

- (CHMLinkItem *)linkItemAtPath:(NSString *)aPath;


#pragma mark - encodings
@property (readonly, assign) NSStringEncoding encoding;
@property (readonly, retain) NSString *encodingName;			// IANA

@property (readonly, assign) NSStringEncoding customEncoding;
@property (readonly, retain) NSString *customEncodingName;		// IANA

// to set or clear a custom encoding; to clear, pass `CHMDocumentFileDefaultStringEncoding` and `nil`
- (void)setCustomEncoding:(NSStringEncoding)aCustomEncoding customEncodingName:(NSString *)aCustomEncodingName;

// convenience, returns `customEncodingName` if non-nil (in other words, one is set), otherwise returns `encodingName`.
@property (readonly, nonatomic, retain) NSString *currentEncodingName;


#pragma mark - search

// sets/gets whether instances automatically prepare search kit index upon creation
// default is YES
+ (BOOL)automaticallyPreparesSearchIndex;
+ (void)setAutomaticallyPreparesSearchIndex:(BOOL)shouldPrepare;

// whether this particular instance's search index has been prepared
@property (readonly, assign) BOOL hasPreparedSearchIndex;

// Asynchronously prepares the search index. Use the `documentFileDidPrepareSearchIndex:` search delegate method to learn when the preparation is complete.
- (void)prepareSearchIndex;


@property (assign) id <CHMDocumentFileSearchDelegate> searchDelegate;

@property (readonly, nonatomic, retain) NSArray *searchResults;


- (void)searchForString:(NSString *)searchString usingMode:(CHMDocumentFileSearchMode)searchMode;


@end


