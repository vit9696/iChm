//
//  CHMSpotlightHMTLDocument.h
//  CHM Spotlight Importer
//
//  Created by Mark Douma on 5/13/2016.
//  Copyright © 2016 Mark Douma.
//

#import <Foundation/Foundation.h>

@class CHMDocumentFile;
@class CHMArchiveItem;


@interface CHMSpotlightHMTLDocument : NSObject {
	NSXMLDocument			*document;
	CHMDocumentFile			*documentFile;
	CHMArchiveItem			*archiveItem;
	
	NSString				*string;
}

- (id)initWithArchiveItem:(CHMArchiveItem *)anArchiveItem inDocumentFile:(CHMDocumentFile *)aDocumentFile error:(NSError **)outError;


@property (readonly, nonatomic, retain) NSString *string;

@end
