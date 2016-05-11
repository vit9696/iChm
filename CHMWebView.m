//
//  CHMWebView.m
//  ichm
//
//  Created by Robin Lu on 11/4/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "CHMWebView.h"
#import "CHMDocument.h"


@implementation CHMWebView


- (void)setDocument:(CHMDocument *)doc {
	chmDocument = doc;
}

- (void)scrollPageDown:(id)sender {
	[chmDocument gotoNextPage:sender];
}

- (void)scrollPageUp:(id)sender {
	[chmDocument gotoPrevPage:sender];	
}

@end
