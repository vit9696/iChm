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
@class CHMExporter;


@protocol CHMExporterDelegate <NSObject>

- (void)exporterDidBeginExporting:(CHMExporter *)anExporter;
- (void)exporter:(CHMExporter *)anExporter didExportPage:(NSUInteger)page percentageComplete:(CGFloat)percentageComplete;
- (void)exporterDidFinishExporting:(CHMExporter *)anExporter;

@end



#ifdef MAC_OS_X_VERSION_10_11
@interface CHMExporter : NSObject <WebFrameLoadDelegate> {
#else
@interface CHMExporter : NSObject {
#endif
	
	id <CHMExporterDelegate>	delegate;	// non-retained
	
	NSArray						*pageList;
	NSUInteger					currentPageListItemIndex;
	
	NSUInteger					cumulativeExportedPDFPageCount;
	
	WebView						*webView;
	CGRect						pageRect;
	CGContextRef				ctx;
	NSPrintInfo					*printInfo;
	
	NSURL						*tempDirURL;
	NSURL						*tempFileURL;
	
}

- (id)initWithDocument:(CHMDocument *)document destinationURL:(NSURL *)destinationURL pageList:(NSArray *)list;

@property (nonatomic, assign) id <CHMExporterDelegate> delegate;

- (void)beginExport;

@end


