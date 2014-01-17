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
#import "PandoraSeed.h"

@implementation PandoraStation

- (id)initWithDictionary:(NSDictionary*)info connection:(PandoraConnection*)newConnection
{
	if(!(self = [super init])) return self;
	[self setValuesForKeysWithDictionary:info];
	connection = [newConnection retain];
	playList = [[NSMutableArray alloc] init];
    [self requestExtendedInfo];
	currentIndex = -1;
	return self;
}

- (void)dealloc {
	[connection release];
	[playList release];
	[self.stationName release];
	[self.stationId release];
	[self.dateCreated release];
	[self.stationToken release];
	[self.genre release];
	[self.quickMixStationIds release];
	//[self.music release];
	[self.stationDetailUrl release];
	[self.stationSharingUrl release];
    [self.seedSongs release];
    [self.seedArtists release];
	[super dealloc];
}

- (NSString*)description {
	return [NSString stringWithFormat:@"Pandora Station: %@", self.stationName];
}

- (void)requestExtendedInfo {
    //DDLogInfo(@"Getting extended info for station: %@", self.stationName);
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									   self.stationToken, @"stationToken",
									   [NSNumber numberWithBool:TRUE], @"includeExtendedAttributes",
									   nil];
	NSError *error = nil;
	NSDictionary *response = [connection jsonRequest:@"station.getStation"
									  withParameters:parameters
											  useTLS:NO
										 isEncrypted:TRUE
											   error:&error];
    if (error) {
        DDLogError(@"%@", error);
        return;
    }
    //DDLogVerbose(@"%@",response);
	
    NSDictionary *music = [response objectForKey:@"music"];
	self.seedArtists = [[NSMutableArray alloc] init];
	for (NSDictionary *artist in [music objectForKey:@"artists"]) {
		PandoraSeed *seed = [[[PandoraSeed alloc] initWithDictionary:artist
														 connection:connection]
							 autorelease];
		[self.seedArtists addObject:seed];
	}
	self.seedSongs = [[NSMutableArray alloc] init];
	for (NSDictionary *song in [music objectForKey:@"songs"]) {
		PandoraSeed *seed = [[[PandoraSeed alloc] initWithDictionary:song
														  connection:connection]
							 autorelease];
		[self.seedArtists addObject:seed];
	}
}

- (NSArray*)getPlaylist
{
	if(!self.stationToken) return nil;
	DDLogInfo(@"Getting New Playlist");
	
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
	NSDictionary *response = [connection jsonRequest:@"station.getPlaylist"
									  withParameters:parameters
											  useTLS:TRUE
										 isEncrypted:TRUE
											   error:&error];
	if (!response) return nil;
	//DDLogVerbose(@"JSON Response:\n%@", response);
	NSArray *songs = [response objectForKey:@"items"];
	for (NSDictionary* song in songs)
	{
		if ([song objectForKey:@"adToken"]) continue;
		PandoraSong *newSong = [[PandoraSong alloc] initWithDictionary:song
															connection:connection station: self];
		[newSong autorelease];
		[playList addObject:newSong];
	}
	return playList;
}

- (PandoraSong *) getCurrentSong {
	if (currentIndex != -1) return [playList objectAtIndex:currentIndex];
	else return [self getNextSong];
}

- (PandoraSong *) getNextSong {
	if ([playList count] <= ++currentIndex) {
		if(![self getPlaylist]) {
			return nil;
		};
	}
	return [playList objectAtIndex:currentIndex];
}

- (PandoraSong *) getSongAtIndex:(NSInteger)index {
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
	PandoraSong *song = [playList objectAtIndex:index];
	if (!song.enabled) {
		return nil;
	}
	currentIndex = index;
	return song;
}

- (NSInteger)indexOfSong:(PandoraSong *)song {
	return [playList indexOfObject:song];
}

- (NSIndexSet*)isDirty {
	NSMutableIndexSet *set = nil;
	for (int i = 0; i < [playList count]; i++) {
		PandoraSong *song = [playList objectAtIndex:i];
		if (!song.enabled) {
			if (!set) set = [NSMutableIndexSet indexSet];
			[set addIndex:i];
		}
	}
	return set;
}

- (void)cleanPlayList {
	int i = 0;
	for (i = 0; i < [playList count]; i++) {
		PandoraSong *song = [playList objectAtIndex:i];
		if (!song.enabled) {
			if (i < currentIndex) {
				currentIndex--;
			}
			[playList removeObjectAtIndex:i--];
		}
	}
}

- (void)removeSong:(PandoraSong*)song {
	NSInteger index = [self indexOfSong:song];
	if (index <= currentIndex) {
		currentIndex--;
	}
	[playList removeObject:song];
}

@end
