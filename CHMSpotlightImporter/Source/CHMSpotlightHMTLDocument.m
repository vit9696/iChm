//
//  CHMSpotlightHMTLDocument.m
//  CHM Spotlight Importer
//
//  Created by Mark Douma on 5/13/2016.
//  Copyright © 2016 Mark Douma.
//

#import "CHMSpotlightHMTLDocument.h"
#import <CHMKit/CHMKit.h>


#define MD_DEBUG 0

#if MD_DEBUG
#define MDLog(...) NSLog(__VA_ARGS__)
#else
#define MDLog(...)
#endif




@interface CHMSpotlightHMTLDocument ()

@property (nonatomic, retain) NSXMLDocument *document;
@property (nonatomic, retain) CHMDocumentFile *documentFile;
@property (nonatomic, retain) CHMArchiveItem *archiveItem;
@property (nonatomic, retain) NSString *string;

- (void)extractStringData;

@end



static NSCharacterSet *whitespaceCharacterSet = nil;


@implementation CHMSpotlightHMTLDocument

@synthesize documentFile;
@synthesize document;
@synthesize archiveItem;
@synthesize string;


+ (void)initialize {
	
	/* This `initialized` flag is used to guard against the rare cases where Cocoa bindings
	 may cause `+initialize` to be called twice: once for this class, and once for the isa-swizzled class: 
	 
	 `[NSKVONotifying_MDClassName initialize]`
	 
	 */
	
	static BOOL initialized = NO;
	
	@synchronized(self) {
		
		if (initialized == NO) {
			whitespaceCharacterSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] retain];
			initialized = YES;
		}
	}
}


- (id)initWithArchiveItem:(CHMArchiveItem *)anArchiveItem inDocumentFile:(CHMDocumentFile *)aDocumentFile error:(NSError **)outError {
	if ((self = [super init])) {
		archiveItem = [anArchiveItem retain];
		documentFile = [aDocumentFile retain];
		
		NSData *pageData = archiveItem.data;
		if (pageData == nil) {
			if (outError) {
				*outError = [NSError errorWithDomain:NSCocoaErrorDomain
												code:0
											userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
													  documentFile.filePath, NSFilePathErrorKey,
													  [NSString stringWithFormat:@"Failed to obtain data for object at path \"%@\"", archiveItem.path], NSLocalizedDescriptionKey, nil]];
			}
			[self release];
			return nil;
		}
		
		NSError *error = nil;
		
		// pass NSXMLDocumentTidyXML | NSXMLDocumentTidyHTML (both) for best results, as they aren't mutually exclusive
		// NSXMLDocumentTidyXML fixes invalid XML, NSXMLDocumentTidyHTML can make strings easier to read
		
		document = [[NSXMLDocument alloc] initWithData:pageData options:NSXMLDocumentTidyXML | NSXMLDocumentTidyHTML error:&error];
		
		if (document == nil) {
			if (outError && error) {
				*outError = [NSError errorWithDomain:NSCocoaErrorDomain
												code:0
											userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
													  documentFile.filePath, NSFilePathErrorKey,
													  error, NSUnderlyingErrorKey, nil]];
			}
			[self release];
			return nil;
		}
		
		[self extractStringData];
	}
	return self;
}


- (void)dealloc {
	[document release];
	[documentFile release];
	[archiveItem release];
	[string release];
	[super dealloc];
}


- (void)extractStringData {
	
	NSError *error = nil;
	NSArray *textNodes = [document nodesForXPath:@".//body//text()" error:&error];
	
	NSMutableString *mString = nil;
	
	for (NSXMLNode *textNode in textNodes) {
		NSString *trimmedStringValue = [textNode.stringValue stringByTrimmingCharactersInSet:whitespaceCharacterSet];
		if (trimmedStringValue.length) {
			if (mString == nil) {
				mString = [[NSMutableString alloc] initWithString:trimmedStringValue];
				continue;
			}
			[mString appendFormat:@" %@", trimmedStringValue];
		}
	}
	
	self.string = mString;
	[mString release];
	
}


@end

