//
//  CHMOutlineView.m
//  ichm
//
//  Created by Robin Lu on 7/28/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "CHMOutlineView.h"


@implementation CHMOutlineView
- (void)rightMouseDown:(NSEvent *)theEvent {       
	NSPoint p = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	
	NSInteger i = [self rowAtPoint:p];
	
	if (i < [self numberOfRows] && ![[self selectedRowIndexes] containsIndex:i]) {
		[self selectRowIndexes:[NSIndexSet indexSetWithIndex:i] byExtendingSelection:NO];
	}
	
	[super rightMouseDown:theEvent];
}

@end
