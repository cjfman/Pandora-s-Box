//
//  PandoraSong.m
//  Pandora's Box
//
//  Created by Charles Franklin on 1/3/13.
//  Copyright (c) 2013 Charles Franklin. All rights reserved.
//

#import "PandoraSong.h"

//#define SONG_DOWNLOAD_DEBUG

@implementation PandoraSong

- (id)initWithDictionary:(NSDictionary*)info station:(PandoraStation*)newStation
{
	if(!(self = [super init])) return self;
	[self setValuesForKeysWithDictionary:info];
	station = newStation;
	self.audioPlayer = nil;
	return self;
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
		self.songData = nil; //[[[NSFileManager defaultManager] contentsAtPath:@"/Volumes/HDD Storage/My Files Backup/Music/iTunes/iTunes Music/The Heavy/The House That Dirt Built/01 The House That Dirt Built.m4a"] retain];
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

@end
