//
//  CHMImageViewPopUpButton.m
//  ichm
//
//  Created by Mark Douma on 4/24/2016.
//  Copyright © 2016 Mark Douma LLC. All rights reserved.
//

#import "CHMImageViewPopUpButton.h"
#import <CoreImage/CoreImage.h>



#define MD_DEBUG 0

#if MD_DEBUG
#define MDLog(...) NSLog(__VA_ARGS__)
#else
#define MDLog(...)
#endif



@implementation CHMImageViewPopUpButton

- (void)awakeFromNib {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endTracking:) name:NSMenuDidEndTrackingNotification object:[self menu]];
    
    if (@available(macOS 10.14, *)) {
        if ([[self effectiveAppearance].name isEqualTo:NSAppearanceNameDarkAqua]) {
            CIImage* ciImage = [[CIImage alloc] initWithData:[self.image TIFFRepresentation]];
            CIFilter *filter = [CIFilter filterWithName:@"CIColorMatrix" withInputParameters:@{
                kCIInputImageKey:ciImage,
                @"inputRVector":[CIVector vectorWithX:-1 Y:0 Z:0],
                @"inputGVector":[CIVector vectorWithX:0 Y:-1 Z:0],
                @"inputBVector":[CIVector vectorWithX:0 Y:0 Z:-1],
                @"inputBiasVector":[CIVector vectorWithX:1 Y:1 Z:1],
            }];
    
            NSCIImageRep *rep = [NSCIImageRep imageRepWithCIImage:[filter outputImage]];
            NSImage *nsImage = [[NSImage alloc] initWithSize:rep.size];
            [nsImage addRepresentation:rep];
            self.image = nsImage;
        }
    }
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


@end
