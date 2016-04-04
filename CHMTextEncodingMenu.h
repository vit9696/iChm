//
//  CHMTextEncodingMenu.h
//  ichm
//
//  Created by Robin Lu on 8/1/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CHMTextEncodingMenu : NSObject {
	IBOutlet NSMenuItem *menu;
	BOOL initialized;
	NSMutableArray *encodingNames;
}

- (void)initEncodingMenu;
- (NSString*)getEncodingByTag:(NSInteger)tag;
@end
