//
//  CHMExporter.m
//  ichm
//
//  Created by Robin Lu on 11/4/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//
#import <WebKit/WebKit.h>
#import "CHMExporter.h"
#import "CHMTableOfContent.h"
#import "CHMDocument.h"

@implementation CHMExporter
- (id)initWithCHMDocument:(CHMDocument*)doc toFileName:(NSString*)filename WithPageList:(NSArray*)list
{
	document = doc;
	[document retain];
	pageList = list;

	pageCount = 0;
	curPageId = 0;
	webView = [[WebView alloc] init];
	[webView setPolicyDelegate:document];
	[webView setFrameLoadDelegate:self];
	[webView setResourceLoadDelegate:document];	

	CFURLRef fileURL = CFURLCreateWithFileSystemPath(NULL, 
													 (CFStringRef) filename, kCFURLPOSIXPathStyle, false);
	NSPrintInfo * sharedInfo = [document printInfo];
	NSMutableDictionary *printInfoDict = [NSMutableDictionary dictionaryWithDictionary: [sharedInfo dictionary]];
	[printInfoDict setObject:NSPrintSaveJob 
					  forKey:NSPrintJobDisposition];
	tmpFileName = [NSString stringWithFormat:@"%@/ichm-export.pdf", NSTemporaryDirectory()];
	[tmpFileName retain];
	[printInfoDict setObject:tmpFileName forKey:NSPrintSavePath];
	printInfo = [[NSPrintInfo alloc] initWithDictionary: printInfoDict];
	[printInfo setHorizontalPagination: NSAutoPagination];
	[printInfo setVerticalPagination: NSAutoPagination];
	[printInfo setVerticallyCentered:NO];	
	
	NSSize pageSize = [printInfo paperSize];
	pageRecct = CGRectMake(0	, 0, pageSize.width , pageSize.height);
	ctx = CGPDFContextCreateWithURL(fileURL, &pageRecct, NULL);	
	CFRelease(fileURL);
	[self retain];
	return self;
}

- (void)export
{
	if (curPageId == [pageList count])
	{
		[self release];
		[document endExportProgressSheet:nil];
		return;
	}
	
	LinkItem *page = [pageList objectAtIndex:curPageId];
	
	NSURL *url = [document composeURL:[page path]];
	NSURLRequest *req = [NSURLRequest requestWithURL:url];
	[[webView mainFrame] loadRequest:req];
	
	double rate = 100.0 * curPageId / [pageList count];
	[document exportedProgressRate:rate PageCount:pageCount];
}

- (void)dealloc
{
	CGPDFContextClose(ctx);	
	[tmpFileName release];
	[printInfo release];
	[webView release];
	[document release];
	[super dealloc];
}

#pragma mark WebFrameLoadDelegate
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	NSView *docView = [[[webView mainFrame] frameView] documentView];
	NSPrintOperation *op = [NSPrintOperation printOperationWithView:docView 
														  printInfo:printInfo];
	[op setShowPanels:NO];
	[op runOperation];
	
	NSURL *url = [NSURL fileURLWithPath:tmpFileName];
	CGPDFDocumentRef pdfDoc = CGPDFDocumentCreateWithURL((CFURLRef)url);
	size_t count = CGPDFDocumentGetNumberOfPages(pdfDoc);
	for (size_t i = 0; i< count ;++i) {
		CGPDFPageRef page = CGPDFDocumentGetPage(pdfDoc, i+1);
		CGContextBeginPage(ctx, &pageRecct);
		CGContextDrawPDFPage(ctx, page);
		CGContextEndPage(ctx);
		++pageCount;
	}
	CGPDFDocumentRelease(pdfDoc);
	
	curPageId += 1;
	[self export];
}
@end
