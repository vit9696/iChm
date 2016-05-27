//
//  CHMDocument.h
//  ichm
//
//  Created by Robin Lu on 7/16/08.
//  Copyright __MyCompanyName__ 2008 . All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <AvailabilityMacros.h>
#import <PSMTabBarControl/PSMTabBarControl.h>
#import <CHMKit/CHMKit.h>
#import "CHMExporter.h"


@class CHMConsole;
@class CHMBookmark;



enum {
	CHMDocumentViewTableOfContents	= 1,
	CHMDocumentViewIndex			= 2,
};
typedef NSUInteger CHMDocumentViewMode;


#ifdef MAC_OS_X_VERSION_10_11
@interface CHMDocument : NSDocument <NSToolbarDelegate, NSMenuDelegate, NSSplitViewDelegate, NSOutlineViewDelegate, NSOutlineViewDataSource, PSMTabBarControlDelegate, CHMDocumentFileSearchDelegate, CHMExporterDelegate, WebPolicyDelegate, WebResourceLoadDelegate, WebFrameLoadDelegate, WebUIDelegate> {
#else
@interface CHMDocument : NSDocument <NSToolbarDelegate, NSMenuDelegate, NSSplitViewDelegate, NSOutlineViewDelegate, NSOutlineViewDataSource, PSMTabBarControlDelegate, CHMDocumentFileSearchDelegate, CHMExporterDelegate> {
#endif
	
	IBOutlet PSMTabBarControl		*tabBar;
	IBOutlet NSTabView				*docTabView;
	IBOutlet NSOutlineView			*outlineView;
	IBOutlet NSWindow				*documentWindow;
	
	IBOutlet NSSegmentedControl		*historyControl;
	IBOutlet NSButton				*homeButton;
	IBOutlet NSSegmentedControl		*textSizeControl;
	IBOutlet NSButton				*toggleSidebarButton;
	IBOutlet NSSearchField			*searchField;
	
	IBOutlet NSSplitView			*splitView;
	IBOutlet NSMenu					*sidebarViewMenu;
	
	IBOutlet NSWindow				*exportProgressSheet;
	IBOutlet NSProgressIndicator	*exportProgressIndicator;
	IBOutlet NSTextField			*exportNoticeLabel;
	
	NSString						*filePath;
	
	NSMutableArray					*searchResults;
	
	
	CHMDocumentFileSearchMode		searchMode;
	CHMDocumentViewMode				viewMode;
	BOOL							isSearching;
	
	BOOL							isSidebarRestored;
	
	NSMutableArray					*webViews;
	WebView							*curWebView;
	CHMConsole						*console;
	
	CHMDocumentFile					*documentFile;
	
	CHMLinkItem						*currentLinkItem;
	
	BOOL							ignoreOutlineViewSelectionChanges;
	
	CHMBookmark						*pendingBookmarkToLoad;
	
	CHMExporter						*exporter;
	
}

@property (readonly) NSString *filePath;

@property (nonatomic, assign) CHMDocumentFileSearchMode	searchMode;

@property (nonatomic, assign) CHMDocumentViewMode viewMode;

@property (nonatomic, retain) CHMDocumentFile *documentFile;

@property (nonatomic, retain) CHMLinkItem *currentLinkItem;

@property (nonatomic, retain) CHMBookmark *pendingBookmarkToLoad;


- (NSString *)currentURL;
- (NSString *)currentTitle;


- (void)loadURL:(NSURL *)url;

- (IBAction)changeTopic:(id)sender;
- (IBAction)openInNewTab:(id)sender;

- (IBAction)goForward:(id)sender;
- (IBAction)goBack:(id)sender;
- (IBAction)goHistory:(id)sender;
- (IBAction)goHome:(id)sender;
- (IBAction)gotoNextPage:(id)sender;
- (IBAction)gotoPrevPage:(id)sender;


// dump to pdf
- (IBAction)exportToPDF:(id)sender;

// search
- (IBAction)changeSearchMode:(id)sender;
- (IBAction)search:(id)sender;
- (IBAction)focusOnSearch:(id)sender;

// sidebar view
- (IBAction)changeViewMode:(id)sender;
- (IBAction)toggleSidebar:(id)sender;


- (IBAction)zoom:(id)sender;
- (IBAction)zoomIn:(id)sender;
- (IBAction)zoomOut:(id)sender;



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
- (IBAction)chmDocumentSelectNextTabViewItem:(id)sender;
- (IBAction)chmDocumentSelectPreviousTabViewItem:(id)sender;


//text encoding
- (IBAction)changeEncoding:(id)sender;

@end


