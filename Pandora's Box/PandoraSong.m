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
	cached = NO;
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

- (void)loadData {
	[self loadAlbumArt];
	[self loadSong];
}

- (void)loadAlbumArt {
	if (albumArt) return;
	@synchronized(albumArt) {
		NSData * imageData = [[NSData alloc] initWithContentsOfURL: [NSURL URLWithString: self.albumArtUrl]];
		albumArt = [[NSImage alloc] initWithData: imageData];
		[imageData release];
	}
}

- (void)loadSong {
	if (!self.enabled) return;
	if (self.songData) return;
	NSString *usedURL;
	@synchronized(self.songData) {
#ifndef SONG_DOWNLOAD_DEBUG
		if (cached) {
			self.songData = [[[NSFileManager defaultManager] contentsAtPath:songPath] retain];
		}
		else {
			NSLog(@"Downloading song data for song: %@", self.songName);
			self.songData = [[NSData alloc] initWithContentsOfURL:
							 [NSURL URLWithString: self.audioUrl]];
			usedURL = self.audioUrl;
		}
#else
		self.songData = [[[NSFileManager defaultManager] contentsAtPath:@"/Volumes/HDD Storage/Users/charles/Desktop/Pandora's Box/5855720188902449219.mp4"] retain];
		usedURL = [NSString stringWithFormat:@"http://test.com/DEBUG_%@.m4a?parameters", self.songName];
		
#endif
		if (!self.songData) {
			NSLog(@"Failed to load song data for song: %@", self.songName);
			self.enabled = NO;
			[self.songData release];
			return;
		}
	}
	NSMutableString *temp = [NSMutableString stringWithString:usedURL];
	NSRange range = [temp rangeOfString:@"?"];
	if (range.location != NSNotFound) {
		range.length = [temp length] - range.location;
		[temp deleteCharactersInRange:range];
	}
	range = [temp rangeOfString:@"." options:NSBackwardsSearch];
	if (range.location != NSNotFound) {
		range.length = range.location + 1;
		range.location = 0;
		[temp deleteCharactersInRange:range];
	}
	audioContainer = [NSString stringWithString:temp];
}

- (void)saveSong:(NSString*)path {
	NSString *fileName = [NSString stringWithFormat:@"%@/%@_%@_%@.%@",
						  path,
						  self.songName,
						  self.artistName,
						  self.albumName,
						  audioContainer];
	songPath = [fileName stringByExpandingTildeInPath];
	NSError *error = nil;
	cached = [self.songData writeToFile:songPath options:0 error:&error];
	if (error) {
		NSLog(@"Error saveing song :%@\n%@",self.songName, error);
	}
}

- (void)clean {
	[self.songData release];
	[self.audioPlayer release];
	self.songData = nil;
	self.audioPlayer = nil;
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

- (void)setAudioPlayer:(AVAudioPlayer *)newPlayer {
	audioPlayer = newPlayer;
}

- (AVAudioPlayer*)audioPlayer {
	if (!audioPlayer) {
		[self loadSong];
		NSError *error = nil;
		audioPlayer = [[AVAudioPlayer alloc] initWithData:self.songData
													error:&error];
		if (error) {
			NSLog(@"%@", error);
			return nil;
		}
	}
	return audioPlayer;
}

- (void)setAlbumArt:(NSImage *)newArt {
	albumArt = newArt;
}

- (NSImage*)albumArt {
	if (!albumArt) {
		[self loadAlbumArt];
	}
	return albumArt;
}

@end
