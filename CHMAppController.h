//
//  CHMAppController.h
//  ichm
//
//  Created by Robin Lu on 7/16/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BookmarkController;


@interface CHMAppController : NSObject <NSApplicationDelegate> {
	IBOutlet NSMenu					*textEncodingMenu;
	IBOutlet BookmarkController		*bookmarkController;
	
}

- (IBAction)homepage:(id)sender;

- (BookmarkController *)bookmarkController;

@end
