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


@class CHMTableOfContents;
@class CHMSearchResults;
@class CHMLinkItem;
@class CHMConsole;
struct chmFile;


enum {
	CHMDocumentSearchInFile		= 1,
	CHMDocumentSearchInIndex	= 2,
};
typedef NSUInteger CHMDocumentSearchMode;


enum {
	CHMDocumentViewTableOfContents	= 1,
	CHMDocumentViewIndex			= 2,
};
typedef NSUInteger CHMDocumentViewMode;


#ifdef MAC_OS_X_VERSION_10_11
@interface CHMDocument : NSDocument <NSToolbarDelegate, NSMenuDelegate, NSSplitViewDelegate, NSOutlineViewDelegate, NSOutlineViewDataSource, PSMTabBarControlDelegate, WebPolicyDelegate, WebResourceLoadDelegate, WebFrameLoadDelegate, WebUIDelegate> {
#else
@interface CHMDocument : NSDocument <NSToolbarDelegate, NSMenuDelegate, NSSplitViewDelegate, NSOutlineViewDelegate, NSOutlineViewDataSource, PSMTabBarControlDelegate> {
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
	
	struct chmFile					*chmFileHandle;
	NSString						*filePath;
	
    NSString						*docTitle;
    NSString						*homePath;
    NSString						*tableOfContentsPath;
    NSString						*indexPath;
	
	CHMTableOfContents				*tableOfContents;
	CHMTableOfContents				*index;
	CHMSearchResults				*searchResults;
	
	CHMDocumentSearchMode			searchMode;
	CHMDocumentViewMode				viewMode;
	BOOL							isSearching;
	
	SKIndexRef						skIndex;
	NSMutableData					*searchIndexObject;
	BOOL							isIndexDone;
	NSCondition						*searchIndexCondition;
	
	BOOL							isSidebarRestored;
	
	NSMutableArray					*webViews;
	WebView							*curWebView;
	CHMConsole						*console;
	
	NSStringEncoding				encoding;
	NSString						*encodingName;
	
	NSStringEncoding				customEncoding;
	NSString						*customEncodingName;
	
}

@property (readonly) NSString *filePath;
@property (readonly) NSString *docTitle;

@property (readonly, assign) NSStringEncoding encoding;
@property (readonly, retain) NSString *encodingName;

@property (assign) NSStringEncoding customEncoding;
@property (retain) NSString *customEncodingName;

@property (nonatomic, readonly, retain) NSString *currentEncodingName;

@property (nonatomic, assign) CHMDocumentSearchMode	searchMode;

@property (nonatomic, assign) CHMDocumentViewMode viewMode;


- (NSString*)currentURL;
- (NSString*)currentTitle;
- (NSURL*)composeURL:(NSString *)path;

- (BOOL)hasObjectAtPath:(NSString *)path;
- (NSData *)dataForObjectAtPath:(NSString *)path;


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

// dump to pdf
- (IBAction)exportToPDF:(id)sender;
- (IBAction)showExportProgressSheet:(id)sender;
- (IBAction)endExportProgressSheet:(id)sender;
- (void)exportedProgressRate:(double)rate PageCount:(NSInteger)count;

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

//text encoding
- (IBAction)changeEncoding:(id)sender;

@end


