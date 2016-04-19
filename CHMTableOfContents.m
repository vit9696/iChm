//
//  CHMTableOfContent.m
//  ichm
//
//  Created by Robin Lu on 7/18/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "CHMTableOfContents.h"
#import <libxml/HTMLparser.h>
#import "CHMDocument.h"

@implementation LinkItem
@synthesize pageID;

- (id)init
{
	if ((self = [super init])) {
		_children = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) dealloc
{
	[_children release];
	[_path release];
	[_name release];
	[super dealloc];
}

- (id)initWithName:(NSString *)name Path:(NSString *)path
{
	if ((self = [super init])) {
		_name = [name retain];
		_path = [path retain];
	}
	return self;
}

- (void)setName:(NSString *)name
{
	[name retain];
	[_name release];
	_name = name;
}

- (void)setPath:(NSString *)path
{
	[path retain];
	[_path release];
	_path = path;
}

- (void)setPageID:(NSUInteger)pid
{
	pageID = pid;
}

- (NSInteger)numberOfChildren
{
	return _children ? [_children count] : 0;
}

- (LinkItem *)childAtIndex:(NSInteger)n
{
	return [_children objectAtIndex:n];
}

- (NSString *)name
{
	return _name;
}

- (NSString *)uppercaseName
{
	return [_name uppercaseString];
}

- (NSString *)path
{
	return _path;
}

- (NSMutableArray*)children
{
	return _children;
}

- (void)appendChild:(LinkItem *)item
{
	if(!_children)
		_children = [[NSMutableArray alloc] init];
	[_children addObject:item];
}

- (LinkItem*)find_by_path:(NSString *)path withStack:(NSMutableArray*)stack
{
	if ([_path isEqualToString:path])
		return self;
	
	if(!_children)
		return nil;
	
	for (LinkItem* item in _children) {
		LinkItem * rslt = [item find_by_path:path withStack:stack];
		if (rslt != nil)
		{
			if(stack)
				[stack addObject:self];
			return rslt;
		}
	}
	
	return nil;
}

- (void)enumerateItemsWithSEL:(SEL)selector ForTarget:(id)target
{
	if (![_path isEqualToString:@"/"])
		[target performSelector:selector withObject:self];
		
	for (LinkItem* item in _children)
	{
		[item enumerateItemsWithSEL:selector ForTarget:target];
	}
}

- (void)sort
{
	NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"uppercaseName" ascending:YES];
	NSMutableArray * sda = [[NSMutableArray alloc] init];
	[sda addObject:sd];
	[_children sortUsingDescriptors:sda];
	[sda release];
	[sd release];	
}

- (void)purge
{
	NSMutableIndexSet *set = [[NSMutableIndexSet alloc] init];
	for (LinkItem * item in _children) {
		if ([item name] == nil && [item path] == nil && [item numberOfChildren] == 0)
			[set addIndex:[_children indexOfObject:item]];
		else
			[item purge];
	}
	
	[_children removeObjectsAtIndexes:set];
	[set release];
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"{\n\tname:%@\n\tpath:%@\n\tchildren:%@\n}", _name, _path, _children];
}
@end



@interface CHMTableOfContents (Private)
- (void)push_item;
- (void)pop_item;
- (void)new_item;

- (void)addToPageList:(LinkItem*)item;
@end


@implementation CHMTableOfContents
@synthesize rootItems;
@synthesize pageList;

static void elementDidStart( CHMTableOfContents *toc, const xmlChar *name, const xmlChar **atts );
static void elementDidEnd( CHMTableOfContents *toc, const xmlChar *name );

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
(startElementSAXFunc) elementDidStart, /* startElement */
(endElementSAXFunc) elementDidEnd, /* endElement */
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

- (id)initWithData:(NSData *)data encodingName:(NSString*)encodingName
{
	if ((self = [super init])) {
		itemStack = [[NSMutableArray alloc] init];
		pageList = [[NSMutableArray alloc] init];
		rootItems = [[LinkItem alloc] initWithName:@"root"	Path:@"/"];
		curItem = rootItems;
		
		if(!encodingName || [encodingName length] == 0)
			encodingName = @"iso_8859_1";
		
		htmlDocPtr doc = htmlSAXParseDoc( (xmlChar *)[data bytes], [encodingName UTF8String],
									  &saxHandler, self);
		[itemStack release];
		
		if( doc ) {
			xmlFreeDoc( doc );
		}
		[rootItems purge];
		[rootItems enumerateItemsWithSEL:@selector(addToPageList:) ForTarget:self];
	}
	
	return self;
}

- (id)initWithTOC:(CHMTableOfContents*)toc filterByPredicate:(NSPredicate*)predicate
{
	if ((self = [super init])) {
		rootItems = [[LinkItem alloc] initWithName:@"root"	Path:@"/"];
		NSMutableArray *children = [rootItems children];
		if (toc) {
			LinkItem * items = [toc rootItems];
			NSArray *src_children = [items children];
			NSArray *results = [src_children filteredArrayUsingPredicate:predicate];
			[children addObjectsFromArray:results];
		}
	}
	return self;
}

- (void) dealloc
{
	[rootItems release];
	[super dealloc];
}

- (LinkItem *)itemForPath:(NSString*)path withStack:(NSMutableArray*)stack
{
	if( [path hasPrefix:@"/"] ) {
		path = [path substringFromIndex:1];
    }
	
	LinkItem *item = [rootItems find_by_path:path withStack:stack];
	if (!item)
	{
		NSString *encoded_path = [path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		item = [rootItems find_by_path:encoded_path withStack:stack];
	}
	return item;
}

- (NSInteger)rootChildrenCount
{
	return [rootItems numberOfChildren];
}

- (void)sort
{
	[rootItems sort];	
}

- (LinkItem*)getNextPage:(LinkItem*)item
{
	NSUInteger idx = [item pageID] + 1;
	if (idx == [pageList count])
		return nil;
	return [pageList objectAtIndex:idx];
}

- (LinkItem*)getPrevPage:(LinkItem*)item
{
	NSUInteger idx = [item pageID] - 1;
	if (idx == -1)
		return nil;
	return [pageList objectAtIndex:idx];
}
# pragma mark NSOutlineView datasource
- (NSInteger)outlineView:(NSOutlineView *)outlineView
numberOfChildrenOfItem:(id)item
{
	if (!item)
		item = rootItems;
	
    return [item numberOfChildren];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView
   isItemExpandable:(id)item
{
    return [item numberOfChildren] > 0;
}

- (id)outlineView:(NSOutlineView *)outlineView
			child:(NSInteger)theIndex
		   ofItem:(id)item
{
	if (!item)
		item = rootItems;
	
    return [(LinkItem *)item childAtIndex:theIndex];
}

- (id)outlineView:(NSOutlineView *)outlineView
objectValueForTableColumn:(NSTableColumn *)tableColumn
		   byItem:(id)item
{
    return [item name];
}

- (LinkItem *)curItem
{
	return curItem;
}

- (void)push_item
{
	[itemStack addObject:curItem];
}

- (void)new_item
{
    if ([itemStack count] == 0) {
        [self push_item];
    }
	LinkItem * parent = [itemStack lastObject];
	curItem = [[LinkItem alloc] init];
	[parent appendChild:curItem];
}

- (void)pop_item
{
	curItem = [itemStack lastObject];
	[itemStack removeLastObject];
}

- (void)addToPageList:(LinkItem*)item
{
	if ([item path] == nil)
		return;
	
	LinkItem* latest = [pageList lastObject];
	
	if(nil == latest)
	{
		[pageList addObject:item];
	}
	else
	{
		NSURL *baseURL = [NSURL URLWithString:@"http://dummy.com"];
		NSURL *url = [NSURL URLWithString:[item path] relativeToURL:baseURL];
		NSURL *curUrl = [NSURL URLWithString:[latest path] relativeToURL:baseURL];
		if (![[url path] isEqualToString:[curUrl path]])
			[pageList addObject:item];
	}
	[item setPageID:([pageList count] - 1)];
}

# pragma mark NSXMLParser delegation
static void elementDidStart( CHMTableOfContents *context, const xmlChar *name, const xmlChar **atts ) 
{
	if (!context)
		return;
	
    if ( !strcasecmp( "ul", (char *)name ) ) {
		[context push_item];
        return;
    }
	
    if ( !strcasecmp( "li", (char *)name ) ) {
		[context new_item];
        return;
    }
	
    if ( !strcasecmp( "param", (char *)name ) && ( atts != NULL ) ) {
		// Topic properties
		const xmlChar *type = NULL;
		const xmlChar *value = NULL;
		
		for( NSUInteger i = 0; atts[ i ] != NULL ; i += 2 ) {
			if( !strcasecmp( "name", (char *)atts[ i ] ) ) {
				type = atts[ i + 1 ];
			}
			else if( !strcasecmp( "value", (char *)atts[ i ] ) ) {
				value = atts[ i + 1 ];
			}
		}
		
		if( ( type != NULL ) && ( value != NULL ) ) {
			if( !strcasecmp( "Name", (char *)type ) || !strcasecmp( "Keyword", (char *)type )) {
				// Name of the topic
				NSString *str = [[NSString alloc] initWithUTF8String:(char *)value];
				if (![[context curItem] name])
					[[context curItem] setName:str];
				[str release];
			}
			else if( !strcasecmp( "Local", (char *)type ) ) {
				// Path of the topic
				NSString *str = [[NSString alloc] initWithUTF8String:(char *)value];
				[[context curItem] setPath:str]; 
				[str release];
			}
		}
        return;
    }
}

static void elementDidEnd( CHMTableOfContents *context, const xmlChar *name )
{
    if ( !strcasecmp( "ul", (char *)name ) ) {
		[context pop_item];
        return;
    }	
}
@end



@implementation CHMSearchResult

- (id) init
{
	if ((self = [super init])) {
		rootItems = [[ScoredLinkItem alloc] initWithName:@"root"	Path:@"/" Score:0];
	}
	return self;
}

- (id)initwithTOC:(CHMTableOfContents*)toc withIndex:(CHMTableOfContents*)index
{
	if ((self = [self init])) {
		tableOfContent = [toc retain];
		indexContent = [index retain];
	}
	return self;
}

- (void) dealloc
{
	[tableOfContent release];
	[indexContent release];
	[super dealloc];
}

- (void)addPath:(NSString*)path Score:(float)score
{
	LinkItem * item = nil;
	if (tableOfContent)
		item = [tableOfContent itemForPath:path withStack:nil];
	if (!item && indexContent)
		item = [indexContent itemForPath:path withStack:nil];
	
	if (!item)
		return;
	ScoredLinkItem * newitem = [[ScoredLinkItem alloc] initWithName:[item name] Path:[item path] Score:score];
	[rootItems appendChild:newitem];
	[newitem release];
}

- (void)sort
{
	[(ScoredLinkItem*)rootItems sort];
}
@end



@implementation ScoredLinkItem

@synthesize relScore;

- (void)sort
{
	NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"relScore" ascending:NO];
	NSMutableArray * sda = [[NSMutableArray alloc] init];
	[sda addObject:sd];
	[_children sortUsingDescriptors:sda];
	[sda release];
	[sd release];
}

- (id)initWithName:(NSString *)name Path:(NSString *)path Score:(float)score
{
	if ((self = [super initWithName:name Path:path])) {
		relScore = score;
	}
	return self;
}

@end
