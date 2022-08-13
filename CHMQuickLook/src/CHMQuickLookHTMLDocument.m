//
//  CHMQuickLookHTMLDocument.m
//  quickchm
//
//  Created by Mark Douma on 5/5/2016.
//
//

#import "CHMQuickLookHTMLDocument.h"
#import <CHMKit/CHMKit.h>
#import <QuickLook/QuickLook.h>
#import <CoreServices/CoreServices.h>


#define MD_DEBUG 0

#if MD_DEBUG
#define MDLog(...) NSLog(__VA_ARGS__)
#else
#define MDLog(...)
#endif

#define MD_DEBUG_DUMP_TO_FILES 0

static inline NSStringEncoding CHMStringEncodingFromIANAEncodingName(NSString *encodingName) {
	return CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)encodingName));
}

static inline NSString *CHMIANAEncodingNameFromEncoding(NSStringEncoding encoding) {
	return (NSString *)CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(encoding));
}


@interface NSXMLElement (CHMAdditions)

- (NSXMLNode *)chm__attributeForCaseInsensitiveName:(NSString *)aName;

@end


@implementation NSXMLElement (CHMAdditions)

- (NSXMLNode *)chm__attributeForCaseInsensitiveName:(NSString *)aName {
	NSArray *attrs = [self attributes];
	for (NSXMLNode *attr in attrs) {
		if ([attr.name caseInsensitiveCompare:aName] == NSOrderedSame) return attr;
	}
	return nil;
}

@end



@interface CHMQuickLookHTMLDocument	()

@property (nonatomic, retain) NSXMLDocument *document;
@property (nonatomic, retain) CHMDocumentFile *documentFile;
@property (nonatomic, retain) CHMLinkItem *linkItem;

- (void)adaptHTML;

- (NSMutableDictionary *)attachmentsDictionary;

#if MD_DEBUG_DUMP_TO_FILES
- (void)writeDebugDataToDebugPathWithName:(NSString *)aName;
#endif

@end


#if MD_DEBUG_DUMP_TO_FILES
static NSString * MDDesktopDebugFolderPath = nil;
#endif


@implementation CHMQuickLookHTMLDocument

@synthesize document;
@synthesize documentFile;
@synthesize linkItem;
@synthesize quickLookProperties;

@dynamic adaptedHTMLData;


#if MD_DEBUG_DUMP_TO_FILES
+ (void)initialize {
	if (MDDesktopDebugFolderPath == nil) MDDesktopDebugFolderPath = [[@"~/Desktop/chmDebug" stringByExpandingTildeInPath] retain];
	
	NSError *error = nil;
	
	if (![[NSFileManager defaultManager] createDirectoryAtPath:MDDesktopDebugFolderPath withIntermediateDirectories:YES attributes:nil error:&error]) {
		NSLog(@"[%@ %@] *** ERROR: failed to create folder at \"%@\", error == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), MDDesktopDebugFolderPath, error);
	}
}
#endif


- (id)initWithLinkItem:(CHMLinkItem *)anItem inDocumentFile:(CHMDocumentFile *)aDocumentFile error:(NSError **)outError {
	if ((self = [super init])) {
		linkItem = [anItem retain];
		documentFile = [aDocumentFile retain];
		
		NSData *pageData = linkItem.archiveItem.data;
		if (pageData == nil) {
			if (outError) {
				*outError = [NSError errorWithDomain:NSCocoaErrorDomain
												code:0
											userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
													  documentFile.filePath, NSFilePathErrorKey,
													  [NSString stringWithFormat:@"Failed to obtain data for object at path \"%@\"", linkItem.path], NSLocalizedDescriptionKey, nil]];
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
		
		MDLog(@"[%@ %@] document.characterEncoding == \"%@\"", NSStringFromClass([self class]), NSStringFromSelector(_cmd), document.characterEncoding);
		
		// set the most common and likely characterEncoding, if there isn't one (ISOLatin1)
		if (document.characterEncoding == nil) {
			document.characterEncoding = CHMIANAEncodingNameFromEncoding(NSISOLatin1StringEncoding);
		}
		
		quickLookProperties = [[NSMutableDictionary alloc] init];
		
		if (document.characterEncoding) [quickLookProperties setObject:document.characterEncoding forKey:(id)kQLPreviewPropertyTextEncodingNameKey];
		[quickLookProperties setObject:@"text/html" forKey:(id)kQLPreviewPropertyMIMETypeKey];
		
		[self adaptHTML];
	}
	return self;
}


- (void)dealloc {
	[document release];
	[documentFile release];
	[quickLookProperties release];
	[linkItem release];
	[super dealloc];
}


- (NSMutableDictionary *)attachmentsDictionary {
	NSMutableDictionary *attachmentsDictionary = [quickLookProperties objectForKey:(id)kQLPreviewPropertyAttachmentsKey];
	if (attachmentsDictionary == nil) {
		attachmentsDictionary = [NSMutableDictionary dictionary];
		[quickLookProperties setObject:attachmentsDictionary forKey:(id)kQLPreviewPropertyAttachmentsKey];
	}
	return attachmentsDictionary;
}


- (NSData *)adaptedHTMLData {
	return [document XMLDataWithOptions:NSXMLNodePrettyPrint | NSXMLDocumentIncludeContentTypeDeclaration];
}


- (NSDictionary *)quickLookProperties {
	return [[quickLookProperties copy] autorelease];
}


- (NSString *)stringFromData:(NSData *)data {
	
	NSMutableSet *mTriedEncodings = [NSMutableSet set];
	
	NSMutableSet *mEncodingNames = [NSMutableSet set];
	if (document.characterEncoding) [mEncodingNames addObject:document.characterEncoding];
	if (documentFile.encodingName) [mEncodingNames addObject:documentFile.encodingName];
	
	// we want ISOLatin1 before WinLatin1
	NSArray *encodingNames = [mEncodingNames.allObjects sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	
	for (NSString *encodingName in encodingNames) {
		NSStringEncoding nsStringEncoding = CHMStringEncodingFromIANAEncodingName(encodingName);
		NSString *cssString = [[[NSString alloc] initWithData:data encoding:nsStringEncoding] autorelease];
		if (cssString) return cssString;
		[mTriedEncodings addObject:[NSNumber numberWithUnsignedInteger:nsStringEncoding]];
	}
	// prefer ISOLatin1 first, then others
	if (![mTriedEncodings containsObject:[NSNumber numberWithUnsignedInteger:NSISOLatin1StringEncoding]]) {
		NSString *cssString = [[[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding] autorelease];
		if (cssString) return cssString;
		[mTriedEncodings addObject:[NSNumber numberWithUnsignedInteger:NSISOLatin1StringEncoding]];
	}
	if (![mTriedEncodings containsObject:[NSNumber numberWithUnsignedInteger:NSUTF8StringEncoding]]) {
		NSString *cssString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		if (cssString) return cssString;
		[mTriedEncodings addObject:[NSNumber numberWithUnsignedInteger:NSUTF8StringEncoding]];
	}
	if (![mTriedEncodings containsObject:[NSNumber numberWithUnsignedInteger:NSWindowsCP1252StringEncoding]]) {
		NSString *cssString = [[[NSString alloc] initWithData:data encoding:NSWindowsCP1252StringEncoding] autorelease];
		if (cssString) return cssString;
		[mTriedEncodings addObject:[NSNumber numberWithUnsignedInteger:NSWindowsCP1252StringEncoding]];
	}
	return nil;
}


- (void)adaptCSSString:(NSMutableString *)mCSSString inArchiveItem:(CHMArchiveItem *)anItem {
	
//	MDLog(@"[%@ %@] cssString (BEFORE) == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), mCSSString);
	
	static NSCharacterSet *quotesCharacterSet = nil;
	if (quotesCharacterSet == nil) quotesCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"\"'"] retain];
	static NSCharacterSet *emptyCharacterSet = nil;
	if (emptyCharacterSet == nil) emptyCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@""] retain];
	
	NSMutableString *mAdaptedCSSString = [NSMutableString string];
	
	NSScanner *scanner = [NSScanner scannerWithString:mCSSString];
	[scanner setCharactersToBeSkipped:emptyCharacterSet];
	
	NSString *result = nil;
	NSString *URLString = nil;
	
	NSUInteger scanLocation = 0;
	
	while ([scanner isAtEnd] == NO) {
		if ([scanner scanUpToString:@"url(" intoString:&result] &&
			[scanner scanString:@"url(" intoString:NULL] &&
			[scanner scanUpToString:@")" intoString:&URLString] &&
			[scanner scanString:@")" intoString:NULL]) {
			
			if (result.length) [mAdaptedCSSString appendString:result];
			scanLocation = scanner.scanLocation;
			
			NSString *quotelessURLString = [URLString stringByTrimmingCharactersInSet:quotesCharacterSet];
			
			CHMArchiveItem *urlArchiveItem = [documentFile archiveItemAtPath:URLString relativeToArchiveItem:anItem];
			NSData *itemData = urlArchiveItem.data;
			if (urlArchiveItem == nil || itemData == nil) {
				[mAdaptedCSSString appendString:[NSString stringWithFormat:@"url(%@)", URLString]];
				continue;
			}
			
			[mAdaptedCSSString appendString:[NSString stringWithFormat:@"url(\"cid:%@\")", quotelessURLString]];
			
			NSString *MIMEType = [CHMArchiveItem MIMETypeForPathExtension:urlArchiveItem.pathExtension];
			
			NSMutableDictionary *attachments = [self attachmentsDictionary];
			NSMutableDictionary *attachmentEntry = [NSMutableDictionary dictionaryWithObjectsAndKeys:itemData,(id)kQLPreviewPropertyAttachmentDataKey, nil];
			if (MIMEType) [attachmentEntry setObject:MIMEType forKey:(id)kQLPreviewPropertyMIMETypeKey];
			[attachments setObject:attachmentEntry forKey:URLString];
			
		} else {
			[mAdaptedCSSString appendString:[mCSSString substringFromIndex:scanLocation]];
		}
	}
	
//	MDLog(@"[%@ %@] cssString (AFTER) == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), mAdaptedCSSString);
	
	[mCSSString setString:mAdaptedCSSString];
}


- (void)adaptStyleElement:(NSXMLElement *)styleElement {
	NSMutableString *mCSSString = [[styleElement.stringValue mutableCopy] autorelease];
	[self adaptCSSString:mCSSString inArchiveItem:linkItem.archiveItem];
	styleElement.stringValue = mCSSString;
}



- (void)adaptLinkElement:(NSXMLElement *)linkElement {
	NSXMLNode *typeAttr = [linkElement chm__attributeForCaseInsensitiveName:@"type"];
	NSXMLNode *hrefAttr = [linkElement chm__attributeForCaseInsensitiveName:@"href"];
	
	if (!(typeAttr && hrefAttr)) return;
	
	if (![typeAttr.stringValue isEqualToString:@"text/css"]) return;
	
	NSString *cssFilePath = [[hrefAttr.stringValue copy] autorelease];
	CHMArchiveItem *cssItem = [documentFile archiveItemAtPath:cssFilePath relativeToArchiveItem:linkItem.archiveItem];
	NSData *cssData = cssItem.data;
	if (cssData == nil) {
		
		return;
	}
	
	NSString *cssString = [self stringFromData:cssData];
	
	NSData *adaptedCSSData = cssData;
	NSString *adaptedCSSStringEncodingName = document.characterEncoding;
	
	if (cssString) {
		NSMutableString *mCSSString = [[cssString mutableCopy] autorelease];
		[self adaptCSSString:mCSSString inArchiveItem:cssItem];
		
		adaptedCSSData = [mCSSString dataUsingEncoding:NSUTF8StringEncoding];
		adaptedCSSStringEncodingName = CHMIANAEncodingNameFromEncoding(NSUTF8StringEncoding);
	}
	
	NSString *contentIDFilePath = [@"cid:" stringByAppendingString:cssFilePath];
	hrefAttr.stringValue = contentIDFilePath;
	
	NSMutableDictionary *attachments = [self attachmentsDictionary];
	NSMutableDictionary *attachmentEntry = [NSMutableDictionary dictionaryWithObjectsAndKeys:adaptedCSSData,(id)kQLPreviewPropertyAttachmentDataKey,
											@"text/css",(id)kQLPreviewPropertyMIMETypeKey, nil];
	if (adaptedCSSStringEncodingName) [attachmentEntry setObject:adaptedCSSStringEncodingName forKey:(id)kQLPreviewPropertyTextEncodingNameKey];
	[attachments setObject:attachmentEntry forKey:cssFilePath];
	
}


- (void)adaptImageElement:(NSXMLElement *)imgElement {
	NSXMLNode *srcAttr = [imgElement chm__attributeForCaseInsensitiveName:@"src"];
	if (srcAttr == nil) {
		return;
	}
	NSString *imgFilePath = [[srcAttr.stringValue copy] autorelease];
	NSData *imgData = [documentFile archiveItemAtPath:imgFilePath relativeToArchiveItem:linkItem.archiveItem].data;
	if (imgData == nil) {
		
		return;
	}
	
	NSString *contentIDFilePath = [@"cid:" stringByAppendingString:imgFilePath];
	srcAttr.stringValue = contentIDFilePath;
	NSString *mimeType = [CHMArchiveItem MIMETypeForPathExtension:[imgFilePath pathExtension]];
	
	NSMutableDictionary *attachments = [self attachmentsDictionary];
	NSMutableDictionary *attachmentEntry = [NSMutableDictionary dictionaryWithObjectsAndKeys:imgData,(id)kQLPreviewPropertyAttachmentDataKey, nil];
	if (mimeType) [attachmentEntry setObject:mimeType forKey:(id)kQLPreviewPropertyMIMETypeKey];
	[attachments setObject:attachmentEntry forKey:imgFilePath];
}



- (void)adaptHTML {
#if MD_DEBUG_DUMP_TO_FILES
	[self writeDebugDataToDebugPathWithName:@"chm__Before.html"];
#endif
	
	NSXMLNode *nextNode = document;
	
	while ((nextNode = [nextNode nextNode])) {
		NSXMLNodeKind kind = nextNode.kind;
		
		if (kind == NSXMLElementKind) {
			
			NSXMLElement *element = (NSXMLElement *)nextNode;
			
			NSString *elementName = [[element name] lowercaseString];
			
			if ([elementName isEqualToString:@"link"]) {
				[self adaptLinkElement:element];
				
			} else if ([elementName isEqualToString:@"a"]) {
				
				
			} else if ([elementName isEqualToString:@"img"]) {
				[self adaptImageElement:element];
				
			} else if ([elementName isEqualToString:@"style"]) {
				[self adaptStyleElement:element];
				
			}
			
			NSXMLNode *styleAttr = [element chm__attributeForCaseInsensitiveName:@"style"];
			if (styleAttr) {
				NSMutableString *mCSSString = [[styleAttr.stringValue mutableCopy] autorelease];
				[self adaptCSSString:mCSSString inArchiveItem:linkItem.archiveItem];
				styleAttr.stringValue = mCSSString;
			}
		}
	}
	
#if MD_DEBUG_DUMP_TO_FILES
	[self writeDebugDataToDebugPathWithName:@"chm__After.html"];
#endif
	
}


#if MD_DEBUG_DUMP_TO_FILES
- (void)writeDebugDataToDebugPathWithName:(NSString *)aName {
	static NSDateFormatter *dateFormatter = nil;
	
	if (dateFormatter == nil) {
		dateFormatter = [[NSDateFormatter alloc] init];
		dateFormatter.dateStyle = NSDateFormatterShortStyle;
		dateFormatter.timeStyle = NSDateFormatterMediumStyle;
	}
	
	NSString *baseName = [aName stringByDeletingPathExtension];
	NSString *uniqueBaseName = [baseName stringByAppendingFormat:@"__%@__", [dateFormatter stringFromDate:[NSDate date]]];
	
	uniqueBaseName = [uniqueBaseName stringByReplacingOccurrencesOfString:@":" withString:@""];
	uniqueBaseName = [uniqueBaseName stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
	uniqueBaseName = [uniqueBaseName stringByReplacingOccurrencesOfString:@", " withString:@"__"];
	
	NSString *uniqueName = [uniqueBaseName stringByAppendingPathExtension:[aName pathExtension]];
	
	NSData *debugData = [self adaptedHTMLData];
	NSError *error = nil;
	
	if (![debugData writeToFile:[MDDesktopDebugFolderPath stringByAppendingPathComponent:uniqueName] options:NSDataWritingAtomic error:&error]) {
		NSLog(@"*** ERROR: failed to write debugData to \"%@\", error == %@", [MDDesktopDebugFolderPath stringByAppendingPathComponent:uniqueName], error);
	}
}
#endif


@end

