//
//  BookmarkController.h
//  ichm
//
//  Created by Robin Lu on 8/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class CHMFile;
@class CHMBookmark;
@class FetchRequestItem;

@interface BookmarkController : NSWindowController {
	IBOutlet NSWindow* addPanel;
	IBOutlet NSTextField* titleField;
	IBOutlet NSTextField* tagField;
	IBOutlet NSMenu *bookmarkMenu;
	IBOutlet NSMenu *groupByFilesMenu;
	IBOutlet NSMenu *groupByTagsMenu;
	IBOutlet NSOutlineView *tocView;

	IBOutlet NSPanel* managePanel;
	IBOutlet NSArrayController* tableController;
	
	NSManagedObjectModel *managedObjectModel;
	NSManagedObjectContext *managedObjectContext;
	
	FetchRequestItem* tocSource;
}

- (IBAction)showAddBookmark:(id)sender;
- (IBAction)endAddBookmark:(id)sender;
- (IBAction)openBookmark:(id)sender;
- (IBAction)filterBookmarks:(id)sender;
- (void)addBookmarkDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;

- (NSManagedObjectModel *)managedObjectModel;
- (NSManagedObjectContext *)managedObjectContext;
@end
