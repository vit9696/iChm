//
//  CHMImageViewPopUpButton.m
//  ichm
//
//  Created by Mark Douma on 4/24/2016.
//  Copyright © 2016 Mark Douma LLC. All rights reserved.
//

#import "CHMImageViewPopUpButton.h"



#define MD_DEBUG 0

#if MD_DEBUG
#define MDLog(...) NSLog(__VA_ARGS__)
#else
#define MDLog(...)
#endif



@implementation CHMImageViewPopUpButton

- (void)awakeFromNib {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endTracking:) name:NSMenuDidEndTrackingNotification object:[self menu]];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}


- (void)mouseDown:(NSEvent *)theEvent {
	MDLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
	NSEvent *adjust = [NSEvent mouseEventWithType:[theEvent type]
										 location:[self convertPoint:NSMakePoint(1,-3) toView:nil]
									modifierFlags:[theEvent modifierFlags]
										timestamp:[theEvent timestamp]
									 windowNumber:[theEvent windowNumber]
										  context:[theEvent context]
									  eventNumber:[theEvent eventNumber]+1
									   clickCount:[theEvent clickCount]
										 pressure:[theEvent pressure]];
	
	[NSMenu popUpContextMenu:[self menu] withEvent:adjust forView:self];
}


- (void)endTracking:(NSNotification *)notification {
	MDLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	
}


- (void)drawRect:(NSRect)dirtyRect {
	NSRect frame = self.frame;
	[super drawRect:frame];
	[[NSColor colorWithCalibratedRed:0.76 green:0.76 blue:0.76 alpha:1.0] set];
	NSRect dividerRect = NSMakeRect(NSWidth(frame) - 1.0, 1.0, 1.0, NSHeight(frame) - 2.0);
	NSRectFill(dividerRect);
}


@end
