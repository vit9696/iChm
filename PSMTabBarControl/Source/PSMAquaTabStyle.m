//
//  PSMAquaTabStyle.m
//  PSMTabBarControl
//
//  Created by John Pannell on 2/17/06.
//  Copyright 2006 Positive Spin Media. All rights reserved.
//

#import "PSMAquaTabStyle.h"
#import "PSMTabBarCell.h"
#import "PSMTabBarControl.h"

@implementation PSMAquaTabStyle

+ (NSString *)name {
    return @"Aqua";
}

- (NSString *)name {
	return [[self class] name];
}

#pragma mark -
#pragma mark Creation/Destruction

- (id) init {
	if((self = [super init])) {
		[self loadImages];
	}
	return self;
}

- (void) loadImages {
	// Aqua Tabs Images
	aquaTabBg = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabsBackground"]];
	[aquaTabBg setFlipped:YES];

	aquaTabBgDown = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabsDown"]];
	[aquaTabBgDown setFlipped:YES];

	aquaTabBgDownGraphite = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabsDownGraphite"]];
	[aquaTabBgDown setFlipped:YES];

	aquaTabBgDownNonKey = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabsDownNonKey"]];
	[aquaTabBgDown setFlipped:YES];

	aquaDividerDown = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabsSeparatorDown"]];
	[aquaDivider setFlipped:NO];

	aquaDivider = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabsSeparator"]];
	[aquaDivider setFlipped:NO];

	aquaCloseButton = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabClose_Front"]];
	aquaCloseButtonDown = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabClose_Front_Pressed"]];
	aquaCloseButtonOver = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabClose_Front_Rollover"]];

	aquaCloseDirtyButton = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabCloseDirty_Front"]];
	aquaCloseDirtyButtonDown = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabCloseDirty_Front_Pressed"]];
	aquaCloseDirtyButtonOver = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabCloseDirty_Front_Rollover"]];

	_addTabButtonImage = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabNew"]];
	_addTabButtonPressedImage = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabNewPressed"]];
	_addTabButtonRolloverImage = [[NSImage alloc] initByReferencingFile:[[PSMTabBarControl bundle] pathForImageResource:@"AquaTabNewRollover"]];
}

- (void)dealloc {
	[aquaTabBg release];
	[aquaTabBgDown release];
	[aquaDividerDown release];
	[aquaDivider release];
	[aquaCloseButton release];
	[aquaCloseButtonDown release];
	[aquaCloseButtonOver release];
	[aquaCloseDirtyButton release];
	[aquaCloseDirtyButtonDown release];
	[aquaCloseDirtyButtonOver release];
	[_addTabButtonImage release];
	[_addTabButtonPressedImage release];
	[_addTabButtonRolloverImage release];

	[super dealloc];
}

#pragma mark -
#pragma mark Control Specifics

- (CGFloat)leftMarginForTabBarControl:(PSMTabBarControl *)tabBarControl {
	return 0.0f;
}

- (CGFloat)rightMarginForTabBarControl:(PSMTabBarControl *)tabBarControl {
	return 0.0f;
}

- (CGFloat)topMarginForTabBarControl:(PSMTabBarControl *)tabBarControl {
	return 0.0f;
}

#pragma mark -
#pragma mark Add Tab Button

- (NSImage *)addTabButtonImage {
	return _addTabButtonImage;
}

- (NSImage *)addTabButtonPressedImage {
	return _addTabButtonPressedImage;
}

- (NSImage *)addTabButtonRolloverImage {
	return _addTabButtonRolloverImage;
}

#pragma mark -
#pragma mark Providing Images

- (NSImage *)closeButtonImageOfType:(PSMCloseButtonImageType)type forTabCell:(PSMTabBarCell *)cell
{
    switch (type) {
        case PSMCloseButtonImageTypeStandard:
            return aquaCloseButton;
        case PSMCloseButtonImageTypeRollover:
            return aquaCloseButtonOver;
        case PSMCloseButtonImageTypePressed:
            return aquaCloseButtonDown;
            
        case PSMCloseButtonImageTypeDirty:
            return aquaCloseDirtyButton;
        case PSMCloseButtonImageTypeDirtyRollover:
            return aquaCloseDirtyButtonOver;
        case PSMCloseButtonImageTypeDirtyPressed:
            return aquaCloseDirtyButtonDown;
            
        default:
            break;
    }
    
}

#pragma mark -
#pragma mark Drawing

- (void)drawBezelOfTabCell:(PSMTabBarCell *)cell withFrame:(NSRect)frame inTabBarControl:(PSMTabBarControl *)tabBarControl {

	NSRect cellFrame = frame;

	// Selected Tab
	if([cell state] == NSOnState) {
		NSRect aRect = NSMakeRect(cellFrame.origin.x, cellFrame.origin.y, cellFrame.size.width, cellFrame.size.height - 2.5);
		aRect.size.height -= 0.5;

		// proper tint
		NSControlTint currentTint;
		if([cell controlTint] == NSDefaultControlTint) {
			currentTint = [NSColor currentControlTint];
		} else{
			currentTint = [cell controlTint];
		}

		if(![tabBarControl isWindowActive]) {
			currentTint = NSClearControlTint;
		}

		NSImage *bgImage;
		switch(currentTint) {
		case NSGraphiteControlTint:
			bgImage = aquaTabBgDownGraphite;
			break;
		case NSClearControlTint:
			bgImage = aquaTabBgDownNonKey;
			break;
		case NSBlueControlTint:
		default:
			bgImage = aquaTabBgDown;
			break;
		}

        [bgImage drawInRect:cellFrame fromRect:NSMakeRect(0.0, 0.0, 1.0, 22.0) operation:NSCompositeSourceOver fraction:1.0 respectFlipped:NO hints:nil];
        
        [aquaDivider drawAtPoint:NSMakePoint(cellFrame.origin.x + cellFrame.size.width - 1.0, cellFrame.origin.y) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];

		aRect.size.height += 0.5;
	} else { // Unselected Tab
		NSRect aRect = NSMakeRect(cellFrame.origin.x, cellFrame.origin.y, cellFrame.size.width, cellFrame.size.height);
		aRect.origin.y += 0.5;
		aRect.origin.x += 1.5;
		aRect.size.width -= 1;

		aRect.origin.x -= 1;
		aRect.size.width += 1;

		// Rollover
		if([cell isHighlighted]) {
			[[NSColor colorWithCalibratedWhite:0.0 alpha:0.1] set];
			NSRectFillUsingOperation(aRect, NSCompositeSourceAtop);
		}

        [aquaDivider drawAtPoint:NSMakePoint(cellFrame.origin.x + cellFrame.size.width - 1.0, cellFrame.origin.y) fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	}
}

- (void)drawBezelOfTabBarControl:(PSMTabBarControl *)tabBarControl inRect:(NSRect)rect {
	if(rect.size.height <= 22.0) {
		//Draw for our whole bounds; it'll be automatically clipped to fit the appropriate drawing area
		rect = [tabBarControl bounds];

		[aquaTabBg drawInRect:rect fromRect:NSMakeRect(0.0, 0.0, 1.0, 22.0) operation:NSCompositeSourceOver fraction:1.0 respectFlipped:NO hints:nil];
	}
}

#pragma mark -
#pragma mark Archiving

- (void)encodeWithCoder:(NSCoder *)aCoder {
	//[super encodeWithCoder:aCoder];
	if([aCoder allowsKeyedCoding]) {
		[aCoder encodeObject:aquaTabBg forKey:@"aquaTabBg"];
		[aCoder encodeObject:aquaTabBgDown forKey:@"aquaTabBgDown"];
		[aCoder encodeObject:aquaTabBgDownGraphite forKey:@"aquaTabBgDownGraphite"];
		[aCoder encodeObject:aquaTabBgDownNonKey forKey:@"aquaTabBgDownNonKey"];
		[aCoder encodeObject:aquaDividerDown forKey:@"aquaDividerDown"];
		[aCoder encodeObject:aquaDivider forKey:@"aquaDivider"];
		[aCoder encodeObject:aquaCloseButton forKey:@"aquaCloseButton"];
		[aCoder encodeObject:aquaCloseButtonDown forKey:@"aquaCloseButtonDown"];
		[aCoder encodeObject:aquaCloseButtonOver forKey:@"aquaCloseButtonOver"];
		[aCoder encodeObject:aquaCloseDirtyButton forKey:@"aquaCloseDirtyButton"];
		[aCoder encodeObject:aquaCloseDirtyButtonDown forKey:@"aquaCloseDirtyButtonDown"];
		[aCoder encodeObject:aquaCloseDirtyButtonOver forKey:@"aquaCloseDirtyButtonOver"];
		[aCoder encodeObject:_addTabButtonImage forKey:@"addTabButtonImage"];
		[aCoder encodeObject:_addTabButtonPressedImage forKey:@"addTabButtonPressedImage"];
		[aCoder encodeObject:_addTabButtonRolloverImage forKey:@"addTabButtonRolloverImage"];
	}
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	//self = [super initWithCoder:aDecoder];
	//if (self) {
	if([aDecoder allowsKeyedCoding]) {
		aquaTabBg = [[aDecoder decodeObjectForKey:@"aquaTabBg"] retain];
		aquaTabBgDown = [[aDecoder decodeObjectForKey:@"aquaTabBgDown"] retain];
		aquaTabBgDownGraphite = [[aDecoder decodeObjectForKey:@"aquaTabBgDownGraphite"] retain];
		aquaTabBgDownNonKey = [[aDecoder decodeObjectForKey:@"aquaTabBgDownNonKey"] retain];
		aquaDividerDown = [[aDecoder decodeObjectForKey:@"aquaDividerDown"] retain];
		aquaDivider = [[aDecoder decodeObjectForKey:@"aquaDivider"] retain];
		aquaCloseButton = [[aDecoder decodeObjectForKey:@"aquaCloseButton"] retain];
		aquaCloseButtonDown = [[aDecoder decodeObjectForKey:@"aquaCloseButtonDown"] retain];
		aquaCloseButtonOver = [[aDecoder decodeObjectForKey:@"aquaCloseButtonOver"] retain];
		aquaCloseDirtyButton = [[aDecoder decodeObjectForKey:@"aquaCloseDirtyButton"] retain];
		aquaCloseDirtyButtonDown = [[aDecoder decodeObjectForKey:@"aquaCloseDirtyButtonDown"] retain];
		aquaCloseDirtyButtonOver = [[aDecoder decodeObjectForKey:@"aquaCloseDirtyButtonOver"] retain];
		_addTabButtonImage = [[aDecoder decodeObjectForKey:@"addTabButtonImage"] retain];
		_addTabButtonPressedImage = [[aDecoder decodeObjectForKey:@"addTabButtonPressedImage"] retain];
		_addTabButtonRolloverImage = [[aDecoder decodeObjectForKey:@"addTabButtonRolloverImage"] retain];
	}
	//}
	return self;
}

@end
