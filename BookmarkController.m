//
//  BookmarkController.m
//  ichm
//
//  Created by Robin Lu on 8/10/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "BookmarkController.h"
#import "CHMDocument.h"
#import "CHMFile.h"
#import "CHMBookmark.h"
#import "CHMTag.h"

@interface BookmarkController (Private)
- (void)groupByTagsMenuNeedsUpdate:(NSMenu*)menu;
- (void)groupByFilesMenuNeedsUpdate:(NSMenu*)menu;
- (NSMenuItem *)createMenuItemForBookmark:(CHMBookmark*)bm;
- (void)setupDataSource;
- (void)addEmptyItemToMenu:(NSMenu*)menu;
@end

@interface FetchRequestItem : NSObject
{
	NSFetchRequest *request;
	NSMutableArray* children;
	NSString *title;
}

@property (readwrite, retain) NSFetchRequest* request;
@property (readwrite, retain) NSString* title;

- (void)addChild:(FetchRequestItem*)child;
- (FetchRequestItem*)childAtIndex:(int)index;
- (int)numberOfChildren;
@end

@implementation FetchRequestItem

@synthesize request;
@synthesize title;

- (id)init
{
	children = [[NSMutableArray alloc] init];
	request = nil;
	title = nil;
	return self;
}

- (void)dealloc
{
	if (request)
		[request release];
	if (title)
		[title release];
	[children release];
	[super dealloc];
}

- (void)addChild:(FetchRequestItem*)child
{
	[children addObject:child];
}

- (FetchRequestItem*)childAtIndex:(int)index
{
	return [children objectAtIndex:index];
}

- (int)numberOfChildren
{
	return [children count];
}

@end


@implementation BookmarkController
- (id)init
{
    if (![super initWithWindowNibName:@"Bookmark"])
        return nil;
	
	tocSource = nil;

	[CHMFile purgeWithContext:[self managedObjectContext]];

    return self;
}

- (void)windowDidLoad
{
    NSLog(@"Nib file is loaded");
	[tableController fetch:self];
}

- (IBAction)showWindow:(id)sender
{
	[self setupDataSource];
	[super showWindow:sender];
}

- (IBAction)showAddBookmark:(id)sender
{
	// force load of nib
	[self window];
	
	
	CHMDocument *doc = (CHMDocument*)sender;
	[titleField setStringValue:[doc currentTitle]];
	[titleField selectText:self];
	CHMBookmark* bm = [CHMBookmark bookmarkByURL:[doc currentURL] withContext:[self managedObjectContext]];
	if( bm && [bm.tags count] > 0 )
		[tagField setStringValue:[bm tagsString]];
	else
		[tagField setStringValue:@""];
	
	[NSApp beginSheet:addPanel modalForWindow:[doc windowForSheet] modalDelegate:self didEndSelector:@selector(addBookmarkDidEnd:returnCode:contextInfo:) contextInfo:doc];

}

- (IBAction)endAddBookmark:(id)sender
{
	unsigned int tag = [sender tag];
	[NSApp endSheet:addPanel returnCode:tag];
	[addPanel orderOut:sender];
}

- (void)addBookmarkDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	NSLog(@"add bookmark ended with return code:%d", returnCode);
	if( 0 == returnCode || !contextInfo)
		return;
	
	CHMDocument *doc = contextInfo;
	NSError *error = nil;
	NSManagedObjectContext *context =[self managedObjectContext];
	
	CHMFile *chmFile = [CHMFile fileByPath:[doc filePath] withContext:context] ;
	if (!chmFile)
	{
		chmFile = [NSEntityDescription
				   insertNewObjectForEntityForName:@"File"
				   inManagedObjectContext:context];
		[chmFile setPath:[doc filePath]];
		[chmFile setTitle:[doc docTitle]];
		[context save:&error];
		if ( ![context save:&error] )
			NSLog(@"Can not fetch file info: %@",error );
	}
	
	CHMBookmark *bookmark = [CHMBookmark bookmarkByURL:[doc currentURL] withContext:[self managedObjectContext]];
	if ( !bookmark )
	{
		bookmark = [NSEntityDescription
							 insertNewObjectForEntityForName:@"Bookmark"
							 inManagedObjectContext:context];
	}
	[bookmark setUrl:[doc currentURL]];
	[bookmark setTitle:[titleField stringValue]];
	[bookmark setCreatedAt:[NSDate date]];
	[bookmark setFile:chmFile];
	[bookmark setTagsString:[tagField stringValue]];
	if ( ![context save:&error] )
	{
		NSLog(@"Can not fetch file info: %@",error );
		return;
	}
}

- (IBAction)filterBookmarks:(id)sender
{
	int selectedRow = [tocView selectedRow];
	if( selectedRow >= 0 ) {
		FetchRequestItem *item = [tocView itemAtRow:selectedRow];
		NSError *error;
		if ([item request])
			[tableController fetchWithRequest:[item request] merge:NO error:&error];
		else
			[tableController fetch:sender];
    }
	
}
#pragma mark CoreData context
- (NSString *)applicationSupportFolder {
	
    NSString *applicationSupportFolder = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    if ( [paths count] == 0 ) {
        NSRunAlertPanel(@"Alert", @"Can't find application support folder", @"Quit", nil, nil);
        [[NSApplication sharedApplication] terminate:self];
    } else {
        applicationSupportFolder = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"iChm"];
    }
    return applicationSupportFolder;
}

- (NSManagedObjectModel *)managedObjectModel {
    if (managedObjectModel) return managedObjectModel;
	
	NSMutableSet *allBundles = [[NSMutableSet alloc] init];
	[allBundles addObject: [NSBundle mainBundle]];
    
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles: [allBundles allObjects]] retain];
    [allBundles release];
    
    return managedObjectModel;
}

- (NSManagedObjectContext *) managedObjectContext {
    NSError *error;
    NSString *applicationSupportFolder = nil;
    NSURL *url;
    NSFileManager *fileManager;
    NSPersistentStoreCoordinator *coordinator;
    
    if (managedObjectContext) {
        return managedObjectContext;
    }
    
    fileManager = [NSFileManager defaultManager];
    applicationSupportFolder = [self applicationSupportFolder];
    if ( ![fileManager fileExistsAtPath:applicationSupportFolder isDirectory:NULL] ) {
        [fileManager createDirectoryAtPath:applicationSupportFolder attributes:nil];
    }
    
    url = [NSURL fileURLWithPath: [applicationSupportFolder stringByAppendingPathComponent: @"Bookmarks.sqlite"]];
    coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    if ([coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error]){
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    } else {
        [[NSApplication sharedApplication] presentError:error];
    }    
    [coordinator release];
    
    return managedObjectContext;
}

#pragma mark Bookmark Menu

#define BOOKMARK_LIMIT 15

- (NSMenuItem *)createMenuItemForBookmark:(CHMBookmark*)bm
{
	NSMenuItem *newitem = [[[NSMenuItem alloc] init] autorelease];
	[newitem setTitle:bm.title];
	[newitem setTarget:self];
	[newitem setAction:@selector(openBookmark:)];
	[newitem setRepresentedObject:bm];
	[newitem setEnabled:[bm.file.isValid boolValue] ];
	return newitem;
}

- (void)addEmptyItemToMenu:(NSMenu*)menu
{
	NSMenuItem *newitem = [[[NSMenuItem alloc] init] autorelease];
	[newitem setTitle:NSLocalizedString(@"(Empty)", @"(Empty menu)")];
	[newitem setEnabled:NO];
	[menu addItem:newitem];	
}

- (void)groupByTagsMenuNeedsUpdate:(NSMenu*)menu
{
	NSArray *tags = [CHMTag allTagswithContext:[self managedObjectContext]];
	
	while([menu numberOfItems] != 0)
		[menu removeItemAtIndex:0];
	
	if ( !tags || [tags count] == 0)
	{
		[self addEmptyItemToMenu:menu];
		return;
	}
	
	for (CHMTag* tag in tags)
	{
		NSSet * bookmarks = tag.bookmarks;
		if ( [bookmarks count] == 0 )
			continue;

		
		NSMenuItem *newitem = [[[NSMenuItem alloc] init] autorelease];
		[newitem setTitle:tag.tag];
		[newitem setEnabled:YES];
		NSMenu *newmenu = [[[NSMenu alloc] init] autorelease];
		[newmenu setAutoenablesItems:NO];
		[newitem setSubmenu:newmenu];
		for (CHMBookmark * bm in bookmarks) {
			[newmenu addItem:[self createMenuItemForBookmark:bm]];
		}
		[menu addItem:newitem];
	}
	
	if ([menu numberOfItems] == 0)
		[self addEmptyItemToMenu:menu];
}

- (void)groupByFilesMenuNeedsUpdate:(NSMenu*)menu
{
	NSArray *files = [CHMFile allFileswithContext:[self managedObjectContext]];
	
	while([menu numberOfItems] != 0)
		[menu removeItemAtIndex:0];
	
	if ( !files || [files count] == 0)
	{
		[self addEmptyItemToMenu:menu];
		return;
	}
	
	for (CHMFile* file in files)
	{
		NSSet * bookmarks = file.bookmarks;
		if ( [bookmarks count] == 0 )
			continue;
		
		
		NSMenuItem *newitem = [[[NSMenuItem alloc] init] autorelease];
		[newitem setTitle:file.title];
		[newitem setEnabled:YES];
		NSMenu *newmenu = [[[NSMenu alloc] init] autorelease];
		[newmenu setAutoenablesItems:NO];
		[newitem setSubmenu:newmenu];
		for (CHMBookmark * bm in bookmarks) {
			[newmenu addItem:[self createMenuItemForBookmark:bm]];
		}
		[menu addItem:newitem];
	}
	
	if ([menu numberOfItems] == 0)
		[self addEmptyItemToMenu:menu];
}

- (void)menuNeedsUpdate:(NSMenu *)menu
{
	NSDocumentController *controller = [NSDocumentController sharedDocumentController];
	[[menu itemWithTag:0] setEnabled:(nil != [controller currentDocument])];

	if (menu == groupByTagsMenu)
		return [self groupByTagsMenuNeedsUpdate:groupByTagsMenu];
	else if (menu == groupByFilesMenu)
		return [self groupByFilesMenuNeedsUpdate:groupByFilesMenu];
	
	while ([menu numberOfItems] > 0)
	{
		[menu removeItemAtIndex:0];
	}
	
	NSManagedObjectContext *context =[self managedObjectContext];
	NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
	NSEntityDescription *bookmarkEntity = [NSEntityDescription
									   entityForName:@"Bookmark" inManagedObjectContext:context];
	[request setEntity:bookmarkEntity];
	[request setFetchLimit:BOOKMARK_LIMIT];
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]
										initWithKey:@"createdAt" ascending:NO];
	[request setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	[sortDescriptor release];

	NSError *error = nil;
	NSArray *array = [context executeFetchRequest:request error:&error];
	if (array == nil)
	{
		NSLog(@"Can not fetch file info: %@",error );
		return;
	}
	for (CHMBookmark* bm in array) {
		[menu addItem:[self createMenuItemForBookmark:bm]];
	}
	
	if ([menu numberOfItems] == 0)
		[self addEmptyItemToMenu:menu];
}

- (IBAction)openBookmark:(id)sender
{
	NSDocumentController *controller = [NSDocumentController sharedDocumentController];
	NSError *error = nil;
	CHMBookmark * bm = (CHMBookmark*)[sender representedObject];
	NSURL *url = [NSURL fileURLWithPath:bm.file.path];
	CHMDocument* doc = [controller openDocumentWithContentsOfURL:url display:YES error:&error];
	[doc loadURL:[NSURL URLWithString:bm.url]];
}

# pragma mark NSOutlineView datasource
- (void)setupDataSource
{
	if(tocSource)
		[tocSource release];
	
	tocSource = [[FetchRequestItem alloc] init];
	
	FetchRequestItem * allItem = [[FetchRequestItem alloc] init];
	[allItem setTitle:NSLocalizedString(@"All", @"All")];
	[tocSource addChild:allItem];
	
	NSManagedObjectContext *moc = [self managedObjectContext];
	NSEntityDescription *bookmarkDescription = [NSEntityDescription
												entityForName:@"Bookmark" 
												inManagedObjectContext:moc];
	
	FetchRequestItem * tagsItem = [[FetchRequestItem alloc] init];
	[tagsItem setTitle:NSLocalizedString(@"Tags", @"Tags")];
	[tocSource addChild:tagsItem];	
	for (CHMTag* tag in [CHMTag allTagswithContext:moc])
	{
		if ([tag.bookmarks count] == 0)
			continue;
		FetchRequestItem * tagItem = [[FetchRequestItem alloc] init];
		[tagItem setTitle:tag.tag];
		NSFetchRequest * request = [[[NSFetchRequest alloc] init] autorelease];
		[request setEntity:bookmarkDescription];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:
								  @"(ANY tags.tag == %@)", tag.tag];
		[request setPredicate:predicate];
		[tagItem setRequest:request];
		[tagsItem addChild:tagItem];
	}
	
	FetchRequestItem * filesItem = [[FetchRequestItem alloc] init];
	[filesItem setTitle:NSLocalizedString(@"Files", @"Files")];
	[tocSource addChild:filesItem];	
	for (CHMFile* file in [CHMFile allFileswithContext:moc])
	{
		if ([file.bookmarks count] == 0)
			continue;
		FetchRequestItem * fileItem = [[FetchRequestItem alloc] init];
		[fileItem setTitle:file.title];
		NSFetchRequest * request = [[[NSFetchRequest alloc] init] autorelease];
		[request setEntity:bookmarkDescription];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:
								  @"(file == %@)", file];
		[request setPredicate:predicate];
		[fileItem setRequest:request];
		[filesItem addChild:fileItem];
	}
	[tocView reloadData];
}

- (int)outlineView:(NSOutlineView *)outlineView
numberOfChildrenOfItem:(id)item
{
	if(!item)
		item = tocSource;
	return [(FetchRequestItem*)item numberOfChildren];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView
   isItemExpandable:(id)item
{
    return [item numberOfChildren] > 0;
}

- (id)outlineView:(NSOutlineView *)outlineView
			child:(int)theIndex
		   ofItem:(id)item
{
	if (!item)
		item = tocSource;
	
    return [item childAtIndex:theIndex];
}

- (id)outlineView:(NSOutlineView *)outlineView
objectValueForTableColumn:(NSTableColumn *)tableColumn
		   byItem:(id)item
{
    return [item title];
}

#pragma mark Bookmark manager window Delegate
- (void)windowWillClose:(NSNotification *)notification
{
	NSError *error;
	[CHMFile purgeWithContext:[self managedObjectContext]];
	[[self managedObjectContext] save:&error];
}
@end
