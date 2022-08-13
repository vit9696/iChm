//
//  QuichChmPageAdaptor.h
//  quickchm
//
//  Created by Qian Qian on 6/29/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#ifdef CHM_BUILD_WITH_CHMOX

#import <Cocoa/Cocoa.h>
#import <CoreFoundation/CoreFoundation.h>
#import <CoreServices/CoreServices.h>

#import <QuickLook/QuickLook.h>

#import "StringUtil.h"
#import "CHMContainer.h"

CFDataRef adaptPage(NSData *page, CHMContainer *container, NSURL *pageUrl, NSMutableDictionary **dict);

#endif
