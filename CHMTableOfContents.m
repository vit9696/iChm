//
//  CHMTableOfContents.m
//  ichm
//
//  Created by Robin Lu on 7/18/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "CHMTableOfContents.h"
#import <libxml/HTMLparser.h>
#import "CHMLinkItem.h"


#define MD_DEBUG 0

#if MD_DEBUG
#define MDLog(...) NSLog(__VA_ARGS__)
#else
#define MDLog(...)
#endif




@interface CHMTableOfContents ()


- (void)push_item;
- (void)pop_item;
- (void)new_item;

- (CHMLinkItem *)curItem;

- (void)addToPageList:(CHMLinkItem *)item;
@end


@implementation CHMTableOfContents

@synthesize items;
@synthesize pageList;

static void elementDidStart(CHMTableOfContents *toc, const xmlChar *name, const xmlChar **atts);
static void elementDidEnd(CHMTableOfContents *toc, const xmlChar *name);

static htmlSAXHandler saxHandler = {
	NULL, /* internalSubset */
	NULL, /* isStandalone */
	NULL, /* hasInternalSubset */
	NULL, /* hasExternalSubset */
	NULL, /* resolveEntity */
	NULL, /* getEntity */
	NULL, /* entityDecl */
	NULL, /* notationDecl */
	NULL, /* attributeDecl */
	NULL, /* elementDecl */
	NULL, /* unparsedEntityDecl */
	NULL, /* setDocumentLocator */
	NULL, /* startDocument */
	NULL, /* endDocument */
	(startElementSAXFunc)elementDidStart, /* startElement */
	(endElementSAXFunc)elementDidEnd, /* endElement */
	NULL, /* reference */
	NULL, /* characters */
	NULL, /* ignorableWhitespace */
	NULL, /* processingInstruction */
	NULL, /* comment */
	NULL, /* xmlParserWarning */
	NULL, /* xmlParserError */
	NULL, /* xmlParserError */
	NULL, /* getParameterEntity */
};


- (id)initWithData:(NSData *)data encodingName:(NSString *)encodingName {
	MDLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
	if ((self = [super init])) {
		itemStack = [[NSMutableArray alloc] init];
		pageList = [[NSMutableArray alloc] init];
		itemsAndPaths = [[NSMutableDictionary alloc] init];
		
		items = [[CHMLinkItem alloc] initWithName:@"root" path:@"/"];
		curItem = items;
		
		if (!encodingName || [encodingName length] == 0) {
			encodingName = @"iso_8859_1";
		}
		
		htmlDocPtr doc = htmlSAXParseDoc((xmlChar *)[data bytes], [encodingName UTF8String], &saxHandler, self);
		[itemStack release];
		itemStack = nil;
		
		if (doc) {
			xmlFreeDoc(doc);
		}
		[items purge];
		[items enumerateItemsWithSelector:@selector(addToPageList:) forTarget:self];
		
		for (CHMLinkItem *item in pageList) {
			NSString *path = item.path;
			if (path) [itemsAndPaths setObject:item forKey:path];
		}
		
//		MDLog(@"[%@ %@] itemsAndPaths == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), itemsAndPaths);
		
	}
	
	return self;
}


- (void)dealloc {
	[items release];
	[itemStack release];
	[pageList release];
	[itemsAndPaths release];
	[super dealloc];
}


- (CHMLinkItem *)itemAtPath:(NSString *)aPath {
	MDLog(@"[%@ %@] aPath == \"%@\"", NSStringFromClass([self class]), NSStringFromSelector(_cmd), aPath);
	
	if ([aPath hasPrefix:@"/"]) aPath = [aPath substringFromIndex:1];
	
	CHMLinkItem *item = [itemsAndPaths objectForKey:aPath];
	
	if (item == nil) {
		NSString *encodedPath = [aPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		
		NSLog(@"[%@ %@] no item found at \"%@\", trying at \"%@\" instead...", NSStringFromClass([self class]), NSStringFromSelector(_cmd), aPath, encodedPath);
		
		item = [itemsAndPaths objectForKey:encodedPath];
	}
	return item;
}


- (void)sort {
	[items sort];
}

- (CHMLinkItem *)pageAfterPage:(CHMLinkItem *)item {
	NSUInteger idx = [item pageID] + 1;
	if (idx == [pageList count]) {
		return nil;
	}
	return [pageList objectAtIndex:idx];
}

- (CHMLinkItem *)pageBeforePage:(CHMLinkItem *)item {
	NSUInteger idx = [item pageID] - 1;
	if (idx == -1) {
		return nil;
	}
	return [pageList objectAtIndex:idx];
}


- (CHMLinkItem *)curItem {
	return curItem;
}

- (void)push_item {
	[itemStack addObject:curItem];
}

- (void)new_item {
    if ([itemStack count] == 0) {
        [self push_item];
    }
	CHMLinkItem *parent = [itemStack lastObject];
	curItem = [[CHMLinkItem alloc] init];
	[parent appendChild:curItem];
}


- (void)pop_item {
	curItem = [itemStack lastObject];
	[itemStack removeLastObject];
}


- (void)addToPageList:(CHMLinkItem *)item {
	if ([item path] == nil) return;
	
	CHMLinkItem *latest = [pageList lastObject];
	
	if (latest == nil) {
		[pageList addObject:item];
		
	} else {
		NSURL *baseURL = [NSURL URLWithString:@"http://dummy.com"];
		NSURL *url = [NSURL URLWithString:[item path] relativeToURL:baseURL];
		NSURL *curUrl = [NSURL URLWithString:[latest path] relativeToURL:baseURL];
		
		if (![[url path] isEqualToString:[curUrl path]]) [pageList addObject:item];
		
	}
	
	[item setPageID:([pageList count] - 1)];
}


#pragma mark NSXMLParser delegation
static void elementDidStart(CHMTableOfContents *context, const xmlChar *name, const xmlChar **atts) {
	if (context == NULL) return;
	
	if (!strcasecmp("ul", (char *)name)) {
		[context push_item];
		return;
	}
	
	if (!strcasecmp("li", (char *)name)) {
		[context new_item];
		return;
	}
	
	if (!strcasecmp("param", (char *)name) && (atts != NULL)) {
		// Topic properties
		const xmlChar *type = NULL;
		const xmlChar *value = NULL;
		
		for (NSUInteger i = 0; atts[i] != NULL; i += 2) {
			
			if (!strcasecmp("name", (char *)atts[i])) {
				type = atts[i + 1];
			} else if (!strcasecmp("value", (char *)atts[i])) {
				value = atts[i + 1];
			}
		}

		if (type && value) {
			if (!strcasecmp("Name", (char *)type) || !strcasecmp("Keyword", (char *)type)) {
				// Name of the topic
				NSString *str = [[NSString alloc] initWithUTF8String:(char *)value];
				if (![[context curItem] name]) {
					[[context curItem] setName:str];
				}
				[str release];
				
			} else if (!strcasecmp("Local", (char *)type)) {
				// Path of the topic
				NSString *str = [[NSString alloc] initWithUTF8String:(char *)value];
				[[context curItem] setPath:str];
				[str release];
			}
		}
		return;
	}
}


static void elementDidEnd(CHMTableOfContents *context, const xmlChar *name) {
	if (!strcasecmp("ul", (char *)name)) {
		[context pop_item];
		return;
	}
}


- (NSString *)description {
	NSMutableString *description = [NSMutableString stringWithFormat:@"%@\r", [super description]];
	[description appendFormat:@"     items == %@", items];
	
	return description;
}


@end

