//
//  ITSSProtocol.h
//  ichm
//
//  Created by Robin Lu on 7/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CHMDocument;

@interface ITSSProtocol : NSURLProtocol {

}

@end

@interface NSURLRequest (ITSSProtocol)
- (CHMDocument *)chmDoc;
- (NSString *)encodingName;
@end

@interface NSMutableURLRequest (ITSSProtocol)
- (void)setChmDoc:(CHMDocument *)doc;
- (void)setEncodingName:(NSString *)name;
@end

