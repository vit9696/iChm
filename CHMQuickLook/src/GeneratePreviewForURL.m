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
#import "CHMQuickLookHTMLDocument.h"

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview);


#define MD_DEBUG 0

#if MD_DEBUG
#define MDLog(...) NSLog(__VA_ARGS__)
#else
#define MDLog(...)
#endif

static NSString * const MDCHMQuickLookBundleIdentifier = @"com.markdouma.qlgenerator.CHM";


#pragma mark Generate preview

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef URL, CFStringRef contentTypeUTI, CFDictionaryRef options) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	MDLog(@"%@; %s(): file == \"%@\"", MDCHMQuickLookBundleIdentifier, __FUNCTION__, [(NSURL *)URL path]);
	
	if (![NSURLProtocol registerClass:[CHMITSSURLProtocol class]]) {
		
	}
	
	[CHMDocumentFile setAutomaticallyPreparesSearchIndex:NO];
	
	CHMQuickLookHTMLDocument *qlHTMLDoc = nil;
	
	CHMDocumentFile *documentFile = [[CHMDocumentFile alloc] initWithContentsOfFile:[(NSURL *)URL path] error:NULL];
	
	if (documentFile == nil) {
		NSLog(@"%@; %s(): failed to create CHMDocumentFile for item at \"%@\"", MDCHMQuickLookBundleIdentifier, __FUNCTION__, [(NSURL *)URL path]);
		goto cleanup;
	}
	
	if (QLPreviewRequestIsCancelled(preview)) goto cleanup;
	
	
	CHMLinkItem *homePageItem = [documentFile linkItemAtPath:[documentFile homePath]];
	if (homePageItem == nil) {
		NSLog(@"%@; %s(): failed to find home page for file at \"%@\"", MDCHMQuickLookBundleIdentifier, __FUNCTION__, [(NSURL *)URL path]);
		goto cleanup;
	}
	
	NSError *error = nil;
	qlHTMLDoc = [[CHMQuickLookHTMLDocument alloc] initWithLinkItem:homePageItem inDocumentFile:documentFile error:&error];
	if (qlHTMLDoc == nil) {
		NSLog(@"%@; %s(): *** ERROR: failed to create CHMQuickLookHTMLDocument; error == %@", MDCHMQuickLookBundleIdentifier, __FUNCTION__, error);
		goto cleanup;
	}
	
	if (QLPreviewRequestIsCancelled(preview)) goto cleanup;
	
	NSData *adaptedHTMLData = [qlHTMLDoc adaptedHTMLData];
	NSDictionary *quickLookProperties = [qlHTMLDoc quickLookProperties];
	
//	MDLog(@"%@; %s(): (CHMQuickLookHTMLDocument) quickLookProperties == %@", MDCHMQuickLookBundleIdentifier, __FUNCTION__, quickLookProperties);
	
	QLPreviewRequestSetDataRepresentation(preview, (CFDataRef)adaptedHTMLData, kUTTypeHTML, (CFDictionaryRef)quickLookProperties);
	
	cleanup : {
		[qlHTMLDoc release];
		[documentFile release];
		[pool release];
	}
	
    return noErr;
}

void CancelPreviewGeneration(void* thisInterface, QLPreviewRequestRef preview) {
	// implement only if supported
}

