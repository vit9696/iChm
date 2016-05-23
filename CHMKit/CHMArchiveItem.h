//
//  CHMArchiveItem.h
//  ichm
//
//  Created by Mark Douma on 5/11/2016.
//  Copyright © 2016 Mark Douma LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CHMDocumentFile;


@interface CHMArchiveItem : NSObject {
	CHMDocumentFile		*documentFile;	// non-retained
	
	CHMArchiveItem		*parent;		// non-retained

    NSMutableArray		*childNodes;
	
	NSString			*name;
	
	NSString			*path;
	
	BOOL				isLeaf;
	
@private
	id chm__privateData;
	
}

@property (readonly, nonatomic, assign) CHMDocumentFile *documentFile;

@property (readonly, nonatomic, assign) CHMArchiveItem *parent;

@property (readonly, nonatomic, retain) NSArray *childNodes;

@property (readonly, nonatomic, assign) BOOL isLeaf;

@property (readonly, nonatomic, assign) BOOL isRootNode;

@property (readonly, nonatomic, retain) NSString *name;

@property (readonly, nonatomic, retain) NSString *path;

// convenience, will be lowercase
@property (readonly, nonatomic, retain) NSString *pathExtension;


- (NSArray *)descendants;

- (CHMArchiveItem *)descendantAtPath:(NSString *)aPath;

- (NSData *)data;
+ (NSString *)MIMETypeForPathExtension:(NSString *)aPathExtension;

@end
