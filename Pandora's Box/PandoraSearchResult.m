//
//  PandoraSearchResult.m
//  Pandora's Box
//
//  Created by Charles Franklin on 6/16/13.
//  Copyright (c) 2013 Charles Franklin. All rights reserved.
//

#import "PandoraSearchResult.h"

@implementation PandoraSearchResult

- (id)initWithDictionary:(NSDictionary*)info {
	if (!(self = [super init])) return self;
	self.songName = nil;	// These two parameters
	self.likelyMatch = NO;	// May not get set by the info
	[self setValuesForKeysWithDictionary:info];
	return self;
}

- (bool)isArtist {
	return !(self.songName);
}

- (bool)isSong {
	return (self.songName);
}

- (NSString*) stringValue{
	if (self.isSong) {
		return [NSString stringWithFormat:
				@"%@  ~ by %@", self.songName, self.artistName];
	}
	return self.artistName;
}

- (NSComparisonResult)compare:(PandoraSearchResult*)b {
	if  (self.likelyMatch &&  b.likelyMatch) return NSOrderedSame;
	if  (self.likelyMatch && !b.likelyMatch) return NSOrderedDescending;
	if (!self.likelyMatch &&  b.likelyMatch) return NSOrderedAscending;
	if (self.score == b.score) return NSOrderedSame;
	if (self.score >  b.score) return NSOrderedDescending;
	if (self.score <  b.score) return NSOrderedAscending;
	if ([self isSong] && [b isSong])
		return [self.songName compare:b.songName];
	if ([self isArtist] && [b isArtist])
		return [self.artistName compare:b.artistName];
	if ([self isSong]) return NSOrderedAscending;
	return NSOrderedDescending;
}

@end
