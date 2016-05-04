//
//  CHMExporter.m
//  ichm
//
//  Created by Robin Lu on 11/4/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//
#import "CHMExporter.h"
#import "CHMTableOfContents.h"
#import "CHMDocument.h"
#import <CHMKit/CHMKit.h>


#define MD_DEBUG 0

#if MD_DEBUG
#define MDLog(...) NSLog(__VA_ARGS__)
#else
#define MDLog(...)
#endif


@interface CHMExporter ()

- (void)exportNextPage;

@end


@implementation CHMExporter

@synthesize delegate;


- (id)initWithDocument:(CHMDocument *)document destinationURL:(NSURL *)destinationURL pageList:(NSArray *)list {
	
	if ((self = [super init])) {
		pageList = list;
		
		cumulativeExportedPDFPageCount = 0;
		currentPageListItemIndex = 0;
		
		webView = [[WebView alloc] init];
		[webView setPolicyDelegate:document];
		[webView setFrameLoadDelegate:self];
		[webView setResourceLoadDelegate:document];
		
		NSPrintInfo *sharedInfo = [document printInfo];
		NSMutableDictionary *printInfoDict = [NSMutableDictionary dictionaryWithDictionary:[sharedInfo dictionary]];
		[printInfoDict setObject:NSPrintSaveJob forKey:NSPrintJobDisposition];
		
		NSString *tempDirPathTemplate = [NSTemporaryDirectory() stringByAppendingPathComponent:@"com.markdouma.iChm.export.XXXXXXXX"];
		
		char *tempDirPath = mkdtemp((char *)[tempDirPathTemplate fileSystemRepresentation]);
		
		if (tempDirPath) tempDirPathTemplate = [[NSFileManager defaultManager] stringWithFileSystemRepresentation:tempDirPath length:strlen(tempDirPath)];
		
		tempDirURL = [[NSURL fileURLWithPath:tempDirPathTemplate] retain];
		tempFileURL = [[tempDirURL URLByAppendingPathComponent:@"ichm-export.pdf"] retain];
		
		[printInfoDict setObject:tempFileURL forKey:NSPrintJobSavingURL];
		
		printInfo = [[NSPrintInfo alloc] initWithDictionary:printInfoDict];
		[printInfo setHorizontalPagination:NSAutoPagination];
		[printInfo setVerticalPagination:NSAutoPagination];
		[printInfo setVerticallyCentered:NO];
		
		NSSize pageSize = [printInfo paperSize];
		pageRect = CGRectMake(0, 0, pageSize.width, pageSize.height);
		ctx = CGPDFContextCreateWithURL((CFURLRef)destinationURL, &pageRect, NULL);
	}
	return self;
}


- (void)dealloc {
	delegate = nil;
	CGPDFContextClose(ctx);
	[printInfo release];
	[webView release];
	[tempDirURL release];
	[tempFileURL release];
	[super dealloc];
}


- (void)cleanup {
	NSError *error = nil;
	if (![[NSFileManager defaultManager] removeItemAtURL:tempDirURL error:&error]) {
		NSLog(@"[%@ %@] *** ERROR: failed to remove item at \%@\"", NSStringFromClass([self class]), NSStringFromSelector(_cmd), tempDirURL.path);
	}
}

- (void)beginExport {
	[delegate exporterDidBeginExporting:self];
	[self exportNextPage];
}


- (void)exportNextPage {
	if (currentPageListItemIndex == pageList.count) {
		[self cleanup];
		[delegate exporterDidFinishExporting:self];
		return;
	}
	
	CHMLinkItem *item = [pageList objectAtIndex:currentPageListItemIndex];
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL chm__itssURLWithPath:item.path]];
	[[webView mainFrame] loadRequest:request];
	[delegate exporter:self didExportPage:cumulativeExportedPDFPageCount percentageComplete:100.0 * currentPageListItemIndex / pageList.count];
}


#pragma mark - <WebFrameLoadDelegate>
- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
	currentPageListItemIndex++;
	[self exportNextPage];
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
	currentPageListItemIndex++;
	[self exportNextPage];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
	NSView *docView = [[[webView mainFrame] frameView] documentView];
	NSPrintOperation *op = [NSPrintOperation printOperationWithView:docView printInfo:printInfo];
	[op setShowsPrintPanel:NO];
	[op setShowsProgressPanel:NO];
	[op runOperation];
	
	CGPDFDocumentRef pdfDoc = CGPDFDocumentCreateWithURL((CFURLRef)tempFileURL);
	size_t count = CGPDFDocumentGetNumberOfPages(pdfDoc);
	for (size_t i = 0; i < count; ++i) {
		CGPDFPageRef page = CGPDFDocumentGetPage(pdfDoc, i + 1);
		CGContextBeginPage(ctx, &pageRect);
		CGContextDrawPDFPage(ctx, page);
		CGContextEndPage(ctx);
		++cumulativeExportedPDFPageCount;
	}
	CGPDFDocumentRelease(pdfDoc);
	
	currentPageListItemIndex++;
	[self exportNextPage];
}

@end


