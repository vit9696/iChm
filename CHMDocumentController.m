//
//  CHMDocumentController.m
//  ichm
//
//  Created by Mark Douma on 5/26/2016.
//  Copyright © 2016 Mark Douma LLC. All rights reserved.
//

#import "CHMDocumentController.h"
#import "CHMBookmark.h"
#import "CHMDocument.h"



#define MD_DEBUG 0

#if MD_DEBUG
#define MDLog(...) NSLog(__VA_ARGS__)
#else
#define MDLog(...)
#endif

@interface CHMDocumentController ()

@property (nonatomic, retain) CHMBookmark *pendingBookmarkToLoad;

@end


@implementation CHMDocumentController

@synthesize pendingBookmarkToLoad;


- (void)dealloc {
	[pendingBookmarkToLoad release];
	[super dealloc];
}


- (id)openDocumentWithContentsOfURL:(NSURL *)URL loadBookmark:(CHMBookmark *)bookmark error:(NSError **)outError {
	self.pendingBookmarkToLoad = bookmark;
	return [super openDocumentWithContentsOfURL:URL display:YES error:outError];
}


- (id)makeDocumentWithContentsOfURL:(NSURL *)URL ofType:(NSString *)typeName error:(NSError **)outError {
	MDLog(@"[%@ %@] URL.path == %@; type == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), URL.path, typeName);
	if (pendingBookmarkToLoad == nil) return [super makeDocumentWithContentsOfURL:URL ofType:typeName error:outError];
	
	CHMDocument *document = [super makeDocumentWithContentsOfURL:URL ofType:typeName error:outError];
	document.pendingBookmarkToLoad = pendingBookmarkToLoad;
	self.pendingBookmarkToLoad = nil;
	return document;
}




@end


