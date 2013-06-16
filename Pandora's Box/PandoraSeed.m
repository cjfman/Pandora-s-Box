//
//  PandoraSeed.m
//  Pandora's Box
//
//  Created by Charles Franklin on 2/12/13.
//  Copyright (c) 2013 Charles Franklin. All rights reserved.
//

#import "PandoraSeed.h"
#import "PandoraConnection.h"

@implementation PandoraSeed

- (id)initWithDictionary:(NSDictionary *)info
			  connection:(PandoraConnection *)newConnection
{
	if(!(self = [super init])) return nil;
	[self setValuesForKeysWithDictionary:info];
	connection = newConnection;
	return self;
}

@end