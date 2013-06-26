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
	loading = false;
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

- (NSString*)description {
	return [NSString stringWithFormat:@"Pandora Song: %@ by %@",
			self.songName, self.artistName];
}

- (void)loadData {
	//loading = true;
	[self loadAlbumArt];
	[self loadSong];
	[self loadLyrics];
	loading = false;
}

- (void)asynchronousLoadWithCallback:(void(^)(void))callback {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[self loadData];
		dispatch_async(dispatch_get_main_queue(), ^{
			callback();
		});
	});
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
			self.songData = [[[NSFileManager defaultManager]
							  contentsAtPath:songPath] retain];
			return;
		}
		else {
			NSLog(@"Downloading song data for song: %@", self.songName);
			self.songData = [[NSData alloc] initWithContentsOfURL:
							 [NSURL URLWithString: self.audioUrl]];
			usedURL = self.audioUrl;
		}
#else
		self.songData = [[[NSFileManager defaultManager] contentsAtPath:@"/Users/Charles/Music/iTunes/iTunes Music/Afrojack/Take Over Control (feat. Eva Simons) - Single/01 Take Over Control (Radio Edit) [feat. Eva Simons].m4a"] retain];
		usedURL = [NSString stringWithFormat:@"http://test.com/DEBUG_%@.m4a?parameters", self.songName];
		
#endif
		if (!self.songData) {
			NSLog(@"Failed to load song data for song: %@", self.songName);
			self.enabled = NO;
			[self.songData release];
			return;
		}
	}
	
	// Find file extension by cleaning URL
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

- (void)loadLyrics {
	[self loadLyrics:@"http://www.azlyrics.com/lyrics/"];
}

- (void)loadLyrics:(NSString*)host {
	if (self.lyrics) return;
	@try {
		NSString *artist;
		artist = [self.artistName stringByReplacingOccurrencesOfString:@"The "
															withString:@""
															   options:0
																 range:NSMakeRange(0, 4)];
		NSURL *url = [NSURL URLWithString:host];
		url = [url URLByAppendingPathComponent:
			   [[artist toAlphaNumeric] lowercaseString]];
		url = [url URLByAppendingPathComponent:
			   [[self.songName toAlphaNumeric] lowercaseString]];
		url = [url URLByAppendingPathExtension:@"html"];
		
		//NSLog(@"Loading Lyrics from site: %@", url);
		
		// Build HTTP Request
		NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
		[request setHTTPMethod:@"GET"];
		[request setValue:@"text/plain" forHTTPHeaderField:@"Content-type"];
		[request setTimeoutInterval:15];
		NSData *lyricData;
		NSError *error = nil;
		NSURLResponse *urlResponse;
		@synchronized(self) {
			lyricData = [NSURLConnection sendSynchronousRequest:request
											 returningResponse:&urlResponse
														 error:&error];
		}
		/*if (lyricData == nil) {
			self.lyrics = [@"Not Available" retain];
			return;
		}*/
		
		NSString *htmlString = [[NSString alloc] initWithData:lyricData encoding:NSUTF8StringEncoding];
		//NSLog(@"%@", htmlString);
		
		// Extract Lyrics from HTML
		NSRange startRange = [htmlString rangeOfString:@"<!-- start of lyrics -->"];
		NSRange endRange = [htmlString rangeOfString:@"<!-- end of lyrics -->"];
		if (startRange.location == NSNotFound) {
			//NSLog(@"Failed to find lyrics at %@", host);
			NSString *backupHost = @"http://www.plyrics.com/lyrics";
			if (![host isEqualToString:backupHost]) {
				[self loadLyrics:backupHost];
			}
			else {
				self.lyrics = [@"Not Available" retain];
			}
			return;
		}
		
		NSInteger startIndex = startRange.length + startRange.location + 2;
		NSInteger endIndex = endRange.location;
		NSRange lyricRange = NSMakeRange(startIndex, endIndex - startIndex);
		self.lyrics = [htmlString substringWithRange:lyricRange];
		self.lyrics = [self.lyrics stringByReplacingOccurrencesOfString:
					   @"<br>" withString:@""];
		self.lyrics = [self.lyrics stringByReplacingOccurrencesOfString:
					   @"<br />" withString:@""];
		self.lyrics = [self.lyrics stringByReplacingOccurrencesOfString:
					   @"<i>" withString:@""];
		self.lyrics = [self.lyrics stringByReplacingOccurrencesOfString:
					   @"</i>" withString:@""];
		self.lyrics = [self.lyrics stringByAppendingString:
					   @"\nLyrics provided by www.azlyrics.com"];
		[self.lyrics retain];
		//NSLog(@"Lyrics:\n%@", self.lyrics);
	}
	@catch (NSException *e) {
		self.lyrics = [@"Not Available" retain];
	}
}

- (void)saveSong:(NSString*)path {
	NSString *filename = [NSString stringWithFormat:@"%@_%@_%@.%@",
						  self.songName,
						  self.artistName,
						  self.albumName,
						  audioContainer];
	filename = [filename stringByReplacingOccurrencesOfString:@"/" withString:@":"];
	path = [path stringByAppendingPathComponent:filename];
	songPath = [[path stringByExpandingTildeInPath] retain];
	NSError *error = nil;
	cached = [self.songData writeToFile:songPath options:0 error:&error];
	if (error) {
		NSLog(@"Error saveing song: %@\n%@",self.songName, error);
	}
}

- (void)clean {
	[self.songData release];
	[self.audioPlayer release];
	self.songData = nil;
	self.audioPlayer = nil;
}

/*******************************************
 Getters and Setters
 *******************************************/

- (void)setAudioPlayer:(AVAudioPlayer *)newPlayer {
	audioPlayer = newPlayer;
}

- (AVAudioPlayer*)audioPlayer {
	if (!self.enabled) return nil;
	if (!audioPlayer) {
		[self loadSong];
		NSError *error = nil;
		audioPlayer = [[AVAudioPlayer alloc] initWithData:self.songData
													error:&error];
		if (error) {
			NSLog(@"Error playing song %@:\n>%@",
				  self.songName, [error localizedDescription]);
			self.enabled = FALSE;
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

- (BOOL)cached {
	return cached;
}

- (BOOL)loading {
	return loading;
}

/*******************************************
 Pandora Calls 
 *******************************************/

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

- (void)sleep {
	NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									   self.trackToken, @"trackToken",
									   nil];
	NSError *error = nil;
	NSDictionary *response = [connection jsonRequest:@"user.sleepSong"
									  withParameters:parameters
											  useTLS:NO
										 isEncrypted:YES
											   error:&error];
	if (error)
	{
		NSLog(@"%@\n%@", response, error);
		return;
	}
	NSLog(@"Sleeping song: %@", self.songName);
}

@end
