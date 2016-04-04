//
//  CHMExporter.h
//  ichm
//
//  Created by Robin Lu on 11/4/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@class CHMDocument;


@interface CHMExporter : NSObject <WebFrameLoadDelegate> {
	CHMDocument *document;
	NSUInteger curPageId;
	NSInteger pageCount;
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
