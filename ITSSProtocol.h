//
//  ITSSProtocol.h
//  ichm
//
//  Created by Robin Lu on 7/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CHMDocumentFile;

@interface ITSSProtocol : NSURLProtocol {

}

@end

@interface NSURLRequest (ITSSProtocol)
- (CHMDocumentFile *)documentFile;
- (NSString *)encodingName;
@end

@interface NSMutableURLRequest (ITSSProtocol)
- (void)setDocumentFile:(CHMDocumentFile *)aDocumentFile;
- (void)setEncodingName:(NSString *)name;
@end


@interface NSURL (ITSSProtocol)

// create a composed URL (itss://chm/*) for an item at the specified path:
+ (NSURL *)chm__itssURLWithPath:(NSString *)aPath;


@end

