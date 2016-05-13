//
//  CHMDocumentFile.m
//  ichm
//
//  Created by Mark Douma on 4/15/2016.
//
//  Copyright © 2016 Mark Douma.

#import "CHMDocumentFile.h"
#import <CHM/CHM.h>
#import "lcid.h"
#import "CHMLinkItem.h"
#import "CHMTableOfContents.h"
#import "CHMSearchResult.h"
#import "CHMITSSURLProtocol.h"
#import "CHMKitPrivateInterfaces.h"


#define MD_DEBUG 1

#if MD_DEBUG
#define MDLog(...) NSLog(__VA_ARGS__)
#else
#define MDLog(...)
#endif


@interface CHMDocumentFile ()

@property (nonatomic, retain) NSString *filePath;

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *homePath;
@property (nonatomic, retain) NSString *tableOfContentsPath;
@property (nonatomic, retain) NSString *indexPath;


@property (assign) NSStringEncoding encoding;
@property (retain) NSString *encodingName;

@property (assign) NSStringEncoding customEncoding;
@property (retain) NSString *customEncodingName;

@property (assign) BOOL hasPreparedSearchIndex;

@property (assign) BOOL isPreparingSearchIndex;


- (BOOL)loadMetadata;
- (void)setupTableOfContentsAndIndex;

- (void)buildSearchIndexInBackgroundThread;
- (void)addToSearchIndex:(const char *)path;
- (void)notifyDelegateSearchIndexIsPrepared:(id)sender;

@end




static BOOL automaticallyPreparesSearchIndex = YES;


@implementation CHMDocumentFile

@synthesize filePath;
@synthesize title;
@synthesize homePath;
@synthesize tableOfContentsPath;
@synthesize indexPath;

@synthesize tableOfContents;
@synthesize index;
@synthesize searchResults;

@synthesize encoding;
@synthesize encodingName;

@synthesize customEncoding;
@synthesize customEncodingName;

@dynamic currentEncodingName;

@synthesize searchDelegate;

@synthesize hasPreparedSearchIndex;
@synthesize isPreparingSearchIndex;



+ (BOOL)automaticallyPreparesSearchIndex {
	return automaticallyPreparesSearchIndex;
}


+ (void)setAutomaticallyPreparesSearchIndex:(BOOL)shouldPrepare {
	automaticallyPreparesSearchIndex = shouldPrepare;
}


+ (id)documentFileWithContentsOfFile:(NSString *)path error:(NSError **)outError {
	return [[(CHMDocumentFile *)[[self class] alloc] initWithContentsOfFile:path error:outError] autorelease];
}


- (id)initWithContentsOfFile:(NSString *)path error:(NSError **)outError {
	if ((self = [super init])) {
		// error reporting isn't yet implemented, so set to nil to be safe if they try to use it.
		if (outError) *outError = nil;
		
		filePath = [path retain];
		
		chmFileHandle = chm_open([filePath fileSystemRepresentation]);
		if (chmFileHandle == NULL) {
			[self release];
			return nil;
		}
		
		hasPreparedSearchIndex = NO;
		isPreparingSearchIndex = NO;
		searchIndexCondition = [[NSCondition alloc] init];
		
		searchResults = [[NSMutableArray alloc] init];
		
		[self loadMetadata];
		[self setupTableOfContentsAndIndex];
		
		if ([[self class] automaticallyPreparesSearchIndex]) [self prepareSearchIndex];
		
	}
	return self;
}


- (void)dealloc {
	searchDelegate = nil;
	
	[filePath release];
	
	if (chmFileHandle) {
		chm_close(chmFileHandle);
	}
	[title release];
	[homePath release];
	[tableOfContentsPath release];
	[indexPath release];
	
	[tableOfContents release];
	[index release];
	[searchResults release];
	
	if (skIndex) SKIndexClose(skIndex);
	
	[searchIndexData release];
	[searchIndexCondition release];
	
	[encodingName release];
	[customEncodingName release];
	
	[super dealloc];
}



#pragma mark - Basic CHM reading operations
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

static inline NSString *readString(NSData *data, NSUInteger offset, NSStringEncoding anEncoding) {
	const char *stringData = (char *)[data bytes] + offset;
	return [[[NSString alloc] initWithCString:stringData encoding:anEncoding] autorelease];
}

static inline NSString *readTrimmedString(NSData *data, NSUInteger offset, NSStringEncoding anEncoding) {
	NSString *str = readString(data, offset, anEncoding);
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
			name = @"windows-1250";
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
			name = @"windows-1251";
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
			name = @"windows-1252";
			break;
		case LCID_EL: //1253
			name = @"windows-1253";
			break;
		case LCID_AZ_LA: //1254
		case LCID_TR: //1254
		case LCID_UZ_UZ: //1254
			name = @"windows-1254";
			break;
		case LCID_HE: //1255
			name = @"windows-1255";
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
			name = @"windows-1256";
			break;
		case LCID_ET: //1257
		case LCID_LT: //1257
		case LCID_LV: //1257
			name = @"windows-1257";
			break;
		case LCID_VI: //1258
			name = @"windows-1258";
			break;
		case LCID_TH: //874
			name = @"cp874";
			break;
		case LCID_JA: //932
			name = @"cp932";
			break;
		case LCID_ZH_CN: //936
		case LCID_ZH_SG: //936
			name = @"cp936";
			break;
		case LCID_KO: //949
			name = @"cp949";
			break;
		case LCID_ZH_HK: //950
		case LCID_ZH_MO: //950
		case LCID_ZH_TW: //950
			name = @"cp950";
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

#pragma mark - chmlib
- (BOOL)hasObjectAtPath:(NSString *)path {
	struct chmUnitInfo info;
	if (chmFileHandle) {
		return chm_resolve_object(chmFileHandle, [path UTF8String], &info) == CHM_RESOLVE_SUCCESS;
	}
	return NO;
}

- (NSData *)dataForObjectAtPath:(NSString *)path {
	if (path == nil) return nil;
    
    if ([path hasPrefix:@"/"]) {
		// Quick fix
		if ([path hasPrefix:@"///"]) {
			path = [path substringFromIndex:2];
		}
    } else {
		path = [NSString stringWithFormat:@"/%@", path];
	}
	struct chmUnitInfo info;
	void *buffer = NULL;
	
	if (chm_resolve_object(chmFileHandle, [path UTF8String], &info ) == CHM_RESOLVE_SUCCESS) {
		buffer = malloc(info.length);
		
		if (buffer) {
			if (!chm_retrieve_object(chmFileHandle, &info, buffer, 0, info.length)) {
				NSLog(@"[%@ %@] failed to load %lu for item at path \"%@\"", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned long)info.length, path);
				free(buffer);
				buffer = NULL;
			}
		}
	}
    
	if (buffer)
		return [NSData dataWithBytesNoCopy:buffer length:info.length];
	
	return nil;
	
}


- (BOOL)loadMetadata {
	/* before anything else, get the encoding */
	
	NSData *systemData = [self dataForObjectAtPath:@"/#SYSTEM"];
	if (systemData == nil) {
		return NO;
	}
	
	NSUInteger maxOffset = [systemData length];
	NSUInteger offset = 4;
	
	for (; offset < maxOffset; ) {
		uint16_t data = readShort(systemData, offset);
		
		if (data == 4) {
			uint32_t lcid = readInt(systemData, offset + 4);
			MDLog(@"[%@ %@] (SYSTEM) LCID == %u", NSStringFromClass([self class]), NSStringFromSelector(_cmd), (unsigned)lcid);
			encodingName = LCIDtoEncodingName(lcid);
			MDLog(@"[%@ %@] (SYSTEM) encodingName == \"%@\"", NSStringFromClass([self class]), NSStringFromSelector(_cmd), encodingName);
			
			CFStringEncoding cfStringEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)encodingName);
			
//			MDLog(@"cfStringEncoding == %lu", (unsigned long)cfStringEncoding);
//			MDLog(@"cfStringEncoding == \"%@\"", CFStringGetNameOfEncoding(cfStringEncoding));
			NSStringEncoding nsStringEncoding = CFStringConvertEncodingToNSStringEncoding(cfStringEncoding);
//			MDLog(@"nsStringEncoding == %lu", (unsigned long)nsStringEncoding);
			
			NSString *locDescrp = [NSString localizedNameOfStringEncoding:nsStringEncoding];
			MDLog(@"[%@ %@] (SYSTEM) encoding == \"%@\"", NSStringFromClass([self class]), NSStringFromSelector(_cmd), locDescrp);
			
			encoding = nsStringEncoding;
			
			break;
		}
		offset += readShort(systemData, offset + 2) + 4;
		
	}
	
	//--- Start with WINDOWS object ---
	NSData *windowsData = [self dataForObjectAtPath:@"/#WINDOWS"];
	NSData *stringsData = [self dataForObjectAtPath:@"/#STRINGS"];
	
	if (windowsData && stringsData) {
		const uint32_t entryCount = readInt(windowsData, 0);
		const uint32_t entrySize = readInt(windowsData, 4);
		
		for (NSUInteger entryIndex = 0; entryIndex < entryCount; ++entryIndex) {
			NSUInteger entryOffset = 8 + (entryIndex * entrySize);

			if (!title || ([title length] == 0)) {
				title = readTrimmedString(stringsData, readInt(windowsData, entryOffset + 0x14), encoding);
				MDLog(@"[%@ %@] (STRINGS) title == \"%@\"", NSStringFromClass([self class]), NSStringFromSelector(_cmd), title);
			}
			if (!tableOfContentsPath || ([tableOfContentsPath length] == 0)) {
				tableOfContentsPath = readString(stringsData, readInt(windowsData, entryOffset + 0x60), encoding);
				MDLog(@"[%@ %@] (STRINGS) tableOfContentsPath == \"%@\"", NSStringFromClass([self class]), NSStringFromSelector(_cmd), tableOfContentsPath);
			}
			if (!indexPath || ([indexPath length] == 0)) {
				indexPath = readString(stringsData, readInt(windowsData, entryOffset + 0x64), encoding);
				MDLog(@"[%@ %@] (STRINGS) indexPath == \"%@\"", NSStringFromClass([self class]), NSStringFromSelector(_cmd), indexPath);
			}
			if (!homePath || ([homePath length] == 0)) {
				homePath = readString(stringsData, readInt(windowsData, entryOffset + 0x68), encoding);
				MDLog(@"[%@ %@] (STRINGS) homePath == \"%@\"", NSStringFromClass([self class]), NSStringFromSelector(_cmd), homePath);
			}
		}
	}
	
	//--- Use SYSTEM object ---
	
	offset = 4;
	
	for (; offset < maxOffset; ) {
		switch (readShort(systemData, offset)) {
			case 0: {
				if (!tableOfContentsPath || ([tableOfContentsPath length] == 0)) {
					tableOfContentsPath = readString(systemData, offset + 4, encoding);
					MDLog(@"[%@ %@] (SYSTEM) tableOfContentsPath == \"%@\"", NSStringFromClass([self class]), NSStringFromSelector(_cmd), tableOfContentsPath);
				}
				break;
			}
				
			case 1: {
				if (!indexPath || ([indexPath length] == 0)) {
					indexPath = readString(systemData, offset + 4, encoding);
					MDLog(@"[%@ %@] (SYSTEM) indexPath == \"%@\"", NSStringFromClass([self class]), NSStringFromSelector(_cmd), indexPath);
				}
				break;
			}
				
			case 2: {
				if (!homePath || ([homePath length] == 0)) {
					homePath = readString(systemData, offset + 4, encoding);
					MDLog(@"[%@ %@] (SYSTEM) homePath == \"%@\"", NSStringFromClass([self class]), NSStringFromSelector(_cmd), homePath);
				}
				break;
			}
				
			case 3: {
				if (!title || ([title length] == 0)) {
					title = readTrimmedString(systemData, offset + 4, encoding);
					MDLog(@"[%@ %@] (SYSTEM) title == \"%@\"", NSStringFromClass([self class]), NSStringFromSelector(_cmd), title);
				}
				break;
			}
				
			case 6: {
				const char *data = (const char *)([systemData bytes] + offset + 4);
				NSString *prefix = [[NSString alloc] initWithCString:data encoding:encoding];
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
	if ([title length] == 0) {
		title = nil;
	} else {
		[title retain];
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
	NSString *separator = [basePath hasSuffix:@"/"] ? @"" : @"/";
	
	NSString *testPath = [NSString stringWithFormat:@"%@%@index.htm", basePath, separator];
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


- (void)setupTableOfContentsAndIndex {
	if (tableOfContentsPath && tableOfContentsPath.length) {
		NSData *tocData = [self dataForObjectAtPath:tableOfContentsPath];
		CHMTableOfContents *newTOC = [[CHMTableOfContents alloc] initWithData:tocData encodingName:[self currentEncodingName]];
		newTOC.documentFile = self;
		CHMTableOfContents *oldTOC = tableOfContents;
		tableOfContents = newTOC;
		
		if (oldTOC) {
			[oldTOC release];
		}
	}
	if (indexPath && indexPath.length) {
		NSData *tocData = [self dataForObjectAtPath:indexPath];
		CHMTableOfContents *newTOC = [[CHMTableOfContents alloc] initWithData:tocData encodingName:[self currentEncodingName]];
		newTOC.documentFile = self;
		CHMTableOfContents *oldTOC = index;
		index = newTOC;
		[index sort];
		
		if (oldTOC) {
			[oldTOC release];
		}
	}
	
//	MDLog(@"[%@ %@] tableOfContents == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), tableOfContents);
	
}


- (CHMLinkItem *)itemAtPath:(NSString *)aPath {
//	MDLog(@"[%@ %@] aPath == \"%@\"", NSStringFromClass([self class]), NSStringFromSelector(_cmd), aPath);
	// strip leading /'s
	aPath = [aPath chm__stringByDeletingLeadingSlashes];
	
	CHMLinkItem *item = nil;
	if (tableOfContents) item = [tableOfContents itemAtPath:aPath];
	if (item == nil && index) item = [index itemAtPath:aPath];
//	MDLog(@"[%@ %@] item == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), item);
	return item;
}



#pragma mark - search
- (void)prepareSearchIndex {
	MDLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
	self.isPreparingSearchIndex = YES;
	
	[searchIndexData release];
	searchIndexData = [[NSMutableData dataWithCapacity: 2^22] retain];
	
	if (skIndex) {
		SKIndexClose(skIndex);
		skIndex = NULL;
	}
	
	skIndex = SKIndexCreateWithMutableData((CFMutableDataRef)searchIndexData, NULL, kSKIndexInverted, (CFDictionaryRef)NULL);
	[NSThread detachNewThreadSelector:@selector(buildSearchIndexInBackgroundThread) toTarget:self withObject:nil];
}

static int forEachFile(struct chmFile *h, struct chmUnitInfo *ui, void *context) {
	if (ui->path[0] != '/' || strstr(ui->path, "/../") != NULL || ui->path[strlen(ui->path)-1] == '/')
        return CHM_ENUMERATOR_CONTINUE;

	CHMDocumentFile *docFile = (CHMDocumentFile *)context;
	[docFile addToSearchIndex:ui->path];
	return CHM_ENUMERATOR_CONTINUE;
}

- (void)buildSearchIndexInBackgroundThread {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	MDLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
	[searchIndexCondition lock];
	chm_enumerate(chmFileHandle, CHM_ENUMERATE_FILES || CHM_ENUMERATE_NORMAL, forEachFile, (void *)self);
	hasPreparedSearchIndex = YES;
	[searchIndexCondition signal];
	[searchIndexCondition unlock];
	
	[self performSelectorOnMainThread:@selector(notifyDelegateSearchIndexIsPrepared:) withObject:nil waitUntilDone:NO];
	
	[pool release];
}


- (void)addToSearchIndex:(const char *)path {
	NSString *filepath = [NSString stringWithCString:path encoding:encoding];
	if ([filepath hasPrefix:@"/"]) {
		filepath = [filepath substringFromIndex:1];
	}
	NSData *data = [self dataForObjectAtPath:filepath];
	NSURL *url = [NSURL chm__ITSSURLWithPath:filepath];
	
	if (!url) {
		return;
	}
	SKDocumentRef doc = SKDocumentCreateWithURL((CFURLRef)url);
	[(id)doc autorelease];
	
	NSString *contents = [[NSString alloc] initWithData:data encoding:encoding];
	
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


- (void)notifyDelegateSearchIndexIsPrepared:(id)sender {
	if (searchDelegate && [searchDelegate respondsToSelector:@selector(documentFileDidPrepareSearchIndex:)]) {
		[searchDelegate documentFileDidPrepareSearchIndex:self];
	}
}


static NSString * const CHMDocumentFileSearchModeDescriptions[] = {
	@"<invalid value>",
	@"CHMDocumentFileSearchInFile",
	@"CHMDocumentFileSearchInIndex",
};

- (void)searchForString:(NSString *)searchString usingMode:(CHMDocumentFileSearchMode)searchMode {
	NSParameterAssert(searchString != nil && searchMode >= CHMDocumentFileSearchInFile && searchMode <= CHMDocumentFileSearchInIndex);
	MDLog(@"[%@ %@] searchMode == %@, searchString == \"%@\", ", NSStringFromClass([self class]), NSStringFromSelector(_cmd), CHMDocumentFileSearchModeDescriptions[searchMode], searchString);
	
	if (self.hasPreparedSearchIndex == NO && self.isPreparingSearchIndex == NO) {
		[self prepareSearchIndex];
	}
	
	if (searchMode == CHMDocumentFileSearchInFile) {
		
		// wait for the building of index
		[searchIndexCondition lock];
		
		while (!hasPreparedSearchIndex) [searchIndexCondition wait];
		
		[searchIndexCondition unlock];
		
	}
	
	[searchResults removeAllObjects];
	
	if (searchMode == CHMDocumentFileSearchInIndex) {
		if (index == nil) {
			if (searchDelegate && [searchDelegate respondsToSelector:@selector(documentFile:didUpdateSearchResults:)]) {
				[searchDelegate documentFile:self didUpdateSearchResults:[self searchResults]];
			}
			return;
		}
		
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name beginswith[c] %@ ", searchString];
		NSMutableArray *indexChildren = index.items.children;
		NSArray *filteredResults = [indexChildren filteredArrayUsingPredicate:predicate];
		
		NSMutableArray *mSearchResults = [NSMutableArray array];
		
		for (CHMLinkItem *item in filteredResults) {
			CHMSearchResult *searchResult = [[CHMSearchResult alloc] initWithItem:item score:0];
			if (searchResult) [mSearchResults addObject:searchResult];
			[searchResult release];
		}
		
		[searchResults setArray:mSearchResults];
		
		if (searchDelegate && [searchDelegate respondsToSelector:@selector(documentFile:didUpdateSearchResults:)]) {
			[searchDelegate documentFile:self didUpdateSearchResults:[self searchResults]];
		}
		return;
	}
	
	// search in file
	
	if (index == nil && tableOfContents == nil) {
		if (searchDelegate && [searchDelegate respondsToSelector:@selector(documentFile:didUpdateSearchResults:)]) {
			[searchDelegate documentFile:self didUpdateSearchResults:[self searchResults]];
		}
		return;
	}
	
	
	SKSearchOptions options = kSKSearchOptionDefault;
	SKIndexFlush(skIndex);
	SKSearchRef search = SKSearchCreate(skIndex, (CFStringRef)searchString, options);
    [(id)search autorelease];
	
	Boolean more = true;
    uint32_t totalCount = 0;
	uint32_t kSearchMax = 10;
	
	NSMutableArray *mSearchResults = [NSMutableArray array];
	
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
			
			CHMLinkItem *item = [self itemAtPath:url.path];
			if (item) {
				CHMSearchResult *searchResult = [[CHMSearchResult alloc] initWithItem:item score:foundScores[pos]];
				if (searchResult) [mSearchResults addObject:searchResult];
				[searchResult release];
			}
        }
    }
	
	static NSArray *searchInFileSortDescriptors = nil;
	
	if (searchInFileSortDescriptors == nil) {
		NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"score" ascending:NO] autorelease];
		searchInFileSortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	}
	
	[mSearchResults sortUsingDescriptors:searchInFileSortDescriptors];
	
	[searchResults setArray:mSearchResults];
	
	if (searchDelegate && [searchDelegate respondsToSelector:@selector(documentFile:didUpdateSearchResults:)]) {
		[searchDelegate documentFile:self didUpdateSearchResults:[self searchResults]];
	}
}


- (NSArray *)searchResults {
	return [[searchResults copy] autorelease];
}


#pragma mark - encodings
- (void)setCustomEncoding:(NSStringEncoding)aCustomEncoding customEncodingName:(NSString *)aCustomEncodingName {
	NSParameterAssert((aCustomEncoding && aCustomEncodingName) ||
					  (!aCustomEncoding && !aCustomEncodingName));
	
	self.customEncoding = aCustomEncoding;
	self.customEncodingName = aCustomEncodingName;
	
	[self setupTableOfContentsAndIndex];
}



- (NSString *)currentEncodingName {
	if (customEncoding) {
		return customEncodingName;
	}
	return encodingName;
}



@end



