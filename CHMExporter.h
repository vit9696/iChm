//
//  CHMExporter.h
//  ichm
//
//  Created by Robin Lu on 11/4/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class CHMDocument;
@class WebView;

@interface CHMExporter : NSObject {
	CHMDocument *document;
	NSUInteger curPageId;
	int pageCount;
	WebView *webView;
	CGRect pageRecct;
	CGContextRef ctx;
	NSArray *pageList;
	NSPrintInfo * printInfo;
	NSString *tmpFileName;
}

- (id)initWithCHMDocument:(CHMDocument*)doc toFileName:(NSString*)filename WithPageList:(NSArray*)list;
- (void)export;
@end
