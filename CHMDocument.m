//
//  CHMDocument.m
//  ichm
//
//  Created by Robin Lu on 7/16/08.
//  Copyright __MyCompanyName__ 2008 . All rights reserved.
//

#import "CHMDocument.h"
#import <CHM/CHM.h>
#import <PSMTabBarControl/PSMTabBarControl.h>
#import "ITSSProtocol.h"
#import "CHMTableOfContents.h"
#import "CHMWebViewController.h"
#import "CHMAppController.h"
#import "CHMTextEncodingMenuController.h"
#import "BookmarkController.h"
#import "CHMWebView.h"
#import "CHMExporter.h"
#import "lcid.h"
#import "LinkItem.h"


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


@interface CHMDocument (Private)

- (BOOL)loadMetadata;
- (void)buildSearchIndex;
- (void)removeHighlight;
- (void)highlightString:(NSString *)pattern;
- (NSString *)findHomeForPath:(NSString *)basePath;

// file preferences
- (void)setPreference:(id)object forFile:(NSString *)filename withKey:(NSString *)key;
- (id)getPreferenceforFile:(NSString *)filename withKey:(NSString *)key;


- (void)addToSearchIndex:(const char *)path;


- (void)setupToolbar;
- (void)updateHistoryButton;
- (void)loadPath:(NSString *)path;

- (NSString *)extractPathFromURL:(NSURL *)url;

- (void)prepareSearchIndex;

- (void)setupTabBar;
- (void)loadJavascript;
- (void)runJavascript:(NSString *)script;

- (void)restoreSidebar;

- (void)after_zoom;

- (NSTabViewItem *)createWebViewInTab:(id)sender;

- (void)setupTOCSource;

- (IBAction)hideSidebar:(id)sender;

@end



@implementation CHMDocument

@synthesize filePath;
@synthesize docTitle;


@synthesize searchMode;

@synthesize viewMode;


- (id)init {
	if ((self = [super init])) {
		
		// Add your subclass-specific initialization here.
		// If an error occurs here, send a [self release] message and return nil.
		isIndexDone = NO;
		searchIndexCondition = [[NSCondition alloc] init];
		
		webViews = [[NSMutableArray alloc] init];
		console = [[CHMConsole alloc] init];
		
		isSidebarRestored = NO;
		
		searchMode = CHMDocumentSearchInFile;
		viewMode = CHMDocumentViewTableOfContents;
	}
	return self;
}

- (void)dealloc {
	if (chmFileHandle) {
		chm_close(chmFileHandle);
	}
	[filePath release];
	[docTitle release];
	[homePath release];
	[tableOfContentsPath release];
	[indexPath release];
	[tocSource release];
	[searchSource release];
	
	if (skIndex) SKIndexClose(skIndex);
	
	[searchIndexObject release];
	[searchIndexCondition release];

	[webViews release];
	[super dealloc];
}

#pragma mark Basic CHM reading operations
static inline NSStringEncoding nameToEncoding(NSString *name) {
	if(!name || [name length] == 0)
		return NSUTF8StringEncoding;
	
	return CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)name));
}

static inline unsigned short readShort(NSData *data, NSUInteger offset) {
	unsigned short value;
	[data getBytes:(void *)&value range:NSMakeRange(offset, 2)];
	return NSSwapLittleShortToHost(value);
}

static inline uint32_t readInt(NSData *data, NSUInteger offset) {
	uint32_t value = 0;
	[data getBytes:&value range:NSMakeRange(offset, 4)];
	return NSSwapLittleIntToHost(value);
}

static inline NSString *readString(NSData *data, NSUInteger offset, NSString *encodingName) {
	const char *stringData = (char *)[data bytes] + offset;
	return [[[NSString alloc] initWithCString:stringData encoding:nameToEncoding(encodingName)] autorelease];
}

static inline NSString *readTrimmedString(NSData *data, NSUInteger offset, NSString *encodingName) {
	NSString *str = readString(data, offset, encodingName);
	return [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

static inline NSString *LCIDtoEncodingName(unsigned int lcid) {
	NSString *name = nil;
	switch (lcid) {
		case LCID_CS: //1250
		case LCID_HR: //1250
		case LCID_HU: //1250
		case LCID_PL: //1250
		case LCID_RO: //1250
		case LCID_SK: //1250
		case LCID_SL: //1250
		case LCID_SQ: //1250
		case LCID_SR_SP: //1250
			name = @"CP1250";
			break;
		case LCID_AZ_CY: //1251
		case LCID_BE: //1251
		case LCID_BG: //1251
		case LCID_MS_MY: //1251
		case LCID_RU: //1251
		case LCID_SB: //1251
		case LCID_SR_SP2: //1251
		case LCID_TT: //1251
		case LCID_UK: //1251
		case LCID_UZ_UZ2: //1251
		case LCID_YI: //1251
			name = @"CP1251";
			break;
		case LCID_AF: //1252
		case LCID_CA: //1252
		case LCID_DA: //1252
		case LCID_DE_AT: //1252
		case LCID_DE_CH: //1252
		case LCID_DE_DE: //1252
		case LCID_DE_LI: //1252
		case LCID_DE_LU: //1252
		case LCID_EN_AU: //1252
		case LCID_EN_BZ: //1252
		case LCID_EN_CA: //1252
		case LCID_EN_CB: //1252
		case LCID_EN_GB: //1252
		case LCID_EN_IE: //1252
		case LCID_EN_JM: //1252
		case LCID_EN_NZ: //1252
		case LCID_EN_PH: //1252
		case LCID_EN_TT: //1252
		case LCID_EN_US: //1252
		case LCID_EN_ZA: //1252
		case LCID_ES_AR: //1252
		case LCID_ES_BO: //1252
		case LCID_ES_CL: //1252
		case LCID_ES_CO: //1252
		case LCID_ES_CR: //1252
		case LCID_ES_DO: //1252
		case LCID_ES_EC: //1252
		case LCID_ES_ES: //1252
		case LCID_ES_GT: //1252
		case LCID_ES_HN: //1252
		case LCID_ES_MX: //1252
		case LCID_ES_NI: //1252
		case LCID_ES_PA: //1252
		case LCID_ES_PE: //1252
		case LCID_ES_PR: //1252
		case LCID_ES_PY: //1252
		case LCID_ES_SV: //1252
		case LCID_ES_UY: //1252
		case LCID_ES_VE: //1252
		case LCID_EU: //1252
		case LCID_FI: //1252
		case LCID_FO: //1252
		case LCID_FR_BE: //1252
		case LCID_FR_CA: //1252
		case LCID_FR_CH: //1252
		case LCID_FR_FR: //1252
		case LCID_FR_LU: //1252
		case LCID_GD: //1252
		case LCID_HI: //1252
		case LCID_ID: //1252
		case LCID_IS: //1252
		case LCID_IT_CH: //1252
		case LCID_IT_IT: //1252
		case LCID_MS_BN: //1252
		case LCID_NL_BE: //1252
		case LCID_NL_NL: //1252
		case LCID_NO_NO: //1252
		case LCID_NO_NO2: //1252
		case LCID_PT_BR: //1252
		case LCID_PT_PT: //1252
		case LCID_SV_FI: //1252
		case LCID_SV_SE: //1252
		case LCID_SW: //1252
			name = @"CP1252";
			break;
		case LCID_EL: //1253
			name = @"CP1253";
			break;
		case LCID_AZ_LA: //1254
		case LCID_TR: //1254
		case LCID_UZ_UZ: //1254
			name = @"CP1254";
			break;
		case LCID_HE: //1255
			name = @"CP1255";
			break;
		case LCID_AR_AE: //1256
		case LCID_AR_BH: //1256
		case LCID_AR_DZ: //1256
		case LCID_AR_EG: //1256
		case LCID_AR_IQ: //1256
		case LCID_AR_JO: //1256
		case LCID_AR_KW: //1256
		case LCID_AR_LB: //1256
		case LCID_AR_LY: //1256
		case LCID_AR_MA: //1256
		case LCID_AR_OM: //1256
		case LCID_AR_QA: //1256
		case LCID_AR_SA: //1256
		case LCID_AR_SY: //1256
		case LCID_AR_TN: //1256
		case LCID_AR_YE: //1256
		case LCID_FA: //1256
		case LCID_UR: //1256
			name = @"CP1256";
			break;
		case LCID_ET: //1257
		case LCID_LT: //1257
		case LCID_LV: //1257
			name = @"CP1257";
			break;
		case LCID_VI: //1258
			name = @"CP1258";
			break;
		case LCID_TH: //874
			name = @"CP874";
			break;
		case LCID_JA: //932
			name = @"CP932";
			break;
		case LCID_ZH_CN: //936
		case LCID_ZH_SG: //936
			name = @"CP936";
			break;
		case LCID_KO: //949
			name = @"CP949";
			break;
		case LCID_ZH_HK: //950
		case LCID_ZH_MO: //950
		case LCID_ZH_TW: //950
			name = @"CP950";
			break;			
		case LCID_GD_IE: //??
		case LCID_MK: //??
		case LCID_RM: //??
		case LCID_RO_MO: //??
		case LCID_RU_MO: //??
		case LCID_ST: //??
		case LCID_TN: //??
		case LCID_TS: //??
		case LCID_XH: //??
		case LCID_ZU: //??
		case LCID_HY: //0
		case LCID_MR: //0
		case LCID_MT: //0
		case LCID_SA: //0
		case LCID_TA: //0
		default:
			break;
	}
	return name;
}

# pragma mark chmlib
- (BOOL)hasObjectAtPath:(NSString *)path {
	struct chmUnitInfo info;
	if (chmFileHandle) {
		return chm_resolve_object(chmFileHandle, [path UTF8String], &info) == CHM_RESOLVE_SUCCESS;
	}
	return NO;
}

- (NSData *)dataForObjectAtPath:(NSString *)path {
	if (!path) {
		return nil;
	}
	if ([path hasPrefix:@"/"]) {
		if ([path hasPrefix:@"///"]) {
			path = [path substringFromIndex:2];
		}
	} else {
		path = [NSString stringWithFormat:@"/%@", path];
	}
	struct chmUnitInfo info;
	void *buffer = nil;
	
	@synchronized(self) {
		if (chm_resolve_object(chmFileHandle, [path UTF8String], &info) == CHM_RESOLVE_SUCCESS) {
			buffer = malloc(info.length);

			if (buffer) {
				if (!chm_retrieve_object(chmFileHandle, &info, buffer, 0, info.length)) {
					NSLog(@"Failed to load %qu bytes for %@", (long long)info.length, path);
					free(buffer);
					buffer = nil;
				}
			}
		}
	}
	
	if (buffer) {
		return [NSData dataWithBytesNoCopy:buffer length:info.length];
	}
	return nil;
}


- (BOOL)loadMetadata {
	//--- Start with WINDOWS object ---
	NSData *windowsData = [self dataForObjectAtPath:@"/#WINDOWS"];
	NSData *stringsData = [self dataForObjectAtPath:@"/#STRINGS"];

	if (windowsData && stringsData) {
		const uint32_t entryCount = readInt(windowsData, 0);
		const uint32_t entrySize = readInt(windowsData, 4);
		
		for (NSUInteger entryIndex = 0; entryIndex < entryCount; ++entryIndex) {
			NSUInteger entryOffset = 8 + (entryIndex * entrySize);

			if (!docTitle || ([docTitle length] == 0)) {
				docTitle = readTrimmedString(stringsData, readInt(windowsData, entryOffset + 0x14), encodingName);
				MDLog(@"[%@ %@] (STRINGS) docTitle == \"%@\"", NSStringFromClass([self class]), NSStringFromSelector(_cmd), docTitle);
			}
			if (!tableOfContentsPath || ([tableOfContentsPath length] == 0)) {
				tableOfContentsPath = readString(stringsData, readInt(windowsData, entryOffset + 0x60), encodingName);
				MDLog(@"[%@ %@] (STRINGS) tableOfContentsPath == \"%@\"", NSStringFromClass([self class]), NSStringFromSelector(_cmd), tableOfContentsPath);
			}
			if (!indexPath || ([indexPath length] == 0)) {
				indexPath = readString(stringsData, readInt(windowsData, entryOffset + 0x64), encodingName);
				MDLog(@"[%@ %@] (STRINGS) indexPath == \"%@\"", NSStringFromClass([self class]), NSStringFromSelector(_cmd), indexPath);
			}
			if (!homePath || ([homePath length] == 0)) {
				homePath = readString(stringsData, readInt(windowsData, entryOffset + 0x68), encodingName);
				MDLog(@"[%@ %@] (STRINGS) homePath == \"%@\"", NSStringFromClass([self class]), NSStringFromSelector(_cmd), homePath);
			}
		}
	}
	
	//--- Use SYSTEM object ---
	NSData *systemData = [self dataForObjectAtPath:@"/#SYSTEM"];
	if (systemData == nil) {
		return NO;
	}
	
	NSUInteger maxOffset = [systemData length];
	NSUInteger offset = 4;
	
	for (; offset < maxOffset; ) {
		switch (readShort(systemData, offset)) {
			case 0: {
				if (!tableOfContentsPath || ([tableOfContentsPath length] == 0)) {
					tableOfContentsPath = readString(systemData, offset + 4, encodingName);
					MDLog(@"[%@ %@] (SYSTEM) tableOfContentsPath == \"%@\"", NSStringFromClass([self class]), NSStringFromSelector(_cmd), tableOfContentsPath);
				}
				break;
			}
				
			case 1: {
				if (!indexPath || ([indexPath length] == 0)) {
					indexPath = readString(systemData, offset + 4, encodingName);
					MDLog(@"[%@ %@] (SYSTEM) indexPath == \"%@\"", NSStringFromClass([self class]), NSStringFromSelector(_cmd), indexPath);
				}
				break;
			}
				
			case 2: {
				if (!homePath || ([homePath length] == 0)) {
					homePath = readString(systemData, offset + 4, encodingName);
					MDLog(@"[%@ %@] (SYSTEM) homePath == \"%@\"", NSStringFromClass([self class]), NSStringFromSelector(_cmd), homePath);
				}
				break;
			}
				
			case 3: {
				if (!docTitle || ([docTitle length] == 0)) {
					docTitle = readTrimmedString(systemData, offset + 4, encodingName);
					MDLog(@"[%@ %@] (SYSTEM) docTitle == \"%@\"", NSStringFromClass([self class]), NSStringFromSelector(_cmd), docTitle);
				}
				break;
			}
				
			case 4: {
				uint32_t lcid = readInt(systemData, offset + 4);
				MDLog(@"[%@ %@] (SYSTEM) LCID == %u", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned)lcid);
				encodingName = LCIDtoEncodingName(lcid);
				MDLog(@"[%@ %@] (SYSTEM) encodingName == \"%@\"", NSStringFromClass([self class]), NSStringFromSelector(_cmd), encodingName);
				break;
			}
				
			case 6: {
				const char *data = (const char *)([systemData bytes] + offset + 4);
				NSString *prefix = [[NSString alloc] initWithCString:data encoding:nameToEncoding(encodingName)];
				if (!tableOfContentsPath || [tableOfContentsPath length] == 0) {
					NSString *path = [NSString stringWithFormat:@"/%@.hhc", prefix];
					if ([self hasObjectAtPath:path]) {
						tableOfContentsPath = path;
					}
				}
				if (!indexPath || [indexPath length] == 0) {
					NSString *path = [NSString stringWithFormat:@"/%@.hhk", prefix];
					if ([self hasObjectAtPath:path]) {
						indexPath = path;
					}
				}
				MDLog(@"[%@ %@] (SYSTEM) tableOfContentsPath == \"%@\"", NSStringFromClass([self class]), NSStringFromSelector(_cmd), tableOfContentsPath);
				[prefix release];
				break;
			}
				
		case 9:
			break;
		case 16:
			break;
		default:
			MDLog(@"[%@ %@] (SYSTEM) unhandled value == %d", NSStringFromClass([self class]), NSStringFromSelector(_cmd), readShort(systemData, offset));
			break;
		}
		offset += readShort(systemData, offset + 2) + 4;
	}
	
	// Check for empty string titles
	if ([docTitle length] == 0) {
		docTitle = nil;
	} else {
		[docTitle retain];
	}
	
	// Check for lack of index page
	if (!homePath) {
		homePath = [self findHomeForPath:@"/"];
		MDLog(@"[%@ %@] Implicit homePath == \"%@\"", NSStringFromClass([self class]), NSStringFromSelector(_cmd), homePath);
	}
	[homePath retain];
	[tableOfContentsPath retain];
	[indexPath retain];
	
	return YES;
}


- (NSString *)findHomeForPath:(NSString *)basePath {
	NSString *testPath;

	NSString *separator = [basePath hasSuffix:@"/"] ? @"" : @"/";
	testPath = [NSString stringWithFormat:@"%@%@index.htm", basePath, separator];
	if ([self hasObjectAtPath:testPath]) {
		return testPath;
	}
	testPath = [NSString stringWithFormat:@"%@%@default.html", basePath, separator];
	if ([self hasObjectAtPath:testPath]) {
		return testPath;
	}
	testPath = [NSString stringWithFormat:@"%@%@default.htm", basePath, separator];
	if ([self hasObjectAtPath:testPath]) {
		return testPath;
	}
	return [NSString stringWithFormat:@"%@%@index.html", basePath, separator];
}


# pragma mark NSDocument
- (NSString *)windowNibName {
	// Override returning the nib file name of the document
	// If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
	return @"CHMDocument";
}


- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
	[super windowControllerDidLoadNib:aController];
	[aController.window setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];
	
	[self setupTabBar];
	[self addNewTab:self];
	
	[outlineView setDataSource:tocSource];
	[outlineView setAutoresizesOutlineColumn:NO];
	
	if (tocSource.rootItems.numberOfChildren == 0) {
		[self hideSidebar:self];
	}
	
	[self setupToolbar];
	[self restoreSidebar];
	
	// go to last viewed page
	NSString *lastPath = (NSString *)[self getPreferenceforFile:filePath withKey:PREF_LAST_PATH];
	if (nil == lastPath) {
		[self goHome:self];
	} else {
		[self loadPath:lastPath];
	}
	
	[self prepareSearchIndex];
	
	// set search type and search menu
	NSString *type = [self getPreferenceforFile:filePath withKey:PREF_SEARCH_TYPE];
	if (type && [type isEqualToString:PREF_VALUE_SEARCH_IN_INDEX]) {
		self.searchMode = CHMDocumentSearchInIndex;
		[searchField setPlaceholderString:NSLocalizedString(@"Search in Index", @"")];
	}
	
	// invoke search if query string provided in command line
	if (firstDocument) {
		NSUserDefaults *args = [NSUserDefaults standardUserDefaults];
		NSString *searchTerm = [[args stringForKey:@"search"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		if (searchTerm && searchTerm.length) {
			[searchField setStringValue:searchTerm];
			self.searchMode = CHMDocumentSearchInFile;
			[self search:self];
			firstDocument = NO;
		}
	}
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
	if (outError != NULL) *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	return nil;
}


- (void)setupTOCSource {
	if (tableOfContentsPath && tableOfContentsPath.length) {
		NSData *tocData = [self dataForObjectAtPath:tableOfContentsPath];
		CHMTableOfContents *newTOC = [[CHMTableOfContents alloc] initWithData:tocData encodingName:[self currentEncodingName]];
		CHMTableOfContents *oldTOC = tocSource;
		tocSource = newTOC;
		
		if (oldTOC) {
			[oldTOC release];
		}
	}
	if (indexPath && indexPath.length) {
		NSData *tocData = [self dataForObjectAtPath:indexPath];
		CHMTableOfContents *newTOC = [[CHMTableOfContents alloc] initWithData:tocData encodingName:[self currentEncodingName]];
		CHMTableOfContents *oldTOC = indexSource;
		indexSource = newTOC;
		[indexSource sort];
		
		if (oldTOC) {
			[oldTOC release];
		}
	}
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)outError {
	MDLog(@"[%@ %@] url.path == %@, type == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), url.path, typeName);
	
	[filePath release];
	filePath = [[url path] retain];
	
	chmFileHandle = chm_open([filePath fileSystemRepresentation]);
	if (!chmFileHandle) return NO;
	
	[self loadMetadata];
	[self setupTOCSource];
	return YES;
}


- (void)close {
	[self resetEncodingMenu];
	[super close];
}

- (NSURL *)composeURL:(NSString *)path {
	MDLog(@"[%@ %@] path == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), path);
	
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"itss://chm/%@", path]];
	if (!url) {
		url = [NSURL URLWithString:[NSString stringWithFormat:@"itss://chm/%@", [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
	}
	return url;
}

- (NSString *)extractPathFromURL:(NSURL *)url {
	return [[[url absoluteString] substringFromIndex:11] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (void)loadPath:(NSString *)path {
	MDLog(@"[%@ %@] path == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), path);
	
	NSURL *url = [self composeURL:path];
	[self loadURL:url];
}

- (void)loadURL:(NSURL *)url {
	MDLog(@"[%@ %@] url == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), url);
	
	if (url) {
		NSURLRequest *req = [NSURLRequest requestWithURL:url];
		[[curWebView mainFrame] loadRequest:req];
	}
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

#pragma mark Properties
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


# pragma mark - <WebFrameLoadDelegate>
- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
	NSLog(@"[%@ %@] error == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error);
}

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
	NSLog(@"[%@ %@] error == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error);
}


- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
	[self updateHistoryButton];
	[self locateTOC:sender];
	
	// set label for tab bar
	NSURL *url = [[[frame dataSource] request] URL];
	NSString *path = [self extractPathFromURL:url];
	LinkItem *item = [(CHMTableOfContents *)[outlineView dataSource] itemForPath:path withStack:nil];
	NSTabViewItem *tabItem = [docTabView selectedTabViewItem];
	NSString *name = [item name];
	if (!name || [name length] == 0) {
		name = [curWebView mainFrameTitle];
	}
	
	if (name && [name length] > 0) {
		[tabItem setLabel:name];
	} else {
		[tabItem setLabel:NSLocalizedString(@"(Untitled)", @"(Untitled)")];
	}
	
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
	NSString *trimedPath = [NSString stringWithString:[url path]];
	while ([trimedPath hasPrefix:@"/"]) {
		trimedPath = [trimedPath substringFromIndex:1];
	}
	[self setPreference:trimedPath forFile:filePath withKey:PREF_LAST_PATH];
}


# pragma mark - Javascript
- (void)loadJavascript {
	NSString *scriptPath = [[NSBundle mainBundle] pathForResource:@"highlight" ofType:@"js"];
	[self runJavascript:[NSString stringWithContentsOfFile:scriptPath encoding:NSUTF8StringEncoding error:NULL]];
}

- (void)runJavascript:(NSString *)script {
	[[curWebView windowScriptObject] evaluateWebScript:[NSString stringWithFormat:@"try{ %@; } catch(e){console.log(e.toString());}", script]];
}


# pragma mark - <WebPolicyDelegate>
- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener {
	
	if ([ITSSProtocol canInitWithRequest:request]) {
		
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
	
	if ([ITSSProtocol canInitWithRequest:request]) {
		[listener use];
	} else {
		[[NSWorkspace sharedWorkspace] openURL:[request URL]];
		[listener ignore];
	}
}

# pragma mark - <WebResourceLoadDelegate>
- (NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource {
	
	if ([ITSSProtocol canInitWithRequest:request]) {
		NSMutableURLRequest *specialURLRequest = [[request mutableCopy] autorelease];
		[specialURLRequest setChmDoc:self];
		[specialURLRequest setEncodingName:[self currentEncodingName]];
		return specialURLRequest;
	} else {
		return request;
	}
}

# pragma mark - <WebUIDelegate>
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

# pragma mark - IBActions
- (IBAction)changeTopic:(id)sender {
	NSInteger selectedRow = [outlineView selectedRow];
	
	if (selectedRow >= 0) {
		LinkItem *topic = [outlineView itemAtRow:selectedRow];
		[self loadPath:[topic path]];
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
	[self loadPath:homePath];
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
	LinkItem *topic = [outlineView itemAtRow:selectedRow];
	LinkItem *nextPage = [tocSource pageAfterPage:topic];
	if (nextPage) {
		[self loadPath:[nextPage path]];
	}
}

- (IBAction)gotoPrevPage:(id)sender {
	NSInteger selectedRow = [outlineView selectedRow];
	LinkItem *topic = [outlineView itemAtRow:selectedRow];
	LinkItem *prevPage = [tocSource pageBeforePage:topic];
	if (prevPage) {
		[self loadPath:[prevPage path]];
	}
}

- (IBAction)locateTOC:(id)sender {
	NSURL *url = [[[[curWebView mainFrame] dataSource] request] URL];
	NSString *path = [self extractPathFromURL:url];
	NSMutableArray *tocStack = [[NSMutableArray alloc] init];
	LinkItem *item = [(CHMTableOfContents *)[outlineView dataSource] itemForPath:path withStack:tocStack];
	
	NSEnumerator *enumerator = [tocStack reverseObjectEnumerator];
	
	for (LinkItem *p in enumerator) {
		[outlineView expandItem:p];
	}
	
	NSInteger idx = [outlineView rowForItem:item];
	NSIndexSet *idxSet = [[NSIndexSet alloc] initWithIndex:idx];
	[outlineView selectRowIndexes:idxSet byExtendingSelection:NO];
	[outlineView scrollRowToVisible:idx];
	[tocStack release];
	[idxSet release];
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

- (void)updateHistoryButton {
	[historyControl setEnabled:[curWebView canGoBack] forSegment:0];
	[historyControl setEnabled:[curWebView canGoForward] forSegment:1];
}

#pragma mark export to pdf
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
		CHMExporter *exporter = [[CHMExporter alloc] initWithCHMDocument:self toFileName:URL.path pageList:[tocSource pageList]];
		[exporter export];
		[exporter release];
		[self showExportProgressSheet:self];
	}
}

- (IBAction)showExportProgressSheet:(id)sender {
	[NSApp beginSheet:exportProgressSheet modalForWindow:documentWindow modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
	[exportProgressIndicator setIndeterminate:FALSE];
}

- (IBAction)endExportProgressSheet:(id)sender {
	[NSApp endSheet:exportProgressSheet];
	[exportProgressSheet orderOut:sender];
}

- (void)exportedProgressRate:(double)rate PageCount:(NSInteger)count {
	NSString *title = NSLocalizedString(@"Save as PDF", @"Save as PDF");
	NSString *label = [NSString stringWithFormat:@"%@ : %ld %@", title, (long)count, NSLocalizedString(@"pages", @"pages")];
	[exportNoticeLabel setStringValue:label];
	[exportProgressIndicator setDoubleValue:rate];
}


# pragma mark TabVew
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
	CHMWebViewController *chmWebViewController = [[CHMWebViewController alloc] init];
	
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
	
	// create new tab item
	NSTabViewItem *newItem = [[[NSTabViewItem alloc] init] autorelease];
	[newItem setView:[chmWebViewController view]];
	[newItem setLabel:@"(Untitled)"];
	[newItem setIdentifier:chmWebViewController];
	
	// add to tab view
	[docTabView addTabViewItem:newItem];
	[webViews addObject:newView];
	
	[chmWebViewController autorelease];
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
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
	curWebView = [(CHMWebViewController *)[tabViewItem identifier] webView];
}

- (IBAction)selectNextTabViewItem:(id)sender {
	[docTabView selectNextTabViewItem:sender];
}

- (IBAction)selectPreviousTabViewItem:(id)sender {
	[docTabView selectPreviousTabViewItem:sender];
}

# pragma mark Toolbar
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


# pragma mark Search
- (void)prepareSearchIndex {
	MDLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
	[searchIndexObject release];
	searchIndexObject = [[NSMutableData dataWithCapacity: 2^22] retain];
	
	if (skIndex) {
		SKIndexClose(skIndex);
		skIndex = NULL;
	}
	
	skIndex = SKIndexCreateWithMutableData((CFMutableDataRef)searchIndexObject, NULL, kSKIndexInverted, (CFDictionaryRef)NULL);
	[NSThread detachNewThreadSelector:@selector(buildSearchIndex) toTarget:self withObject:nil];
}

static int forEachFile(struct chmFile *h, struct chmUnitInfo *ui, void *context) {
	if (ui->path[0] != '/' || strstr(ui->path, "/../") != NULL || ui->path[strlen(ui->path)-1] == '/')
        return CHM_ENUMERATOR_CONTINUE;

	CHMDocument *doc = (CHMDocument *)context;
	[doc addToSearchIndex:ui->path];
	return CHM_ENUMERATOR_CONTINUE;
}

- (void)buildSearchIndex {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	MDLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
	[searchIndexCondition lock];
	chm_enumerate(chmFileHandle, CHM_ENUMERATE_FILES || CHM_ENUMERATE_NORMAL, forEachFile, (void *)self);
	isIndexDone = YES;
	[searchIndexCondition signal];
	[searchIndexCondition unlock];
	
	[pool release];
}

- (void)addToSearchIndex:(const char *)path {
//	MDLog(@"[%@ %@] %s", NSStringFromClass([self class]), NSStringFromSelector(_cmd), path);
	
	NSString *filepath = [NSString stringWithCString:path encoding:nameToEncoding(encodingName)];
	if ([filepath hasPrefix:@"/"]) {
		filepath = [filepath substringFromIndex:1];
	}
	NSData *data = [self dataForObjectAtPath:filepath];
	NSURL *url = [self composeURL:filepath];
	
	if (!url) {
		return;
	}
	SKDocumentRef doc = SKDocumentCreateWithURL((CFURLRef)url);
	[(id)doc autorelease];
	
	NSString *contents = [[NSString alloc] initWithData:data encoding:nameToEncoding(encodingName)];
	
	// if the encoding being set is invalid, try following encoding.
	if (contents == nil && data.length) {
		contents = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	}
	if (contents == nil && data.length) {
		contents = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
	}
	SKIndexAddDocumentWithText(skIndex, doc, (CFStringRef)contents, (Boolean)true);
	[contents release];
}


- (IBAction)changeSearchMode:(id)sender {
	NSInteger tag = [sender tag];
	if (searchMode == tag) return;
	self.searchMode = tag;
	[searchField setPlaceholderString:(searchMode == CHMDocumentSearchInFile ? NSLocalizedString(@"Search in File", @"") : NSLocalizedString(@"Search in Index", @""))];
	
	if ([searchField stringValue].length) [self search:self];
	
	[self setPreference:(searchMode == CHMDocumentSearchInFile ? PREF_VALUE_SEARCH_IN_FILE : PREF_VALUE_SEARCH_IN_INDEX) forFile:filePath withKey:PREF_SEARCH_TYPE];
}


- (IBAction)search:(id)sender {
#if MD_DEBUG
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	
	if (searchMode == CHMDocumentSearchInFile) {
		
		// waiting for the building of index
		[searchIndexCondition lock];
		
		while (!isIndexDone) [searchIndexCondition wait];
		
		[searchIndexCondition unlock];
		
	}
	
	NSString *searchString = [searchField stringValue];
	
	if (searchString.length == 0) {
		
		if (viewMode == CHMDocumentViewTableOfContents) {
			[outlineView setDataSource:tocSource];
			[[[outlineView outlineTableColumn] headerCell] setStringValue:NSLocalizedString(@"Contents", @"Contents")];
			[self locateTOC:sender];
			
		} else if (viewMode == CHMDocumentViewIndex) {
			[outlineView setDataSource:indexSource];
			[[[outlineView outlineTableColumn] headerCell] setStringValue:NSLocalizedString(@"Index", @"Index")];
			
		}
		[outlineView reloadData];
		
		[searchSource release];
		searchSource = nil;
		[self removeHighlight];
		return;
	}
	
	if (searchMode == CHMDocumentSearchInIndex) {
		
		[searchSource release];
		searchSource = nil;
		
		if (indexSource == nil) return;
		
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name beginswith[c] %@ ", searchString];
//		searchSource = [[CHMTableOfContents alloc] initWithTableOfContents:indexSource filterByPredicate:predicate];
		searchSource = [[CHMSearchResults alloc] initWithTableOfContents:indexSource filterByPredicate:predicate];
		
		[outlineView deselectAll:self];
		[outlineView setDataSource:searchSource];
		[[[outlineView outlineTableColumn] headerCell] setStringValue:NSLocalizedString(@"Search", @"Search")];
		
		[outlineView reloadData];
		return;
	}
	
	// search in file
	
	[searchSource release];
	
	searchSource = [[CHMSearchResults alloc] initWithTableOfContents:tocSource indexContents:indexSource];
	
	if (indexSource == nil && tocSource == nil) return;
	
	SKSearchOptions options = kSKSearchOptionDefault;
	SKIndexFlush(skIndex);
	SKSearchRef search = SKSearchCreate(skIndex, (CFStringRef)searchString, options);
    [(id)search autorelease];
	
	Boolean more = true;
    uint32_t totalCount = 0;
	uint32_t kSearchMax = 10;
	
    while (more) {
        SKDocumentID		foundDocIDs[kSearchMax];
        float				foundScores[kSearchMax];
        SKDocumentRef		foundDocRefs[kSearchMax];
		
        float *scores;
		
		scores = foundScores;
		
        CFIndex foundCount = 0;
        CFIndex pos;
		
		more = SKSearchFindMatches(search,
								  kSearchMax,
								  foundDocIDs,
								  scores,
								  1, // maximum time before func returns, in seconds
								  &foundCount
								  );
		
        totalCount += foundCount;
		
		//..........................................................................
		// get document locations for matches and display results.
		//     alternatively, you can collect results over iterations of this loop
		//     for display later.
		
		SKIndexCopyDocumentRefsForDocumentIDs((SKIndexRef)skIndex,
											  (CFIndex)foundCount,
											  (SKDocumentID *)foundDocIDs,
											  (SKDocumentRef *)foundDocRefs);
		
        for (pos = 0; pos < foundCount; pos++) {
			
            SKDocumentRef doc = (SKDocumentRef)[(id)foundDocRefs[pos] autorelease];
			
            NSURL *url = [(id)SKDocumentCopyURL(doc) autorelease];
			
			[searchSource addPath:[url path] score:foundScores[pos]];
        }
    }
	[searchSource sort];
	[outlineView deselectAll:self];
	[outlineView setDataSource:searchSource];
	[[[outlineView outlineTableColumn] headerCell] setStringValue:NSLocalizedString(@"Search", @"Search")];
	
	[outlineView reloadData];
	
}


- (IBAction)focusOnSearch:(id)sender {
	[documentWindow makeFirstResponder:searchField];
}

# pragma mark find panel
- (IBAction)showFindPanel:(id)sender {
	CHMWebViewController *chmWebView = (CHMWebViewController *)[[docTabView selectedTabViewItem] identifier];
	return [chmWebView showFindPanel:sender];
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
	[[[docTabView selectedTabViewItem] identifier] hideFindPanel:sender];
	[self removeHighlight];
}


#pragma mark text encoding
- (void)setupEncodingMenu {
	NSApplication *app = [NSApplication sharedApplication];
	CHMAppController *chmapp = [app delegate];
	
	NSMenu *menu = [[chmapp textEncodingMenu] submenu];
	NSArray *items = [menu itemArray];
	for (NSMenuItem *item in items) {
		if ([item tag] == customizedEncodingTag) {
			[item setState:NSOnState];
		} else {
			[item setState:NSOffState];
		}
		[item setTarget:self];
		[item setAction:@selector(changeEncoding:)];
		[item setEnabled:YES];
	}
}

- (void)resetEncodingMenu {
	NSApplication *app = [NSApplication sharedApplication];
	CHMAppController *chmapp = [app delegate];
	
	NSMenu *menu = [[chmapp textEncodingMenu] submenu];
	NSArray *items = [menu itemArray];
	for (NSMenuItem *item in items) {
		if ([item tag] == 0) {
			[item setState:NSOnState];
		} else {
			[item setState:NSOffState];
		}
		[item setTarget:nil];
		[item setAction:NULL];
		[item setEnabled:NO];
	}
}

- (IBAction)changeEncoding:(id)sender {
	customizedEncodingTag = [sender tag];
	for (WebView *wv in webViews) {
		[wv setCustomTextEncodingName:[self currentEncodingName]];
	}
	
	[self setupTOCSource];
	[outlineView setDataSource:tocSource];
	[self locateTOC:self];
}

- (NSString *)getEncodingByTag:(NSInteger)tag {
	CHMAppController *chmapp = [NSApp delegate];
	
	CHMTextEncodingMenuController *menu = [[[chmapp textEncodingMenu] submenu] delegate];
	return [menu getEncodingByTag:tag];
}

- (NSString *)currentEncodingName {
	NSString *ename = [self getEncodingByTag:customizedEncodingTag];
	if (!ename) {
		ename = encodingName;
	}
	MDLog(@"[%@ %@] encodingName == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), ename);
	
	return ename;
}


#pragma mark - (NSMenuValidation)

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	MDLog(@"[%@ %@] menuItem == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), menuItem);
	SEL action = [menuItem action];
	NSInteger tag = [menuItem tag];
	
	if (action == @selector(changeSearchMode:)) {
		[menuItem setState:searchMode == tag];
		if (tag == CHMDocumentSearchInIndex) {
			return (indexSource != nil);
		}
	} else if (action == @selector(changeViewMode:)) {
		[menuItem setState:viewMode == tag];
		if (tag == CHMDocumentViewIndex) {
			return (indexSource != nil);
		}
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
	
	if (viewMode == CHMDocumentViewTableOfContents) {
		[outlineView setDataSource:tocSource];
		[[[outlineView outlineTableColumn] headerCell] setStringValue:NSLocalizedString(@"Contents", @"Contents")];
		[self locateTOC:sender];
		
	} else if (viewMode == CHMDocumentViewIndex) {
		[outlineView setDataSource:indexSource];
		[[[outlineView outlineTableColumn] headerCell] setStringValue:NSLocalizedString(@"Index", @"Index")];
		
	}
	[outlineView reloadData];
}


@end

