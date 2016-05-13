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
	CHMLinkItem			*item;
	CGFloat				score;
	
}

@property (nonatomic, retain) CHMLinkItem *item;
@property (nonatomic, assign) CGFloat score;


@end
