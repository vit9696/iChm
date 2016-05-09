//
//  CHMITSSURLProtocol.h
//  ichm
//
//  Created by Robin Lu on 7/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CHMDocumentFile;

@interface CHMITSSURLProtocol : NSURLProtocol {

}

@end

@interface NSURLRequest (CHMITSSURLProtocol)

- (CHMDocumentFile *)documentFile;
- (NSString *)encodingName;

@end

@interface NSMutableURLRequest (CHMITSSURLProtocol)

- (void)setDocumentFile:(CHMDocumentFile *)aDocumentFile;
- (void)setEncodingName:(NSString *)name;

@end


@interface NSURL (CHMITSSURLProtocol)

// create a composed URL (itss://chm/*) for an item at the specified path:
+ (NSURL *)chm__ITSSURLWithPath:(NSString *)aPath;


@end

