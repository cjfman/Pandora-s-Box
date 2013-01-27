//
//  PandoraStation.m
//  Pandora's Box
//
//  Created by Charles Franklin on 1/3/13.
//  Copyright (c) 2013 Charles Franklin. All rights reserved.
//

#import "PandoraStation.h"
#import "PandoraConnection.h"
#import "PandoraSong.h"

@implementation PandoraStation

- (id)initWithDictionary:(NSDictionary*)info connection:(PandoraConnection*)newConnection
{
	if(!(self = [super init])) return self;
	[self setValuesForKeysWithDictionary:info];
	connection = newConnection;
	//currentSong = nil;
	playList = [[NSMutableArray alloc] init];
	//justPlayed = [[NSMutableArray alloc] init];
	currentIndex = -1;
	return self;
}

- (NSArray*)getPlaylist
{
	if(!self.stationToken) return nil;
	NSLog(@"Getting New Playlist");
	
	/*
	NSString *formats = [NSString stringWithFormat: @"%@,%@,%@,%@",
						@"HTTP_64_AACPLUS",
						@"HTTP_32_AACPLUS",
						@"HTTP_64_AAC",
						@"HTTP_128_MP3"];
	//*/
	
	NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									   self.stationToken, @"stationToken",
									   //formats, @"additionalAudioUrl",
									   nil];
	NSError *error = nil;
	NSDictionary *response = [connection jsonRequest:@"station.getPlaylist" withParameters:parameters useTLS:TRUE isEncrypted:TRUE error:&error];
	if (!response) return nil;
	//NSLog(@"JSON Response:\n%@", response);
	NSArray *songs = [response objectForKey:@"items"];
	for (NSDictionary* song in songs)
	{
		if ([song objectForKey:@"adToken"]) continue;
		[playList addObject:[[PandoraSong alloc] initWithDictionary:song station: self]];
	}
	return playList;
}

- (PandoraSong *) getCurrentSong {
	//if (currentSong) return currentSong;
	if (currentIndex != -1) return [playList objectAtIndex:currentIndex];
	else return [self getNextSong];
}

- (PandoraSong *) getNextSong {
	/*if ([playList count] > 0) {
		if (currentSong) {
			[justPlayed addObject:currentSong];
		}
	}
	else {
		[self getPlaylist];
	}
	currentSong = [playList objectAtIndex:0];
	[playList removeObjectAtIndex:0];
	return currentSong;*/
	if ([playList count] <= ++currentIndex) {
		[self getPlaylist];
	}
	return [playList objectAtIndex:currentIndex];
}

- (PandoraSong *) getSongAtIndex:(NSInteger)index {
	/*if (index < [justPlayed count]) {
		return [justPlayed objectAtIndex:index];
	}
	else if (index == [justPlayed count]) {
		return currentSong;
	}
	else if ([playList count] > 0) {
		index -= [justPlayed count] + 1;
		return [playList objectAtIndex:index];
	}
	return nil;*/
	return [playList objectAtIndex:index];
}

- (NSInteger)count {
	return [playList count];
}

- (NSInteger)getCurrentIndex {
	return currentIndex;
}

- (PandoraSong *)setCurrentIndex:(NSInteger)index {
	if (index < 0) index = 0;
	else if (index >= [playList count]) index = [playList count] - 1;
	currentIndex = index;
	return [playList objectAtIndex:currentIndex];
}

@end
