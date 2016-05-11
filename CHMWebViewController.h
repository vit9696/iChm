//
//  CHMWebView.h
//  ichm
//
//  Created by Robin Lu on 7/29/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class WebView;

@interface CHMWebViewController : NSViewController {
	IBOutlet WebView		*webView;
	IBOutlet NSView			*findPanel;
	IBOutlet NSSearchField	*searchField;
}

@property (readonly) WebView *webView;
@property (readonly) NSSearchField *searchField;

- (IBAction)hideFindPanel:(id)sender;
- (IBAction)showFindPanel:(id)sender;

@end
