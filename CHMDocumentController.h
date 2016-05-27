//
//  CHMDocumentController.h
//  ichm
//
//  Created by Mark Douma on 5/26/2016.
//  Copyright © 2016 Mark Douma LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CHMBookmark;


@interface CHMDocumentController : NSDocumentController {
	CHMBookmark			*pendingBookmarkToLoad;
	
}

- (id)openDocumentWithContentsOfURL:(NSURL *)URL loadBookmark:(CHMBookmark *)bookmark error:(NSError **)outError;

@end
