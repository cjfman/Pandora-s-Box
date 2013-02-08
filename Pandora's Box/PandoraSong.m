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
	connection = [newConnection retain];
	station = [newStation retain];
	self.audioPlayer = nil;
	self.enabled = YES;
	return self;
}

- (void)dealloc {
	[connection release];
	[station release];
	[self.songName release];
	[self.artistName release];
	[self.albumName release];
	[self.trackToken release];
	[self.stationId release];
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
	if (!self.enabled) return;
	if (self.songData) return;
	NSLog(@"Loading song data for song: %@", self.songName);
	@synchronized(self.songData) {
#ifndef SONG_DOWNLOAD_DEBUG
		self.songData = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: self.audioUrl]];
#else
		//self.songData = [[[NSFileManager defaultManager] contentsAtPath:@"/Volumes/HDD Storage/My Files Backup/Music/iTunes/iTunes Music/The Heavy/The House That Dirt Built/01 The House That Dirt Built.m4a"] retain];
		self.songData = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: @"http://t3-2.p-cdn.com/access/3458497696169817008.mp3?version=4&lid=70147280&token=eZd2CDOwKDQAykg%2FQXUV9D7Y%2BEgxlNzgOyfFKrLmgj%2FLw0dcboROS%2FMUNEty9T5nTwBvzFos149gqsjEFzluR%2FKUwviGrtt23Hp5PoI%2BksGZVg2eFAZNQXfIzaJpdfeMf5J5x6tmNYjHGd1JjMBe07UHLimXNovisv3rcwsN0CJIRvzmahLDQwIfV1utqo4V3okS8bIq%2BXMQBqYEJ8HD1jT95B4oL6fIeDnTXwSE%2BmsN9%2BmZxnzXTuh4vGf54ne7%2F9wEvvUNBxHYeYdCXsaLi4qmlZ0PShsQ5Hu0cDYAkCl2082%2F0W989r%2BYYXPfltUXXbhmEUgpX2caU92J3OSo455snl1AfbdO"]];
		
#endif
		if (!self.songData) {
			NSLog(@"Failed to load song data for song: %@", self.songName);
			self.enabled = NO;
			[self.songData release];
		}
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
	self.songRating = (rating) ? 1 : -1;
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
	NSLog(@"%@ now rated %ld", self.songName, [[response objectForKey:@"isPositive"] integerValue]);
}

@end
