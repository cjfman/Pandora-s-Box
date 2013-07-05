//
//  PandoraSong.h
//  Pandora's Box
//
//  Created by Charles Franklin on 1/3/13.
//  Copyright (c) 2013 Charles Franklin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "cjfmanExtentionToNSString.h"

@class PandoraConnection;
@class PandoraStation;

@interface PandoraSong : NSObject
{
	PandoraConnection *connection;
	PandoraStation *station;
	NSString *audioContainer;
	NSString *songPath;
	AVAudioPlayer *audioPlayer;
	NSImage *albumArt;
	NSString *lyrics;
	BOOL cached;
	BOOL loading;
}

// Song Info
@property (copy) NSString *songName;
@property (copy) NSString *artistName;
@property (copy) NSString *albumName;
@property (copy) NSString *trackToken;
@property (copy) NSString *musicToken;
@property (copy) NSString *stationId;
@property (assign) NSInteger songRating;

// Song Data
@property (copy) NSString *audioUrl;
@property (copy) NSString *albumArtUrl;
@property (copy) NSDictionary *audioUrlMap;
@property (copy) NSArray *additionalAudioUrl;

// Song Properties
@property BOOL allowFeedback;

// Additional Info
@property (copy) NSString *songExplorerUrl;
@property (copy) NSString *artistExplorerUrl;
@property (copy) NSString *albumExplorerUrl;
@property (copy) NSString *songDetailUrl;
@property (copy) NSString *artistDetailUrl;
@property (copy) NSString *albumDetailUrl;

// External Links
@property (copy) NSString *amazonAlbumUrl;
@property (copy) NSString *itunesSongUrl;

// Included only for KVC compatibility;
@property (copy) NSString *amazonAlbumDigitalAsin;
@property (copy) NSString *amazonAlbumAsin;
@property (copy) NSString *nowPlayingStationAdUrl;
@property (copy) NSString *trackGain;
@property (copy) NSString *amazonSongDigitalAsin;
@property (copy) NSString *adToken;

@property (retain) NSData *songData;
@property (assign) BOOL enabled;

- (id)initWithDictionary:(NSDictionary*)info
			  connection:(PandoraConnection*)newConnection
				 station:(PandoraStation*)newStation;
- (NSString*)description;
- (void)loadData;
- (void)asynchronousLoadWithCallback:(void(^)(void))callback;
- (void)loadAlbumArt;
- (void)loadSong;
- (void)loadLyrics;
- (void)loadLyrics:(NSString*)host;
- (void)saveSong:(NSString*)path;
- (void)clean;

// Getters and Setters
- (void)setAudioPlayer:(AVAudioPlayer*)newPlayer;
- (AVAudioPlayer*)audioPlayer;
- (void)setAlbumArt:(NSImage*)newArt;
- (NSImage*)albumArt;
- (NSString*)lyrics;
- (BOOL)cached;
- (BOOL)loading;

// Pandora Calls
- (void)rate:(BOOL)rating;
- (void)sleep;

@end


