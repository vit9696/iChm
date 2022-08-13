//	  QuickCHM a CHM Quicklook plgin for Mac OS X 10.5
//
//    Copyright (C) 2007  Qian Qian (qiqian82@gmail.com)
//
//    QuickCHM is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    QuickCHM is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with this program.  If not, see <http://www.gnu.org/licenses/>.

#import <CoreFoundation/CoreFoundation.h>
#import <CoreFoundation/CFPlugInCOM.h>
#import <CoreServices/CoreServices.h>
#import <QuickLook/QuickLook.h>
#import <CHMKit/CHMKit.h>


OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize);
void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail);


#define MD_DEBUG 0

#if MD_DEBUG
#define MDLog(...) NSLog(__VA_ARGS__)
#else
#define MDLog(...)
#endif

static NSString * const MDCHMQuickLookBundleIdentifier = @"com.markdouma.qlgenerator.CHM";


/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef URL, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize) {
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	MDLog(@"%@; %s(): file == \"%@\"", MDCHMQuickLookBundleIdentifier, __FUNCTION__, [(NSURL *)URL path]);
	
	[CHMDocumentFile setAutomaticallyPreparesSearchIndex:NO];
	
	NSXMLDocument *htmlDoc = nil;
	
	CHMDocumentFile *documentFile = [[CHMDocumentFile alloc] initWithContentsOfFile:[(NSURL *)URL path] error:NULL];
	
	if (documentFile == nil) {
		NSLog(@"%@; %s(): failed to create CHMDocumentFile for item at \"%@\"", MDCHMQuickLookBundleIdentifier, __FUNCTION__, [(NSURL *)URL path]);
		goto cleanup;
	}
	
	if (QLThumbnailRequestIsCancelled(thumbnail)) goto cleanup;
	
	CHMLinkItem *mainPageItem = [documentFile linkItemAtPath:[documentFile homePath]];
	
	NSData *mainPageData = mainPageItem.archiveItem.data;
	
	if (mainPageData == nil) {
		NSLog(@"%@; %s(): failed to find home page for file at \"%@\"", MDCHMQuickLookBundleIdentifier, __FUNCTION__, [(NSURL *)URL path]);
		goto cleanup;
	}
	
	if (QLThumbnailRequestIsCancelled(thumbnail)) goto cleanup;
	
	NSError *error = nil;
	
	// pass NSXMLDocumentTidyXML | NSXMLDocumentTidyHTML (both) for best results, as they aren't mutually exclusive
	// NSXMLDocumentTidyXML fixes invalid XML, NSXMLDocumentTidyHTML can make strings easier to read
	
	htmlDoc = [[NSXMLDocument alloc] initWithData:mainPageData options:NSXMLDocumentTidyXML | NSXMLDocumentTidyHTML error:&error];
	if (htmlDoc == nil) {
		NSLog(@"%@; %s(): failed to create NSXMLDocument for item at \"%@\"; error == %@", MDCHMQuickLookBundleIdentifier, __FUNCTION__, [(NSURL *)URL path], error);
		goto cleanup;
	}
	
	NSArray *imgElements = [htmlDoc nodesForXPath:@".//img" error:&error];
	
	if (imgElements == nil || !imgElements.count) {
		NSLog(@"%@; %s(): failed to find <img> elements for item at \"%@\"; error == %@", MDCHMQuickLookBundleIdentifier, __FUNCTION__, [(NSURL *)URL path], error);
		goto cleanup;
	}
	
	if (QLThumbnailRequestIsCancelled(thumbnail)) goto cleanup;
	
	NSData *coverImageData = nil;
	
	for (NSXMLElement *imgElement in imgElements) {
		NSXMLNode *srcAttribute = [imgElement attributeForName:@"src"];
		NSString *path = [srcAttribute stringValue];
		
		NSData *imgData = [documentFile archiveItemAtPath:path relativeToArchiveItem:mainPageItem.archiveItem].data;
		
		if (imgData.length > coverImageData.length) coverImageData = imgData;
	}
	
	if (coverImageData) {
		QLThumbnailRequestSetImageWithData(thumbnail, (CFDataRef)coverImageData, NULL);
	}
	
	cleanup : {
		[htmlDoc release];
		[documentFile release];
		[pool release];
	}
	
	return noErr;
}

void CancelThumbnailGeneration(void* thisInterface, QLThumbnailRequestRef thumbnail) {
    // implement only if supported
}

