//
//  GetMetadataForFile.m
//  CHMTestImporter
//
//  Created by Marco Yuen on 24/12/08.
//  Copyright 2008 University of Victoria. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CHMKit/CHMKit.h>
#import "CHMSpotlightHMTLDocument.h"


#define MD_DEBUG 1
#define MD_DEBUG_PERFORMANCE 0

static NSString * const MDBundleIdentifierKey = @"com.markdouma.mdimporter.CHM";

#if MD_DEBUG
#define MDLog(...) NSLog(__VA_ARGS__)
#else
#define MDLog(...)
#endif

// 100MB
#define CHM_MAX_FILE_SIZE 104857600


#pragma mark - Custom Attribute
NSString * const com_marcoyuen_chmImporter_SectionTitles = @"com_marcoyuen_chm_SectionTitles";


#pragma mark - Importer entrance function
Boolean GetMetadataForFile(void *thisInterface, CFMutableDictionaryRef attributes, CFStringRef contentTypeUTI, CFStringRef pathToFile) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
#if !MD_DEBUG_PERFORMANCE
	MDLog(@"%@; %s(): file == \"%@\"", MDBundleIdentifierKey, __FUNCTION__, (NSString *)pathToFile);
#endif
	
#if MD_DEBUG_PERFORMANCE
	NSDate *startDate = [NSDate date];
#endif
	
	[CHMDocumentFile setAutomaticallyPreparesSearchIndex:NO];
	
	CHMDocumentFile *documentFile = [[CHMDocumentFile alloc] initWithContentsOfFile:(NSString *)pathToFile error:NULL];
	
	if (documentFile == nil) {
		NSLog(@"%@; %s(): failed to create CHMDocumentFile for file at \"%@\"", MDBundleIdentifierKey, __FUNCTION__, pathToFile);
		goto cleanup;
	}
	
	NSMutableDictionary *mAttributes = (NSMutableDictionary *)attributes;
	
	NSMutableArray *sectionTitles = [NSMutableArray array];
	
	NSArray *sectionLinkItems = documentFile.tableOfContents.linkItems.children;
	
	// 1. The first element is _usually_ the title of the book.
	// 2. Everything else---title heading.
	
	BOOL setTitle = NO;
	
	if (documentFile.title) {
		[mAttributes setObject:documentFile.title forKey:(id)kMDItemTitle];
		setTitle = YES;
	}
	
	for (CHMLinkItem *linkItem in sectionLinkItems) {
		NSString *sectionTitle = linkItem.name;
		if (setTitle == NO) {
			if (sectionTitle) [mAttributes setObject:sectionTitle forKey:(id)kMDItemTitle];
			setTitle = YES;
			continue;
		}
		if (sectionTitle) [sectionTitles addObject:sectionTitle];
	}
	
	if (sectionTitles.count) {
		[mAttributes setObject:sectionTitles forKey:com_marcoyuen_chmImporter_SectionTitles];
	}
	
	NSMutableString *mString = [NSMutableString string];
	
	NSArray *allArchiveItems = documentFile.allArchiveItems;
	
	NSUInteger spotDocCreationErrorCount = 0;
	
	NSError *exampleError = nil;
	
	for (CHMArchiveItem *archiveItem in allArchiveItems) {
		
		if (![archiveItem.pathExtension hasPrefix:@"htm"]) continue;
		
		NSAutoreleasePool *localPool = [[NSAutoreleasePool alloc] init];
		
		NSError *error = nil;
		
		CHMSpotlightHMTLDocument *htmlDocument = [[CHMSpotlightHMTLDocument alloc] initWithArchiveItem:archiveItem inDocumentFile:documentFile error:&error];
		
		if (htmlDocument == nil) {
			if (exampleError != error) {
				[exampleError release];
				exampleError = [error retain];
			}
			spotDocCreationErrorCount++;
			[localPool release];
			continue;
		}
		
		NSString *string = htmlDocument.string;
		if (string == nil) {
			[htmlDocument release];
			[localPool release];
			continue;
		}
		
		(mString.length ? [mString appendFormat:@" %@", string] : [mString setString:string]);
		
		if (mString.length >= CHM_MAX_FILE_SIZE) {
			[htmlDocument release];
			[localPool release];
			break;
		}
		
		[htmlDocument release];
		[localPool release];
	}
	
	if (mString.length) [mAttributes setObject:mString forKey:(id)kMDItemTextContent];
	
	if (spotDocCreationErrorCount) {
		NSLog(@"%@; %s(): *** ERROR: failed to create %lu CHMSpotlightHMTLDocument(s) for file at \"%@\"; example error == %@", MDBundleIdentifierKey, __FUNCTION__, (unsigned long)spotDocCreationErrorCount, (NSString *)pathToFile, exampleError);
	}
	
	[exampleError release];
	
#if MD_DEBUG_PERFORMANCE
	NSTimeInterval elapsedTime = ABS([startDate timeIntervalSinceNow]);
	MDLog(@"%@; %s(): elapsed time == %.5f sec (%.4f ms); %@ of text; file == \"%@\"", MDBundleIdentifierKey, __FUNCTION__,elapsedTime, elapsedTime * 1000.0, [NSByteCountFormatter stringFromByteCount:mString.length countStyle:NSByteCountFormatterCountStyleFile], (NSString *)pathToFile);
#endif

cleanup: {
	[documentFile release];
	[pool release];
}
	return TRUE;
	
}
	

