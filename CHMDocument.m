//
//  CHMDocument.m
//  ichm
//
//  Created by Robin Lu on 7/16/08.
//  Copyright __MyCompanyName__ 2008 . All rights reserved.
//

#import "CHMDocument.h"
#import "CHMWebViewController.h"
#import "CHMAppController.h"
#import "BookmarkController.h"
#import "CHMWebView.h"


#define MD_DEBUG 1

#if MD_DEBUG
#define MDLog(...) NSLog(__VA_ARGS__)
#else
#define MDLog(...)
#endif


#define PREF_FILES_INFO @"files info"
#define PREF_UPDATED_AT @"updated at"
#define PREF_LAST_PATH @"last path"
#define PREF_SEARCH_TYPE @"search type"

#define PREF_VALUE_SEARCH_IN_INDEX @"index"
#define PREF_VALUE_SEARCH_IN_FILE  @"file"


static NSString * const	ICHMToolbarIdentifier			= @"ICHM Toolbar Identifier";
static NSString * const HistoryToolbarItemIdentifier 	= @"History Item Identifier";
static NSString * const TextSizeToolbarItemIdentifier 	= @"Text Size Item Identifier";
static NSString * const SearchToolbarItemIdentifier     = @"Search Item Identifier";
static NSString * const HomeToolbarItemIdentifier       = @"Home Item Identifier";
static NSString * const SidebarToolbarItemIdentifier    = @"Sidebar Item Identifier";
static NSString * const WebVewPreferenceIndentifier     = @"iCHM WebView Preferences";
static NSString * const SidebarWidthName				= @"Sidebar Width";
static CGFloat MinSidebarWidth = 160.0;
static BOOL firstDocument = YES;

@interface CHMConsole : NSObject {
	
}

- (void)log:(NSString*)string;
@end

@implementation CHMConsole

- (void)log:(NSString *)string {
	NSLog(@"%@", string);
}

+ (BOOL)isSelectorExcludedFromWebScript:(SEL)selector {
	if (selector == @selector(log:)) {
		return NO;
	}
	return YES;
}

+ (NSString *)webScriptNameForSelector:(SEL)selector {
	if (@selector(log:)) {
		return @"log";
	}
	return nil;
}

@end


@interface CHMDocument ()

- (void)removeHighlight;
- (void)highlightString:(NSString *)pattern;

// file preferences
- (void)setPreference:(id)object forFile:(NSString *)filename withKey:(NSString *)key;
- (id)getPreferenceforFile:(NSString *)filename withKey:(NSString *)key;


- (void)setupToolbar;
- (void)updateToolbarButtons;


- (void)setupTabBar;
- (void)loadJavascript;
- (void)runJavascript:(NSString *)script;

- (void)restoreSidebar;

- (void)after_zoom;

- (NSTabViewItem *)createWebViewInTab:(id)sender;

- (IBAction)hideSidebar:(id)sender;

- (CHMTableOfContents *)currentDataSource;

- (void)loadLinkItem:(CHMLinkItem *)anItem;

- (IBAction)revealCurrentItemInOutlineView:(id)sender;

@end



@implementation CHMDocument

@synthesize filePath;
@synthesize searchMode;
@synthesize viewMode;
@synthesize documentFile;
@synthesize currentLinkItem;


- (id)init {
	if ((self = [super init])) {
		
		// Add your subclass-specific initialization here.
		// If an error occurs here, send a [self release] message and return nil.
		
		webViews = [[NSMutableArray alloc] init];
		console = [[CHMConsole alloc] init];
		
		isSidebarRestored = NO;
		
		searchMode = CHMDocumentFileSearchInFile;
		viewMode = CHMDocumentViewTableOfContents;
		
		searchResults = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc {
	MDLog(@"\"%@\" - [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
	[filePath release];
	
	[webViews release];
	[console release];
	
	documentFile.searchDelegate = nil;
	[documentFile release];
	
	[currentLinkItem release];
	
	[searchResults release];
	
	exporter.delegate = nil;
	[exporter release];
	[super dealloc];
}


#pragma mark - NSDocument
- (NSString *)windowNibName {
	return @"CHMDocument";
}


- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
	MDLog(@"\"%@\" - [%@ %@]", [self displayName], NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
	[super windowControllerDidLoadNib:aController];
	[aController.window setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];
	
	[self setupTabBar];
	[self addNewTab:self];
	
	[exportProgressIndicator setUsesThreadedAnimation:YES];
	
	[outlineView setAutoresizesOutlineColumn:NO];
	
	if (documentFile.tableOfContents.linkItems.numberOfChildren == 0) {
		[self hideSidebar:self];
	}
	
	[self setupToolbar];
	[self restoreSidebar];
	
	// go to last viewed page
	NSString *lastPath = (NSString *)[self getPreferenceforFile:filePath withKey:PREF_LAST_PATH];
	
	if (lastPath == nil) {
		[self goHome:self];
	} else {
		
		// old prefs saved relative paths, we now use absolute paths; make sure to make any relative paths to absolute
		if (![lastPath hasPrefix:@"/"]) lastPath = [@"/" stringByAppendingPathComponent:lastPath];
		
		CHMLinkItem *lastItem = [documentFile linkItemAtPath:lastPath];
		(lastItem ? [self loadLinkItem:lastItem] : [self goHome:self]);
	}
	
	// set search type and search menu
	NSString *type = [self getPreferenceforFile:filePath withKey:PREF_SEARCH_TYPE];
	if (type && [type isEqualToString:PREF_VALUE_SEARCH_IN_INDEX]) {
		self.searchMode = CHMDocumentFileSearchInIndex;
		[[searchField cell] setPlaceholderString:NSLocalizedString(@"Search in Index", @"")];
	}
	
	// invoke search if query string provided in command line
	if (firstDocument) {
		NSUserDefaults *args = [NSUserDefaults standardUserDefaults];
		NSString *searchTerm = [[args stringForKey:@"search"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if (searchTerm && searchTerm.length) {
			[searchField setStringValue:searchTerm];
			self.searchMode = CHMDocumentFileSearchInFile;
			[self search:self];
			firstDocument = NO;
		}
	}
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
	if (outError) *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	return nil;
}


- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError {
	MDLog(@"[%@ %@] url.path == %@, type == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), url.path, typeName);
	
	[filePath release];
	filePath = [[url path] retain];
	
	documentFile = [[CHMDocumentFile alloc] initWithContentsOfFile:filePath error:outError];
	
	documentFile.searchDelegate = self;
	
	return (documentFile != nil);
}


- (void)loadURL:(NSURL *)URL {
//	MDLog(@"[%@ %@] URL == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), URL);
	
	if (URL) {
		NSURLRequest *req = [NSURLRequest requestWithURL:URL];
		[[curWebView mainFrame] loadRequest:req];
	}
}

- (void)loadLinkItem:(CHMLinkItem *)anItem {
//	MDLog(@"[%@ %@] anItem == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), anItem);
	
	self.currentLinkItem = anItem;
	NSURL *url = [NSURL chm__ITSSURLWithPath:anItem.path];
	[self loadURL:url];
}


- (void)setPreference:(id)object forFile:(NSString *)filename withKey:(NSString *)key {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSMutableDictionary *filesInfoList = [NSMutableDictionary dictionaryWithDictionary:[defaults dictionaryForKey:PREF_FILES_INFO]];
	NSMutableDictionary *fileInfo = [NSMutableDictionary dictionaryWithDictionary:[filesInfoList objectForKey:filename]];
	[fileInfo setObject:object forKey:key];
	[fileInfo setObject:[NSDate date] forKey:PREF_UPDATED_AT];
	[filesInfoList setObject:fileInfo forKey:filename];
	
	if ([filesInfoList count] > 20) {
		NSDictionary *oldest = nil;
		NSString *oldestKey = nil;
		for (NSString *key in[filesInfoList allKeys]) {
			NSDictionary *info = [filesInfoList objectForKey:key];
			if (oldest == nil || [[oldest objectForKey:PREF_UPDATED_AT] compare:[info objectForKey:PREF_UPDATED_AT]] == NSOrderedDescending) {
				oldest = info;
				oldestKey = key;
			}
		}
		[oldestKey retain];
		if (oldestKey) [filesInfoList removeObjectForKey:oldestKey];
		[oldestKey release];
	}
	[defaults setObject:filesInfoList forKey:PREF_FILES_INFO];
}

- (id)getPreferenceforFile:(NSString *)filename withKey:(NSString *)key {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *filesInfoList = [defaults dictionaryForKey:PREF_FILES_INFO];
	if (filesInfoList == nil) {
		return nil;
	}
	NSDictionary *fileInfo = [filesInfoList objectForKey:filename];
	if (fileInfo == nil) {
		return nil;
	}
	return [fileInfo objectForKey:key];
}

#pragma mark - Properties
- (NSString *)currentURL {
	if (curWebView) {
		return [curWebView mainFrameURL];
	}
	return nil;
}

- (NSString *)currentTitle {
	if (curWebView) {
		return [[docTabView selectedTabViewItem] label];
	}
	return nil;
}


#pragma mark - <WebFrameLoadDelegate>
- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
	NSLog(@"[%@ %@] error == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error);
}

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
	NSLog(@"[%@ %@] error == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error);
}

- (void)webView:(WebView *)sender didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame {
	if (frame == [sender mainFrame]) {
//		MDLog(@"[%@ %@] title == \"%@\"", NSStringFromClass([self class]), NSStringFromSelector(_cmd), title);
	}
}


- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
//	MDLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
//	MDLog(@"[%@ %@] (frame == [sender mainFrame]) == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (frame == [sender mainFrame] ? @"YES" : @"NO"));
	
	NSURL *URL = [[[frame dataSource] request] URL];
	
	CHMLinkItem *newCurrentItem = [documentFile linkItemAtPath:URL.path];
	
	if (newCurrentItem) self.currentLinkItem = newCurrentItem;
	
	[self updateToolbarButtons];
	[self revealCurrentItemInOutlineView:nil];
	
	NSTabViewItem *tabItem = [docTabView selectedTabViewItem];
	NSString *name = currentLinkItem.name;
	if (name.length == 0) name = [curWebView mainFrameTitle];
	
	[tabItem setLabel:(name.length ? name : NSLocalizedString(@"(Untitled)", @"(Untitled)"))];
	
	if (frame == [sender mainFrame]) {
		[[curWebView windowScriptObject] setValue:console forKey:@"console"];
		[self loadJavascript];
		
		NSString *searchString = [searchField stringValue];
		
		if (searchString.length) {
			[self highlightString:searchString];
			[self findNext:self];
		}
	}
	
	// setup last path
	[self setPreference:URL.path forFile:filePath withKey:PREF_LAST_PATH];
}


#pragma mark - Javascript
- (void)loadJavascript {
	NSString *scriptPath = [[NSBundle mainBundle] pathForResource:@"highlight" ofType:@"js"];
	[self runJavascript:[NSString stringWithContentsOfFile:scriptPath encoding:NSUTF8StringEncoding error:NULL]];
}

- (void)runJavascript:(NSString *)script {
	[[curWebView windowScriptObject] evaluateWebScript:[NSString stringWithFormat:@"try{ %@; } catch(e){console.log(e.toString());}", script]];
}


#pragma mark - <WebPolicyDelegate>
- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener {
	
	if ([CHMITSSURLProtocol canInitWithRequest:request]) {
		
		int navigationType = [[actionInformation objectForKey:WebActionNavigationTypeKey] intValue];
		unsigned int modifier = [[actionInformation objectForKey:WebActionModifierFlagsKey] unsignedIntValue];
		
		// link click
		if (navigationType == WebNavigationTypeLinkClicked && modifier) {
			[self addNewTab:self];
			[[curWebView mainFrame] loadRequest:request];
			[listener ignore];
			return;
		}
		[listener use];
	} else {
		[[NSWorkspace sharedWorkspace] openURL:[request URL]];
		[listener ignore];
	}
}


- (void)webView:(WebView *)sender decidePolicyForNewWindowAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request newFrameName:(NSString *)frameName decisionListener:(id<WebPolicyDecisionListener>)listener {
//	MDLog(@"[%@ %@] request == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), request);
	
	if ([CHMITSSURLProtocol canInitWithRequest:request]) {
		[listener use];
	} else {
		[[NSWorkspace sharedWorkspace] openURL:[request URL]];
		[listener ignore];
	}
}

#pragma mark - <WebResourceLoadDelegate>
- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource {
//	MDLog(@"[%@ %@] request == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), request);
	
	if ([CHMITSSURLProtocol canInitWithRequest:request]) {
		NSMutableURLRequest *specialURLRequest = [[request mutableCopy] autorelease];
		[specialURLRequest setDocumentFile:documentFile];
		[specialURLRequest setEncodingName:documentFile.currentEncodingName];
		return specialURLRequest;
	} else {
		return request;
	}
}

#pragma mark - <WebUIDelegate>
- (WebView *)webView:(WebView *)sender createWebViewWithRequest:(NSURLRequest *)request {
	WebView *wv = [(CHMWebViewController *)[[self createWebViewInTab:sender] identifier] webView];
	[[wv mainFrame] loadRequest:request];
	return wv;
}

- (void)webViewShow:(WebView *)sender {
	
	for (NSTabViewItem *item in [docTabView tabViewItems]) {
		CHMWebViewController *chmwv = [item identifier];
		if ([chmwv webView] == sender) {
			curWebView = sender;
			[docTabView selectTabViewItem:item];
		}
	}
}

#pragma mark - IBActions
- (IBAction)changeTopic:(id)sender {
	NSInteger selectedRow = [outlineView selectedRow];
	
	if (selectedRow >= 0) {
		CHMLinkItem *topic = [outlineView itemAtRow:selectedRow];
		[self loadLinkItem:topic];
	}
}

- (IBAction)openInNewTab:(id)sender {
	[self addNewTab:sender];
	[self changeTopic:sender];
}

- (IBAction)goForward:(id)sender {
	[curWebView goForward];
}

- (IBAction)goBack:(id)sender {
	[curWebView goBack];
}

- (IBAction)goHome:(id)sender {
	[self loadLinkItem:[documentFile linkItemAtPath:documentFile.homePath]];
}

- (IBAction)goHistory:(id)sender {
	NSSegmentedCell *segCell = sender;
	switch ([segCell selectedSegment]) {
		case 0:
			[self goBack:sender];
			break;
		case 1:
			[self goForward:sender];
			break;
		default:
			break;
	}
}


- (IBAction)gotoNextPage:(id)sender {
	NSInteger selectedRow = [outlineView selectedRow];
	CHMLinkItem *topic = [outlineView itemAtRow:selectedRow];
	CHMLinkItem *nextPage = [documentFile.tableOfContents pageAfterPage:topic];
	if (nextPage) [self loadLinkItem:nextPage];
}

- (IBAction)gotoPrevPage:(id)sender {
	NSInteger selectedRow = [outlineView selectedRow];
	CHMLinkItem *topic = [outlineView itemAtRow:selectedRow];
	CHMLinkItem *prevPage = [documentFile.tableOfContents pageBeforePage:topic];
	if (prevPage) [self loadLinkItem:prevPage];
}

- (IBAction)revealCurrentItemInOutlineView:(id)sender {
//	MDLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
	if (!isSearching) {
		NSArray *ancestors = [currentLinkItem ancestors];
		
		for (CHMLinkItem *parent in ancestors) {
			[outlineView expandItem:parent];
		}
	}
	
	NSInteger currentItemIndex = [outlineView rowForItem:currentLinkItem];
	
	if (currentItemIndex == -1) return;
	
	[outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:currentItemIndex] byExtendingSelection:NO];
	[outlineView scrollRowToVisible:currentItemIndex];
}


- (IBAction)zoomIn:(id)sender {
	[curWebView makeTextLarger:sender];
	[self after_zoom];
}


- (IBAction)zoom:(id)sender {
	NSSegmentedCell *segCell = sender;
	switch ([segCell selectedSegment]) {
		case 0:
			[self zoomIn:sender];
			break;
		case 1:
			[self zoomOut:sender];
			break;
		default:
			break;
	}
}

- (IBAction)zoomOut:(id)sender {
	[curWebView makeTextSmaller:sender];
	[self after_zoom];
}

- (void)after_zoom {
	[textSizeControl setEnabled:[curWebView canMakeTextLarger] forSegment:0];
	[textSizeControl setEnabled:[curWebView canMakeTextSmaller] forSegment:1];
	float zoomFactor = [curWebView textSizeMultiplier];
	[[NSUserDefaults standardUserDefaults] setFloat:zoomFactor forKey:@"zoom factor"];
}


- (IBAction)printDocument:(id)sender {
	NSView *docView = [[[curWebView mainFrame] frameView] documentView];
    
    NSPrintOperation *op = [NSPrintOperation printOperationWithView:docView printInfo:[self printInfo]];
	
    [op setShowPanels:YES];
	
    [self runModalPrintOperation:op delegate:nil didRunSelector:NULL contextInfo:NULL];
	
}

- (void)updateToolbarButtons {
	[historyControl setEnabled:[curWebView canGoBack] forSegment:0];
	[historyControl setEnabled:[curWebView canGoForward] forSegment:1];
	[textSizeControl setEnabled:[curWebView canMakeTextLarger] forSegment:0];
	[textSizeControl setEnabled:[curWebView canMakeTextSmaller] forSegment:1];
}

#pragma mark - export to pdf
- (IBAction)exportToPDF:(id)sender {
	
	/* create or get the shared instance of NSSavePanel */
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	[savePanel setTitle:NSLocalizedString(@"Save as PDF", @"Save as PDF")];
	
	[savePanel setAllowedFileTypes:[NSArray arrayWithObjects:@"pdf", nil]];
	
	/* display the NSSavePanel */
	NSInteger runResult = [savePanel runModalForDirectory:nil file:[[filePath lastPathComponent] stringByDeletingPathExtension]];
	
	/* if successful, save file under designated name */
	if (runResult == NSOKButton) {
		NSURL *URL = [savePanel URL];
		exporter = [[CHMExporter alloc] initWithDocument:self destinationURL:URL pageList:documentFile.tableOfContents.pageList];
		exporter.delegate = self;
		[exporter beginExport];
	}
}


#pragma mark - <CHMExporterDelegate>
- (void)exporterDidBeginExporting:(CHMExporter *)anExporter {
//	MDLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	[exportProgressIndicator setIndeterminate:NO];
	[exportNoticeLabel setStringValue:NSLocalizedString(@"Save as PDF", @"Save as PDF")];
	[NSApp beginSheet:exportProgressSheet modalForWindow:documentWindow modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
}


- (void)exporter:(CHMExporter *)anExporter didExportPage:(NSUInteger)page percentageComplete:(CGFloat)percentageComplete {
	NSString *title = NSLocalizedString(@"Save as PDF", @"Save as PDF");
	NSString *label = [NSString stringWithFormat:@"%@ : %lu %@", title, (unsigned long)page, NSLocalizedString(@"pages", @"pages")];
	[exportNoticeLabel setStringValue:label];
	[exportProgressIndicator setDoubleValue:percentageComplete];
}


- (void)exporterDidFinishExporting:(CHMExporter *)anExporter {
	[NSApp endSheet:exportProgressSheet];
	[exportProgressSheet orderOut:nil];
	exporter.delegate = nil;
	[exporter autorelease];
	exporter = nil;
}
#pragma mark <CHMExporterDelegate>


#pragma mark - TabVew
- (void)setupTabBar {
	[tabBar setTabView:docTabView];
	[tabBar setPartnerView:docTabView];
	[tabBar setStyleNamed:@"Unified"];
	[tabBar setDelegate:self];
	[tabBar setShowAddTabButton:YES];
	[tabBar setSizeCellsToFit:YES];
	[[tabBar addTabButton] setTarget:self];
	[[tabBar addTabButton] setAction:@selector(addNewTab:)];
}

- (NSTabViewItem *)createWebViewInTab:(id)sender {
	CHMWebViewController *chmWebViewController = [[[CHMWebViewController alloc] init] autorelease];
	
	// init the webview
	WebView *newView = [chmWebViewController webView];
	[(CHMWebView *)newView setDocument:self];
	[newView setPreferencesIdentifier:WebVewPreferenceIndentifier];
	
	if ([webViews count] == 0) {
		// set preference
		WebPreferences *pref = [newView preferences];
		[pref setJavaScriptEnabled:YES];
		[pref setUserStyleSheetEnabled:YES];
		[pref setJavaScriptCanOpenWindowsAutomatically:YES];
		[pref setAutosaves:YES];
		NSString *stylePath = [[NSBundle mainBundle] pathForResource:@"ichm" ofType:@"css"];
		NSURL *styleURL = [[NSURL alloc] initFileURLWithPath:stylePath];
		[pref setUserStyleSheetLocation:styleURL];
		[styleURL release];
	}
	
	[newView setPolicyDelegate:self];
	[newView setFrameLoadDelegate:self];
	[newView setUIDelegate:self];
	[newView setResourceLoadDelegate:self];
	
	if ([[NSUserDefaults standardUserDefaults] floatForKey:@"zoom factor"] != 0) {
		[newView setTextSizeMultiplier:[[NSUserDefaults standardUserDefaults] floatForKey:@"zoom factor"]];
	}
	// NOTE: the tab view item retains the CHMWebViewController instance
	// create new tab item
	NSTabViewItem *newItem = [[[NSTabViewItem alloc] init] autorelease];
	[newItem setView:[chmWebViewController view]];
	[newItem setLabel:@"(Untitled)"];
	[newItem setIdentifier:chmWebViewController];
	
	// add to tab view
	[docTabView addTabViewItem:newItem];
	[webViews addObject:newView];
	
	return newItem;
}

- (IBAction)addNewTab:(id)sender {
	NSTabViewItem *item = [self createWebViewInTab:sender];
	curWebView = [(CHMWebViewController *)[item identifier] webView];
	[docTabView selectTabViewItem:item];
}


- (IBAction)closeTab:(id)sender {
	if ([webViews count] > 1) {
		NSTabViewItem *item = [docTabView selectedTabViewItem];
		[item retain];
		[docTabView removeTabViewItem:item];
		[[tabBar delegate] tabView:docTabView didCloseTabViewItem:item];
		[item release];
	} else {
		[self close];
	}
}


- (void)tabView:(NSTabView *)tabView didCloseTabViewItem:(NSTabViewItem *)tabViewItem {
	[webViews removeObject:[[tabViewItem identifier] webView]];
	[self updateToolbarButtons];
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
	curWebView = [(CHMWebViewController *)[tabViewItem identifier] webView];
	[self updateToolbarButtons];
}

- (IBAction)chmDocumentSelectNextTabViewItem:(id)sender {
	NSInteger tabViewItemCount = docTabView.numberOfTabViewItems;
	NSInteger currentTabViewItemIndex = [docTabView indexOfTabViewItem:[docTabView selectedTabViewItem]];
	if (currentTabViewItemIndex == tabViewItemCount - 1) {
		[docTabView selectFirstTabViewItem:sender];
	} else {
		[docTabView selectNextTabViewItem:sender];
	}
}

- (IBAction)chmDocumentSelectPreviousTabViewItem:(id)sender {
	NSInteger currentIndex = [docTabView indexOfTabViewItem:[docTabView selectedTabViewItem]];
	if (currentIndex == 0) {
		[docTabView selectLastTabViewItem:sender];
	} else {
		[docTabView selectPreviousTabViewItem:sender];
	}
}

#pragma mark - Toolbar
- (void)setupToolbar {
	NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:ICHMToolbarIdentifier] autorelease];
	
	[toolbar setAllowsUserCustomization:YES];
	[toolbar setAutosavesConfiguration:YES];
	
	[toolbar setDelegate:self];
	
	[documentWindow setToolbar:toolbar];
	
}


- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
	return [NSArray arrayWithObjects:HistoryToolbarItemIdentifier, TextSizeToolbarItemIdentifier, NSToolbarSeparatorItemIdentifier, NSToolbarPrintItemIdentifier,
			NSToolbarSpaceItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, SidebarToolbarItemIdentifier, SearchToolbarItemIdentifier, nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
	return [NSArray arrayWithObjects:HistoryToolbarItemIdentifier, HomeToolbarItemIdentifier, TextSizeToolbarItemIdentifier, NSToolbarPrintItemIdentifier, NSToolbarSeparatorItemIdentifier,
			NSToolbarSpaceItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, SidebarToolbarItemIdentifier, SearchToolbarItemIdentifier, nil];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdent willBeInsertedIntoToolbar:(BOOL)willBeInserted {
	NSToolbarItem *toolbarItem = nil;
	if ([itemIdent isEqual:TextSizeToolbarItemIdentifier]) {
		toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdent] autorelease];
		
		[toolbarItem setLabel:NSLocalizedString(@"Zoom", @"Zoom")];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Zoom", @"Zoom")];
		
		[toolbarItem setToolTip:NSLocalizedString(@"Zoom", @"Zoom")];
		[toolbarItem setView:textSizeControl];
		[textSizeControl setEnabled:[curWebView canMakeTextLarger] forSegment:0];
		[textSizeControl setEnabled:[curWebView canMakeTextSmaller] forSegment:1];
	} else if ([itemIdent isEqual:HistoryToolbarItemIdentifier]) {
		toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdent] autorelease];
		
		[toolbarItem setLabel:NSLocalizedString(@"History", @"History")];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"History", @"History")];
		
		[toolbarItem setToolTip:NSLocalizedString(@"Navigate in History", @"Navigate in History")];
		[toolbarItem setView:historyControl];
		[historyControl setEnabled:NO forSegment:0];
		[historyControl setEnabled:NO forSegment:1];
	} else if ([itemIdent isEqual:HomeToolbarItemIdentifier]) {
		toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdent] autorelease];
		
		[toolbarItem setLabel:NSLocalizedString(@"Home", @"Home")];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Home", @"Home")];
		
		[toolbarItem setToolTip:NSLocalizedString(@"Back to Home", @"Back to Home")];
		[toolbarItem setView:homeButton];
	} else if ([itemIdent isEqual:SidebarToolbarItemIdentifier]) {
		toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdent] autorelease];
		
		[toolbarItem setLabel:NSLocalizedString(@"Sidebar", @"Sidebar")];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Sidebar", @"Sidebar")];
		
		[toolbarItem setToolTip:NSLocalizedString(@"Toggle Sidebar", @"Toggle Sidebar")];
		[toolbarItem setView:toggleSidebarButton];
	} else if ([itemIdent isEqual:SearchToolbarItemIdentifier]) {
		toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdent] autorelease];
		
		[toolbarItem setLabel:NSLocalizedString(@"Search", @"Search")];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Search", @"Search")];
		
		[toolbarItem setToolTip:NSLocalizedString(@"Search", @"Search")];
		[toolbarItem setView:searchField];
		
	} else {
		// itemIdent refered to a toolbar item that is not provide or supported by us or cocoa
		// Returning nil will inform the toolbar this kind of item is not supported
		toolbarItem = nil;
	}
	return toolbarItem;
}


#pragma mark - <CHMDocumentFileSearchDelegate>


- (void)documentFile:(CHMDocumentFile *)aDocumentFile didUpdateSearchResults:(NSArray *)aSearchResults {
	MDLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	[searchResults setArray:aSearchResults];
	[outlineView reloadData];
}


#pragma mark <CHMDocumentFileSearchDelegate>
#pragma mark - Search
- (IBAction)changeSearchMode:(id)sender {
	NSInteger tag = [sender tag];
	if (searchMode == tag) return;
	self.searchMode = tag;
	[[searchField cell] setPlaceholderString:(searchMode == CHMDocumentFileSearchInFile ? NSLocalizedString(@"Search in File", @"") : NSLocalizedString(@"Search in Index", @""))];
	
	[self setPreference:(searchMode == CHMDocumentFileSearchInFile ? PREF_VALUE_SEARCH_IN_FILE : PREF_VALUE_SEARCH_IN_INDEX) forFile:filePath withKey:PREF_SEARCH_TYPE];
	
	if ([searchField stringValue].length) [self search:self];
	
}


- (IBAction)search:(id)sender {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	NSString *searchString = [searchField stringValue];
	
	if (searchString.length == 0) {
		
		isSearching = NO;
		
		[searchResults removeAllObjects];
		
		[outlineView reloadData];
		
		if (viewMode == CHMDocumentViewTableOfContents) {
			[[[outlineView outlineTableColumn] headerCell] setStringValue:NSLocalizedString(@"Contents", @"Contents")];
			[self revealCurrentItemInOutlineView:nil];
			
		} else if (viewMode == CHMDocumentViewIndex) {
			[[[outlineView outlineTableColumn] headerCell] setStringValue:NSLocalizedString(@"Index", @"Index")];
			
		}
		
		[self removeHighlight];
		return;
	}
	
	isSearching = YES;
	
	[searchResults removeAllObjects];
	
	[[[outlineView outlineTableColumn] headerCell] setStringValue:NSLocalizedString(@"Search", @"Search")];
	
	[outlineView deselectAll:nil];
	
	[documentFile searchForString:searchString usingMode:searchMode];
	
}


- (IBAction)focusOnSearch:(id)sender {
	[documentWindow makeFirstResponder:searchField];
}

#pragma mark - find panel
- (IBAction)showFindPanel:(id)sender {
	return [(CHMWebViewController *)[[docTabView selectedTabViewItem] identifier] showFindPanel:sender];
}

- (IBAction)beginFind:(id)sender {
	NSString *searchString = [[[[docTabView selectedTabViewItem] identifier] searchField] stringValue];
	if (searchString.length == 0) {
		[self removeHighlight];
		return;
	}
	[self highlightString:searchString];
	[self findNext:sender];
}

- (void)highlightString:(NSString *)pattern {
	[self runJavascript:[NSString stringWithFormat:@"highlight(document.body, '%@')", pattern]];
}

- (void)removeHighlight {
	[self runJavascript:@"removeHighlight();"];
}

- (IBAction)findNext:(id)sender {
	[self runJavascript:[NSString stringWithFormat:@"scrollToHighlight(%d)", 1]];
}

- (IBAction)findPrev:(id)sender {
	[self runJavascript:[NSString stringWithFormat:@"scrollToHighlight(%d)", -1]];
}


- (IBAction)findInFile:(id)sender {
	NSSegmentedCell *segCell = sender;
	if ([segCell selectedSegment] == 0) {
		[self findPrev:sender];
	} else {
		[self findNext:sender];
	}
}

- (IBAction)doneFind:(id)sender {
	[(CHMWebViewController *)[[docTabView selectedTabViewItem] identifier] hideFindPanel:sender];
	[self removeHighlight];
}


#pragma mark - text encoding

- (IBAction)changeEncoding:(id)sender {
	MDLog(@"[%@ %@] sender == %@, tag == %ld", NSStringFromClass([self class]), NSStringFromSelector(_cmd), sender, (long)[sender tag]);
	
	NSInteger tag = [sender tag];
	id representedObject = [sender representedObject];
	
	// get the path of the currentLinkItem
	NSString *previousCurrentItemPath = [[currentLinkItem.path retain] autorelease];
	
	if (tag == 0 && documentFile.customEncoding) {
		// go back to default encoding
		[documentFile setCustomEncoding:CHMDocumentFileDefaultStringEncoding customEncodingName:nil];
		
	} else if ((tag && documentFile.customEncoding == 0)		    // set a custom encoding
			   || (tag && tag != documentFile.customEncoding)) {	// set a different custom encoding
		
		NSString *customEncodingName = nil;
		
		if ([representedObject isKindOfClass:[NSString class]]) {
			customEncodingName = (NSString *)representedObject;
			
		} else {
			customEncodingName = (NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(tag));
			
		}
		[documentFile setCustomEncoding:tag customEncodingName:customEncodingName];
		
		MDLog(@"[%@ %@] customEncoding == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), [NSString localizedNameOfStringEncoding:tag]);
		MDLog(@"[%@ %@] customEncodingName == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), customEncodingName);
		
	} else {
		return;
	}
	// Setting a new encoding will recreate the table of contents and CHMLinkItem tree, so our currentLinkItem is no longer valid; replace it with the new one at the same path.
	self.currentLinkItem = [documentFile linkItemAtPath:previousCurrentItemPath];
	
	for (WebView *webView in webViews) {
		[webView setCustomTextEncodingName:documentFile.currentEncodingName];
	}
	
	[outlineView reloadData];
	[self revealCurrentItemInOutlineView:nil];
}


#pragma mark - (NSMenuValidation)

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	MDLog(@"[%@ %@] menuItem == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), menuItem);
	SEL action = [menuItem action];
	NSInteger tag = [menuItem tag];
	
	if (action == @selector(changeSearchMode:)) {
		[menuItem setState:searchMode == tag];
		if (tag == CHMDocumentFileSearchInIndex) {
			return (documentFile.index != nil);
		}
	} else if (action == @selector(changeViewMode:)) {
		[menuItem setState:viewMode == tag];
		if (tag == CHMDocumentViewIndex) {
			return (documentFile.index != nil);
		}
	} else if (action == @selector(changeEncoding:)) {
		if (tag == 0) {
			NSFont *menuFont = menuItem.menu.font;
			if (menuFont == nil) menuFont = [NSFont menuFontOfSize:[NSFont systemFontSize] + 1];
			
			NSMutableAttributedString *mTitle = [[[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"Automatic ", @"Automatic ")
																						attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																									menuFont,NSFontAttributeName, nil]] autorelease];
			
			NSString *locDescription = [NSString localizedNameOfStringEncoding:documentFile.encoding];
			if (locDescription) {
				NSAttributedString *attrLocDescription = [[[NSAttributedString alloc] initWithString:locDescription
																						  attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																									  menuFont,NSFontAttributeName,
																									  [NSColor selectedTextBackgroundColor],NSForegroundColorAttributeName, nil]] autorelease];
				[mTitle appendAttributedString:attrLocDescription];
			}
			
			[menuItem setAttributedTitle:mTitle];
		}
		
		[menuItem setState:documentFile.customEncoding == tag];
		
	} else if (action == @selector(zoomIn:)) {
		return [curWebView canMakeTextLarger];
		
	} else if (action == @selector(zoomOut:)) {
		return [curWebView canMakeTextSmaller];
		
	} else if (action == @selector(chmDocumentSelectNextTabViewItem:) ||
			   action == @selector(chmDocumentSelectPreviousTabViewItem:)) {
		return docTabView.numberOfTabViewItems > 1;
		
	}
	return YES;
}


#pragma mark - <NSSplitViewDelegate>
- (void)splitViewDidResizeSubviews:(NSNotification *)aNotification {
	if (!isSidebarRestored) {
		return;
	}
	NSView *sidebarView = [[splitView subviews] objectAtIndex:1];
	CGFloat curWidth = [sidebarView frame].size.width;
	if (curWidth > MinSidebarWidth) {
		[[NSUserDefaults standardUserDefaults] setFloat:curWidth forKey:SidebarWidthName];
	}
}

#pragma mark -
- (void)restoreSidebar {
	CGFloat width = [[NSUserDefaults standardUserDefaults] floatForKey:SidebarWidthName];
	if (width < MinSidebarWidth) {
		width = MinSidebarWidth;
	}
	CGFloat newpos = [splitView frame].size.width - width;
	isSidebarRestored = YES;
	[splitView setPosition:newpos ofDividerAtIndex:0];
}

- (IBAction)toggleSidebar:(id)sender {
	CGFloat curWidth = [outlineView frame].size.width;
	if (curWidth > 30) {
		[self hideSidebar:sender];
	} else {
		[self restoreSidebar];
	}
}

- (IBAction)hideSidebar:(id)sender {
	[splitView setPosition:[splitView maxPossiblePositionOfDividerAtIndex:0] ofDividerAtIndex:0];
}


#pragma mark - <NSOutlineViewDelegate>
- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
	[self changeTopic:self];
}

#pragma mark -

- (CHMTableOfContents *)currentDataSource {
	if (viewMode == CHMDocumentViewTableOfContents) {
		return documentFile.tableOfContents;
	} else if (viewMode == CHMDocumentViewIndex) {
		return documentFile.index;
	}
	return nil;
}


#pragma mark - <NSOutlineViewDataSource>
- (NSInteger)outlineView:(NSOutlineView *)anOutlineView numberOfChildrenOfItem:(id)item {
	if (item == nil) {
		if (isSearching) {
			return searchResults.count;
		} else {
			item = [self currentDataSource].linkItems;
		}
	}
    return [(CHMLinkItem *)item numberOfChildren];
}


- (BOOL)outlineView:(NSOutlineView *)anOutlineView isItemExpandable:(id)item {
//	MDLog(@"[%@ %@] item == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), item);
	
	if (isSearching) {
		return NO;
	}
    return [(CHMLinkItem *)item numberOfChildren] > 0;
}

- (id)outlineView:(NSOutlineView *)anOutlineView child:(NSInteger)theIndex ofItem:(id)item {
	if (isSearching) {
		if (item == nil) {
			CHMSearchResult *searchResult = [searchResults objectAtIndex:theIndex];
			return searchResult.linkItem;
		}
		return nil;
	}
	if (item == nil) item = [self currentDataSource].linkItems;
    return [(CHMLinkItem *)item childAtIndex:theIndex];
}

- (id)outlineView:(NSOutlineView *)anOutlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    return [(CHMLinkItem *)item name];
}



#pragma mark <NSOutlineViewDataSource>
#pragma mark - Bookmark
- (IBAction)showAddBookmark:(id)sender {
	CHMAppController *chmapp = [NSApp delegate];
	BookmarkController *bookmarkController = [chmapp bookmarkController];
	[bookmarkController showAddBookmark:self];
}

#pragma mark sidebar view changing
- (IBAction)changeViewMode:(id)sender {
	MDLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
	NSInteger tag = [sender tag];
	if (viewMode == tag) return;
	self.viewMode = tag;
	
	[outlineView reloadData];
	
	if (viewMode == CHMDocumentViewTableOfContents) {
		[[[outlineView outlineTableColumn] headerCell] setStringValue:NSLocalizedString(@"Contents", @"Contents")];
		[self revealCurrentItemInOutlineView:nil];
		
	} else if (viewMode == CHMDocumentViewIndex) {
		[[[outlineView outlineTableColumn] headerCell] setStringValue:NSLocalizedString(@"Index", @"Index")];
		
	}
}


@end

