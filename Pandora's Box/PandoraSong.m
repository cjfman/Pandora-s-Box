//
//  PandoraSong.m
//  Pandora's Box
//
//  Created by Charles Franklin on 1/3/13.
//  Copyright (c) 2013 Charles Franklin. All rights reserved.
//

#import "PandoraSong.h"
#import "PandoraConnection.h"
#import "PandoraStation.h"

//#define SONG_DOWNLOAD_DEBUG

@implementation PandoraSong

- (id)initWithDictionary:(NSDictionary*)info
			  connection:(PandoraConnection*)newConnection
				 station:(PandoraStation*)newStation {
	if(!(self = [super init])) return self;
	[self setValuesForKeysWithDictionary:info];
	connection = newConnection;
	station = newStation;
	self.audioPlayer = nil;
	return self;
}

- (void)dealloc {
	[self.songName release];
	[self.artistName release];
	[self.albumName release];
	[self.trackToken release];
	[self.stationId release];
	[self.songRating release];
	[self.audioUrl release];
	[self.albumArtUrl release];
	[self.audioUrlMap release];
	[self.additionalAudioUrl release];
	[self.songExplorerUrl release];
	[self.artistExplorerUrl release];
	[self.albumExplorerUrl release];
	[self.songDetailUrl release];
	[self.artistDetailUrl release];
	[self.albumDetailUrl release];
	[self.amazonAlbumUrl release];
	[self.itunesSongUrl release];
	[self.amazonAlbumDigitalAsin release];
	[self.amazonAlbumAsin release];
	[self.nowPlayingStationAdUrl release];
	[self.trackGain release];
	[self.amazonSongDigitalAsin release];
	[self.adToken release];
	[self.albumArt release];
	[self.songData release];
	[self.audioPlayer release];
	[super dealloc];
}

- (NSImage*)albumArt {
	if (!_albumArt) {
		[self loadAlbumArt];
	}
	return _albumArt;
}

- (void)loadData {
	[self loadAlbumArt];
	[self loadSong];
}

- (void)loadSong {
	if (self.songData) return;
	@synchronized(self.songData) {
#ifndef SONG_DOWNLOAD_DEBUG
		self.songData = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: self.audioUrl]];
#else
		self.songData = [[[NSFileManager defaultManager] contentsAtPath:@"/Volumes/HDD Storage/My Files Backup/Music/iTunes/iTunes Music/The Heavy/The House That Dirt Built/01 The House That Dirt Built.m4a"] retain];
#endif
	}
}

- (void)loadAlbumArt {
	if (_albumArt) return;
	@synchronized(_albumArt) {
		NSData * imageData = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: self.albumArtUrl]];
		_albumArt = [[NSImage alloc] initWithData: imageData];
		[imageData release];
	}
}

- (void)rate:(BOOL)rating {
	NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									   self.trackToken, @"trackToken",
									   [NSNumber numberWithBool:rating], @"isPositive",
									   nil];
	NSError *error = nil;
	NSDictionary *response = [connection jsonRequest:@"station.addFeedback"
									  withParameters:parameters
											  useTLS:NO
										 isEncrypted:YES
											   error:&error];
	if (error)
	{
		NSLog(@"%@", error);
		return;
	}
	//NSLog(@"%@", response);
}

@end
