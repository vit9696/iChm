//
//  CHMDocument.h
//  ichm
//
//  Created by Robin Lu on 7/16/08.
//  Copyright __MyCompanyName__ 2008 . All rights reserved.
//


#import <Cocoa/Cocoa.h>

@class WebView;
@class CHMTableOfContent;
@class CHMSearchResult;
@class LinkItem;
@class PSMTabBarControl;
@class CHMConsole;
struct chmFile;

@interface CHMDocument : NSDocument {
	IBOutlet PSMTabBarControl *tabBar;
	IBOutlet NSTabView *docTabView;
	IBOutlet NSOutlineView *tocView;
	IBOutlet NSWindow *documentWindow;
	IBOutlet NSSegmentedControl *historyItemView;
	IBOutlet NSButton *homeItemView;
	IBOutlet NSSegmentedControl *textSizeItemView;
	IBOutlet NSButton* sidebarItemView;
	IBOutlet NSSearchField *searchItemView;
	IBOutlet NSSplitView *splitView;
	IBOutlet NSMenuItem *textEncodingMenu;
	IBOutlet NSPanel *addBookmarkPanel;
	IBOutlet NSMenu *sidebarViewMenu;
	
	IBOutlet NSWindow *exportProgressSheet;
	IBOutlet NSProgressIndicator *exportProgressIndicator;
	IBOutlet NSTextField *exportNoticeLabel;
	
	struct chmFile *chmFileHandle;
	NSString *filePath;
	
    NSString *docTitle;
    NSString *homePath;
    NSString *tocPath;
    NSString *indexPath;
	
	CHMTableOfContent *tocSource ;
	CHMTableOfContent *indexSource ;
	CHMSearchResult *searchSource;
	
	SKIndexRef skIndex;
	NSMutableData *searchIndexObject;
	BOOL isIndexDone;
	NSCondition *searchIndexCondition;
	
	BOOL isSidebarRestored;
	
	NSMutableArray *webViews;
	WebView *curWebView;
	CHMConsole *console;
	
	int customizedEncodingTag;
	NSString* encodingName;
}

@property (readonly) NSString* filePath;
@property (readonly) NSString* docTitle;

- (NSString*)currentURL;
- (NSString*)currentTitle;
- (NSURL*)composeURL:(NSString *)path;

- (BOOL) exist: (NSString *)path;
- (NSData *)content: (NSString *)path;
- (BOOL)loadMetadata;

- (NSString *)findHomeForPath: (NSString *)basePath;
- (void)highlightString:(NSString*)pattern;
- (void)removeHighlight;
- (void)buildSearchIndex;

- (void)loadURL:(NSURL *)url;

- (IBAction)changeTopic:(id)sender;
- (IBAction)openInNewTab:(id)sender;

- (IBAction)goForward:(id)sender;
- (IBAction)goBack:(id)sender;
- (IBAction)goHistory:(id)sender;
- (IBAction)goHome:(id)sender;
- (IBAction)gotoNextPage:(id)sender;
- (IBAction)gotoPrevPage:(id)sender;

- (IBAction)locateTOC:(id)sender;

// file preferences
- (void)setLastPath:(NSString*)path forFile:(NSString*)filename;
- (NSString*)getLoastURLforFile:(NSString*)filename;

// dump to pdf
- (IBAction)exportToPDF:(id)sender;
- (IBAction)showExportProgressSheet:(id)sender;
- (IBAction)endExportProgressSheet:(id)sender;
- (void)exportedProgressRate:(double)rate PageCount:(int)count;

// search
- (IBAction)setSearchInFile:(id)sender;
- (IBAction)setSearchInIndex:(id)sender;
- (IBAction)searchInFile:(id)sender;
- (IBAction)searchInIndex:(id)sender;
- (IBAction)focusOnSearch:(id)sender;

// sidebar view
- (IBAction)popViewMenu:(id)sender;
- (IBAction)changeToContentsView:(id)sender;
- (IBAction)changeToIndexView:(id)sender;
- (void)resetViewMenuState:(NSMenuItem*)sender;
- (void)resetSidebarView;

- (IBAction)zoom:(id)sender;
- (IBAction)zoomIn:(id)sender;
- (IBAction)zoomOut:(id)sender;

- (IBAction)toggleSidebar:(id)sender;
- (IBAction)hideSidebar:(id)sender;

- (void)addToSearchIndex:(const char*)path;

// find panel
- (IBAction)showFindPanel:(id)sender;
- (IBAction)beginFind:(id)sender;
- (IBAction)findNext:(id)sender;
- (IBAction)findPrev:(id)sender;
- (IBAction)findInFile:(id)sender;
- (IBAction)doneFind:(id)sender;

// bookmark
- (IBAction)showAddBookmark:(id)sender;

// tab
- (IBAction)addNewTab:(id)sender;
- (IBAction)closeTab:(id)sender;

//text encoding
- (void)setupEncodingMenu;
- (void)resetEncodingMenu;
- (IBAction)changeEncoding:(id)sender;
- (NSString*)getEncodingByTag:(int)tag;
- (NSString*)currentEncodingName;

@end
