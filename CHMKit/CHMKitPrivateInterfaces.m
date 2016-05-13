//
//  CHMKitPrivateInterfaces.m
//  CHMKit
//
//  Created by Mark Douma on 5/4/2016.
//  Copyright © 2016 Mark Douma.
//

#import "CHMKitPrivateInterfaces.h"

@implementation NSString (CHMKitPrivateInterfaces)

- (NSString *)chm__stringByDeletingLeadingSlashes {
	while ([self hasPrefix:@"/"]) {
		self = [self substringFromIndex:1];
	}
	return self;
}

@end
