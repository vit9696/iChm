//
//  CHMSearchResult.h
//  ichm
//
//  Created by Mark Douma on 4/27/2016.
//  Copyright © 2016 Mark Douma LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CHMLinkItem;


@interface CHMSearchResult : NSObject {
	CHMLinkItem			*linkItem;
	CGFloat				score;
	
}

@property (nonatomic, retain) CHMLinkItem *linkItem;
@property (nonatomic, assign) CGFloat score;


@end
