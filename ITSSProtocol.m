//
//  ITSSProtocol.m
//  ichm
//
//  Created by Robin Lu on 7/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "ITSSProtocol.h"
#import "CHMDocument.h"


#define MD_DEBUG 1

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
	
	NSURL *url = [[self request] URL];
	
	MDLog(@"[%@ %@] url == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), url);
	
	CHMDocument *document = [[self request] chmDoc];
	NSString *encodingName = [[self request] encodingName];
	
	if (document == nil) {
		[[self client] URLProtocol:self didFailWithError:[NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:nil]];
		return;
	}
	
	NSString *path;
	
	if ([url parameterString]) {
		path = [NSString stringWithFormat:@"%@;%@", [url path], [url parameterString]];
	} else {
		path = [url path];
	}
	if (![document hasObjectAtPath:path]) {
		path = [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	}
	
	NSData *data = [document dataForObjectAtPath:path];
	
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
	NSURLResponse *response = [[NSURLResponse alloc] initWithURL:url
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

- (CHMDocument *)chmDoc {
	return [NSURLProtocol propertyForKey:@"chmdoc" inRequest:self];
}

- (NSString *)encodingName {
	return [NSURLProtocol propertyForKey:@"encodingName" inRequest:self];
}
@end



@implementation NSMutableURLRequest (ITSSProtocol)

- (void)setChmDoc:(CHMDocument *)doc {
	[NSURLProtocol setProperty:doc forKey:@"chmdoc" inRequest:self];
}

- (void)setEncodingName:(NSString *)name {
	[NSURLProtocol setProperty:name forKey:@"encodingName" inRequest:self];
}
@end
