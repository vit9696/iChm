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
#import "CHMDocumentController.h"


#define MD_DEBUG 0

#if MD_DEBUG
#define MDLog(...) NSLog(__VA_ARGS__)
#else
#define MDLog(...)
#endif




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
- (FetchRequestItem*)childAtIndex:(NSInteger)index;
- (NSInteger)numberOfChildren;
@end

@implementation FetchRequestItem

@synthesize request;
@synthesize title;

- (id)init
{
	if ((self = [super init])) {
		children = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc
{
	[request release];
	[title release];
	[children release];
	[super dealloc];
}

- (void)addChild:(FetchRequestItem*)child
{
	[children addObject:child];
}

- (FetchRequestItem*)childAtIndex:(NSInteger)index
{
	return [children objectAtIndex:index];
}

- (NSInteger)numberOfChildren
{
	return [children count];
}

@end


@implementation BookmarkController
- (id)init
{
	if ((self = [super initWithWindowNibName:@"Bookmark"])) {
		[CHMFile purgeWithContext:[self managedObjectContext]];
	}
    return self;
}

- (void)windowDidLoad
{
	MDLog(@"[%@ %@] Nib file is loaded", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
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
	NSInteger tag = [(NSButton *)sender tag];
	[NSApp endSheet:addPanel returnCode:tag];
	[addPanel orderOut:sender];
}

- (void)addBookmarkDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	MDLog(@"[%@ %@] add bookmark ended with returnCode == %ld", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (long)returnCode);
	
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
		[chmFile setTitle:doc.documentFile.title];
		[context save:&error];
		if ( ![context save:&error] )
			NSLog(@"Cannot fetch file info: %@", error);
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
		NSLog(@"Cannot fetch file info: %@", error);
		return;
	}
}

- (IBAction)filterBookmarks:(id)sender
{
	NSInteger selectedRow = [tocView selectedRow];
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
		[fileManager createDirectoryAtPath:applicationSupportFolder withIntermediateDirectories:YES attributes:nil error:NULL];
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
		NSLog(@"Cannot fetch file info: %@", error);
		return;
	}
	for (CHMBookmark* bm in array) {
		[menu addItem:[self createMenuItemForBookmark:bm]];
	}
	
	if ([menu numberOfItems] == 0)
		[self addEmptyItemToMenu:menu];
}


- (IBAction)openBookmark:(id)sender {
	CHMDocumentController *docController = [CHMDocumentController sharedDocumentController];
	CHMBookmark *bookmark = (CHMBookmark *)[sender representedObject];
	NSURL *URL = [NSURL fileURLWithPath:bookmark.file.path];
	CHMDocument *document = [docController documentForURL:URL];
	if (document) {
		[document loadURL:[NSURL URLWithString:bookmark.url]];
	} else {
		NSError *error = nil;
		[docController openDocumentWithContentsOfURL:URL loadBookmark:bookmark error:&error];
	}
}


# pragma mark NSOutlineView datasource
- (void)setupDataSource
{
	[tocSource release];
	
	tocSource = [[FetchRequestItem alloc] init];
	
	FetchRequestItem * allItem = [[[FetchRequestItem alloc] init] autorelease];
	[allItem setTitle:NSLocalizedString(@"All", @"All")];
	[tocSource addChild:allItem];
	
	NSManagedObjectContext *moc = [self managedObjectContext];
	NSEntityDescription *bookmarkDescription = [NSEntityDescription
												entityForName:@"Bookmark" 
												inManagedObjectContext:moc];
	
	FetchRequestItem * tagsItem = [[[FetchRequestItem alloc] init] autorelease];
	[tagsItem setTitle:NSLocalizedString(@"Tags", @"Tags")];
	[tocSource addChild:tagsItem];	
	for (CHMTag* tag in [CHMTag allTagswithContext:moc])
	{
		if ([tag.bookmarks count] == 0)
			continue;
		FetchRequestItem * tagItem = [[[FetchRequestItem alloc] init] autorelease];
		[tagItem setTitle:tag.tag];
		NSFetchRequest * request = [[[NSFetchRequest alloc] init] autorelease];
		[request setEntity:bookmarkDescription];
		NSPredicate *predicate = [NSPredicate predicateWithFormat:
								  @"(ANY tags.tag == %@)", tag.tag];
		[request setPredicate:predicate];
		[tagItem setRequest:request];
		[tagsItem addChild:tagItem];
	}
	
	FetchRequestItem * filesItem = [[[FetchRequestItem alloc] init] autorelease];
	[filesItem setTitle:NSLocalizedString(@"Files", @"Files")];
	[tocSource addChild:filesItem];	
	for (CHMFile* file in [CHMFile allFileswithContext:moc])
	{
		if ([file.bookmarks count] == 0)
			continue;
		FetchRequestItem * fileItem = [[[FetchRequestItem alloc] init] autorelease];
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

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
	if(!item)
		item = tocSource;
	return [(FetchRequestItem*)item numberOfChildren];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return [item numberOfChildren] > 0;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)theIndex ofItem:(id)item {
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
