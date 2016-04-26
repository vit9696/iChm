//
//  CHMExporter.h
//  ichm
//
//  Created by Robin Lu on 11/4/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <AvailabilityMacros.h>

@class CHMDocument;


#ifdef MAC_OS_X_VERSION_10_11
@interface CHMExporter : NSObject <WebFrameLoadDelegate> {
#else
@interface CHMExporter : NSObject {
#endif
	
	CHMDocument			*document;
	NSUInteger			curPageId;
	NSInteger			pageCount;
	WebView				*webView;
	CGRect				pageRect;
	CGContextRef		ctx;
	NSArray				*pageList;
	NSPrintInfo			*printInfo;
	NSString			*tmpFileName;
}

- (id)initWithCHMDocument:(CHMDocument *)doc toFileName:(NSString *)filename pageList:(NSArray *)list;
- (void)export;

@end
