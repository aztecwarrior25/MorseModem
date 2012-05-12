//
//  MyQueue.m
//  MyAVController
//
//  Created by Shriniwas Kulkarni on 1/30/11.
//  Copyright 2011 ASU. All rights reserved.
//

#import "MyQueue.h"


@implementation MyQueue
- (id)init {
	if (self = [super init]) {
		objects = [[NSMutableArray alloc] init];    
	}
	return self;
}
- (void)addObject:(id)object {
	@synchronized(objects) {
		[objects addObject:object];
	}
}
- (id)takeObject {
	id object = nil;
	@synchronized(objects) {
		if ([objects count] > 0) {
			object = [[[objects objectAtIndex:0] retain] autorelease];
			[objects removeObjectAtIndex:0];
		}
	}
	return object;
}
- (int)count {
	return [objects count];
}

@end
