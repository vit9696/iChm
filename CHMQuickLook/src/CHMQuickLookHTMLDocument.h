//
//  CHMQuickLookHTMLDocument.h
//  quickchm
//
//  Created by Mark Douma on 5/5/2016.
//
//

#import <Foundation/Foundation.h>

@class CHMDocumentFile;
@class CHMLinkItem;


@interface CHMQuickLookHTMLDocument : NSObject {
	NSXMLDocument			*document;
	CHMDocumentFile			*documentFile;
	CHMLinkItem				*linkItem;
	NSMutableDictionary		*quickLookProperties;
	
}

- (id)initWithLinkItem:(CHMLinkItem *)anItem inDocumentFile:(CHMDocumentFile *)aDocumentFile error:(NSError **)outError;


@property (readonly, nonatomic, retain) NSData *adaptedHTMLData;

@property (readonly, nonatomic, copy) NSDictionary *quickLookProperties;


@end

