//
//  ITSSProtocol.m
//  ichm
//
//  Created by Robin Lu on 7/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ITSSProtocol.h"
#import "CHMDocumentFile.h"


#define MD_DEBUG 0

#if MD_DEBUG
#define MDLog(...) NSLog(__VA_ARGS__)
#else
#define MDLog(...)
#endif


@implementation ITSSProtocol

- (id)initWithRequest:(NSURLRequest *)request cachedResponse:(NSCachedURLResponse *)cachedResponse client:(id <NSURLProtocolClient>)client {
    return [super initWithRequest:request cachedResponse:cachedResponse client:client];
}


+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
	return [[[request URL] scheme] isEqualToString:@"itss"];
}


+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
	return request;
}

-(void)stopLoading {
	
}

- (void)startLoading {
	
	NSURL *URL = [[self request] URL];
	
	MDLog(@"[%@ %@] URL == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), URL);
	
	CHMDocumentFile *documentFile = [[self request] documentFile];
	NSString *encodingName = [[self request] encodingName];
	
	if (documentFile == nil) {
		[[self client] URLProtocol:self didFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:nil]];
		return;
	}
	
	NSString *path;
	
	if ([URL parameterString]) {
		path = [NSString stringWithFormat:@"%@;%@", [URL path], [URL parameterString]];
	} else {
		path = [URL path];
	}
	if (![documentFile hasObjectAtPath:path]) {
		path = [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	}
	
	NSData *data = [documentFile dataForObjectAtPath:path];
	
	if (data == nil) {
		[[self client] URLProtocol:self didFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:nil]];
		return;
	}
	
	NSString *type = nil;
	
	NSString *extension = [[path pathExtension] lowercaseString];
	if ([extension isEqualToString:@"html"] ||
		[extension isEqualToString:@"htm"]) {
		type = @"text/html";
	}
	NSURLResponse *response = [[NSURLResponse alloc] initWithURL:URL
														MIMEType:type
										   expectedContentLength:data.length
												textEncodingName:encodingName];
	
	[[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
	
	[[self client] URLProtocol:self didLoadData:data];
	[[self client] URLProtocolDidFinishLoading:self];
	
	[response release];
}

@end

@implementation NSURLRequest (ITSSProtocol)

- (CHMDocumentFile *)documentFile {
	return [NSURLProtocol propertyForKey:@"chm__documentFile" inRequest:self];
}

- (NSString *)encodingName {
	return [NSURLProtocol propertyForKey:@"chm__encodingName" inRequest:self];
}

@end



@implementation NSMutableURLRequest (ITSSProtocol)

- (void)setDocumentFile:(CHMDocumentFile *)aDocumentFile {
	[NSURLProtocol setProperty:aDocumentFile forKey:@"chm__documentFile" inRequest:self];
}

- (void)setEncodingName:(NSString *)name {
	[NSURLProtocol setProperty:name forKey:@"chm__encodingName" inRequest:self];
}

@end


@implementation NSURL (ITSSProtocol)

// create a composed URL (itss://chm/*) for an item at the specified path:
+ (NSURL *)chm__itssURLWithPath:(NSString *)aPath {
	if ([NSThread isMainThread]) MDLog(@"[%@ %@] path == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), aPath);
	
	NSURL *URL = [NSURL URLWithString:[NSString stringWithFormat:@"itss://chm/%@", aPath]];
	if (URL == nil) URL = [NSURL URLWithString:[NSString stringWithFormat:@"itss://chm/%@", [aPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
	return URL;
}

@end


