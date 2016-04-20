//
//  CHMTextEncodingMenuController.h
//  ichm
//
//  Created by Robin Lu on 8/1/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CHMTextEncodingMenuController : NSObject {
	IBOutlet NSMenuItem		*menu;
	NSMutableArray			*encodingNames;
	BOOL					initialized;
}

- (NSString*)getEncodingByTag:(NSInteger)tag;

@end
