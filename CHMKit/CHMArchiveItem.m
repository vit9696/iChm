//
//  CHMArchiveItem.m
//  ichm
//
//  Created by Mark Douma on 5/11/2016.
//  Copyright © 2016 Mark Douma LLC. All rights reserved.
//

#import "CHMArchiveItem.h"
#import "CHMDocumentFile.h"
#import "CHMKitPrivateInterfaces.h"
#import <CHM/CHM.h>


#define MD_DEBUG 0

#if MD_DEBUG
#define MDLog(...) NSLog(__VA_ARGS__)
#else
#define MDLog(...)
#endif


static int CHMEnumerateItems(struct chmFile *chmHandle, struct chmUnitInfo *unitInfo, void *context) {
	
	if (unitInfo->flags & CHM_ENUMERATE_NORMAL && (unitInfo->flags & CHM_ENUMERATE_FILES || unitInfo->flags & CHM_ENUMERATE_DIRS)) {
		NSMutableDictionary *fileAndDirPaths = (NSMutableDictionary *)context;
		
		NSString *itemPath = [NSString stringWithUTF8String:unitInfo->path];
		
		if (unitInfo->flags & CHM_ENUMERATE_FILES) {
			NSMutableArray *filePaths = [fileAndDirPaths objectForKey:@"chmFiles"];
			if (itemPath) [filePaths addObject:itemPath];
			
		} else if (unitInfo->flags & CHM_ENUMERATE_DIRS) {
			NSMutableArray *dirPaths = [fileAndDirPaths objectForKey:@"chmDirs"];
			if (itemPath) [dirPaths addObject:[itemPath stringByStandardizingPath]];
		}
	}
	return CHM_ENUMERATOR_CONTINUE;
}


@implementation CHMArchiveItem

@synthesize documentFile;
@synthesize parent;
@synthesize childNodes;
@synthesize isLeaf;
@synthesize name;
@synthesize path;
@dynamic pathExtension;
@dynamic isRootNode;


+ (id)rootArchiveItemWithDocumentFile:(CHMDocumentFile *)aDocumentFile chmFileHandle:(struct chmFile *)aChmFileHandle {
	NSMutableDictionary *fileAndDirPaths = [NSMutableDictionary dictionary];
	[fileAndDirPaths setObject:[NSMutableArray array] forKey:@"chmDirs"];
	[fileAndDirPaths setObject:[NSMutableArray array] forKey:@"chmFiles"];
	
	if (!chm_enumerate(aChmFileHandle, CHM_ENUMERATE_ALL, CHMEnumerateItems, (void *)fileAndDirPaths)) {
		NSLog(@"[%@ %@] *** ERROR: chm_enumerate() failed for file at \"%@\"", NSStringFromClass([self class]), NSStringFromSelector(_cmd), aDocumentFile.filePath);
		return nil;
	}
	
	NSMutableDictionary *dirPathsAndFilePaths = [NSMutableDictionary dictionary];
	
	NSMutableArray *filePaths = [fileAndDirPaths objectForKey:@"chmFiles"];
	
	for (NSString *filePath in filePaths) {
		NSString *parentDirPath = [filePath stringByDeletingLastPathComponent];
		NSMutableArray *parentDirPathEntries = [dirPathsAndFilePaths objectForKey:parentDirPath];
		if (parentDirPathEntries == nil) {
			parentDirPathEntries = [NSMutableArray array];
			[dirPathsAndFilePaths setObject:parentDirPathEntries forKey:parentDirPath];
		}
		[parentDirPathEntries addObject:filePath];
	}
	
	CHMArchiveItem *rootArchiveItem = nil;
	
	NSMutableArray *chmDirPaths = [fileAndDirPaths objectForKey:@"chmDirs"];
	[chmDirPaths sortUsingSelector:@selector(localizedStandardCompare:)];
	
	for (NSString *chmDirPath in chmDirPaths) {
		
		NSMutableArray *itemChildPaths = [dirPathsAndFilePaths objectForKey:chmDirPath];
		
		CHMArchiveItem *archiveItem = [[CHMArchiveItem alloc] initDirectoryArchiveItemWithPath:chmDirPath childNodePaths:itemChildPaths documentFile:aDocumentFile];
		if (rootArchiveItem == nil) {
			rootArchiveItem = archiveItem;
		} else {
			NSString *parentDirPath = [chmDirPath stringByDeletingLastPathComponent];
			
			CHMArchiveItem *parentDirItem = nil;
			
			if ([parentDirPath isEqualToString:@"/"]) {
				parentDirItem = rootArchiveItem;
			} else {
				parentDirItem = [rootArchiveItem descendantAtPath:parentDirPath];
				
			}
			[parentDirItem insertChildNode:archiveItem];
			[archiveItem release];
		}
	}
	return [rootArchiveItem autorelease];
}


- (id)initDirectoryArchiveItemWithPath:(NSString *)aPath childNodePaths:(NSArray *)childNodePaths documentFile:(CHMDocumentFile *)aDocumentFile {
	if ((self = [super init])) {
		path = [aPath retain];
		name = [[path lastPathComponent] retain];
		documentFile = aDocumentFile;
		isLeaf = NO;
		childNodes = [[NSMutableArray alloc] init];
		
		if (childNodePaths.count) {
			NSMutableArray *createdChildNodes = [NSMutableArray array];
			
			for (NSString *childNodePath in childNodePaths) {
				CHMArchiveItem *archiveItem = [[CHMArchiveItem alloc] initLeafArchiveItemWithPath:childNodePath documentFile:documentFile];
				if (archiveItem) [createdChildNodes addObject:archiveItem];
				[archiveItem release];
			}
			[self insertChildNodes:createdChildNodes];
		}
	}
	return self;
}


- (id)initLeafArchiveItemWithPath:(NSString *)aPath documentFile:(CHMDocumentFile *)aDocumentFile {
	if ((self = [super init])) {
		path = [aPath retain];
		name = [[path lastPathComponent] retain];
		documentFile = aDocumentFile;
		isLeaf = YES;
	}
	return self;
}


- (void)dealloc {
	parent = nil;
	documentFile = nil;
	[path release];
	[name release];
	[childNodes release];
	[super dealloc];
}


- (NSString *)pathExtension {
	return [[path pathExtension] lowercaseString];
}


- (NSArray *)childNodes {
	return [[childNodes copy] autorelease];
}


- (void)insertChildNode:(CHMArchiveItem *)aChildNode {
	[aChildNode setParent:self];
	[childNodes addObject:aChildNode];
}


- (void)insertChildNodes:(NSArray *)newChildren {
	[newChildren makeObjectsPerformSelector:@selector(setParent:) withObject:self];
	[childNodes addObjectsFromArray:newChildren];
}


- (BOOL)isRootNode {
	return (parent == nil);
}


- (NSArray *)descendants {
	NSMutableArray  *descendants = [[NSMutableArray alloc] init];
	for (CHMArchiveItem *node in childNodes) {
		[descendants addObject:node];
		
		if (!node.isLeaf) {
			[descendants addObjectsFromArray:[node descendants]];   // Recursive - will go down the chain to get all
		}
	}
	return [descendants autorelease];
}


- (CHMArchiveItem *)descendantAtPath:(NSString *)aPath {
//	MDLog(@"[%@ %@] aPath == %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), aPath);
	
	if (aPath == nil) return nil;
	
	NSArray *pathComponents = [aPath pathComponents];
	
	NSMutableArray *revisedPathComponents = [NSMutableArray array];
	
	for (NSString *component in pathComponents) {
		if (![component isEqualToString:@"/"]) [revisedPathComponents addObject:component];
	}
	
	NSUInteger count = [revisedPathComponents count];
	
	if (count == 0) return nil;
	
	NSString *targetName = [revisedPathComponents objectAtIndex:0];
	NSString *remainingPath = nil;
	
	if (count > 1) remainingPath = [NSString pathWithComponents:[revisedPathComponents subarrayWithRange:NSMakeRange(1, (count - 1))]];
	
	for (CHMArchiveItem *child in childNodes) {
		if ([[child name] isEqualToString:targetName]) {
			if (remainingPath == nil) {
				return child;
			}
			// if there's remaining path left, and the child isn't a folder, then bail
			if ([child isLeaf]) return nil;
			
			return [child descendantAtPath:remainingPath];
		}
	}
	return nil;
}

- (NSData *)data {
	if (isLeaf)	return [documentFile dataForObjectAtPath:path];
	return nil;
}


- (void)sortWithSortDescriptors:(NSArray *)sortDescriptors recursively:(BOOL)recursively {
	if (isLeaf) return;
	[childNodes sortUsingDescriptors:sortDescriptors];
	if (recursively) {
		for (CHMArchiveItem *childNode in childNodes) {
			if (childNode.isLeaf) continue;
			[childNode sortWithSortDescriptors:sortDescriptors recursively:recursively];
		}
	}
}


- (NSString *)description {
	NSMutableString *description = [NSMutableString stringWithFormat:@"<%@> %@", NSStringFromClass([self class]), self.name];
	if (childNodes) [description appendFormat:@"\r          childNodes == %@", childNodes];
	
	[description replaceOccurrencesOfString:@"\\n" withString:@"\r" options:0 range:NSMakeRange(0, description.length)];
	[description replaceOccurrencesOfString:@"\\\"" withString:@"" options:0 range:NSMakeRange(0, description.length)];
	return description;
}



@end
