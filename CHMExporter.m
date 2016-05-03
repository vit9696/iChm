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
#import "ITSSProtocol.h"


@implementation CHMExporter


- (id)initWithCHMDocument:(CHMDocument*)doc toFileName:(NSString*)filename pageList:(NSArray*)list {
	
	if ((self = [super init])) {
		document = [doc retain];
		pageList = list;
		
		pageCount = 0;
		curPageId = 0;
		webView = [[WebView alloc] init];
		[webView setPolicyDelegate:document];
		[webView setFrameLoadDelegate:self];
		[webView setResourceLoadDelegate:document];
		
		NSURL *fileURL = [NSURL fileURLWithPath:filename];
		
		NSPrintInfo *sharedInfo = [document printInfo];
		NSMutableDictionary *printInfoDict = [NSMutableDictionary dictionaryWithDictionary:[sharedInfo dictionary]];
		[printInfoDict setObject:NSPrintSaveJob forKey:NSPrintJobDisposition];
		
		tmpFileName = [[NSString stringWithFormat:@"%@/ichm-export.pdf", NSTemporaryDirectory()] retain];
		
		[printInfoDict setObject:tmpFileName forKey:NSPrintSavePath];
		
		printInfo = [[NSPrintInfo alloc] initWithDictionary:printInfoDict];
		[printInfo setHorizontalPagination: NSAutoPagination];
		[printInfo setVerticalPagination: NSAutoPagination];
		[printInfo setVerticallyCentered:NO];
		
		NSSize pageSize = [printInfo paperSize];
		pageRect = CGRectMake(0, 0, pageSize.width, pageSize.height);
		ctx = CGPDFContextCreateWithURL((CFURLRef)fileURL, &pageRect, NULL);
		[self retain];
	}
	return self;
}


- (void)dealloc {
	CGPDFContextClose(ctx);
	[tmpFileName release];
	[printInfo release];
	[webView release];
	[document release];
	[super dealloc];
}


- (void)export {
	if (curPageId == [pageList count]) {
		[self release];
		[document endExportProgressSheet:nil];
		return;
	}
	CHMLinkItem *page = [pageList objectAtIndex:curPageId];
	
	NSURL *url = [NSURL chm__itssURLWithPath:[page path]];
	NSURLRequest *req = [NSURLRequest requestWithURL:url];
	[[webView mainFrame] loadRequest:req];
	
	double rate = 100.0 * curPageId / [pageList count];
	[document exportedProgressRate:rate PageCount:pageCount];
}


#pragma mark WebFrameLoadDelegate
- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
	curPageId += 1;
	[self export];
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame {
	curPageId += 1;
	[self export];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
	NSView *docView = [[[webView mainFrame] frameView] documentView];
	NSPrintOperation *op = [NSPrintOperation printOperationWithView:docView printInfo:printInfo];
	[op setShowPanels:NO];
	[op runOperation];
	
	NSURL *url = [NSURL fileURLWithPath:tmpFileName];
	CGPDFDocumentRef pdfDoc = CGPDFDocumentCreateWithURL((CFURLRef)url);
	size_t count = CGPDFDocumentGetNumberOfPages(pdfDoc);
	for (size_t i = 0; i < count; ++i) {
		CGPDFPageRef page = CGPDFDocumentGetPage(pdfDoc, i + 1);
		CGContextBeginPage(ctx, &pageRect);
		CGContextDrawPDFPage(ctx, page);
		CGContextEndPage(ctx);
		++pageCount;
	}
	CGPDFDocumentRelease(pdfDoc);
	
	curPageId += 1;
	[self export];
}

@end


