//
//  PandoraSong.h
//  Pandora's Box
//
//  Created by Charles Franklin on 1/3/13.
//  Copyright (c) 2013 Charles Franklin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class PandoraConnection;
@class PandoraStation;

@interface PandoraSong : NSObject
{
	PandoraConnection *connection;
	PandoraStation *station;
	NSString *audioContainer;
	NSString *songPath;
}

// Song Info
@property (copy) NSString *songName;
@property (copy) NSString *artistName;
@property (copy) NSString *albumName;
@property (copy) NSString *trackToken;
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

@property (retain) NSImage *albumArt;
@property (retain) NSData *songData;
@property (retain) AVAudioPlayer *audioPlayer;
@property (assign) BOOL enabled;

- (id)initWithDictionary:(NSDictionary*)info
			  connection:(PandoraConnection*)newConnection
				 station:(PandoraStation*)newStation;
- (void)loadData;
- (void)loadAlbumArt;
- (void)loadSong;
- (void)saveSong:(NSString*)path;
- (void)rate:(BOOL)rating;

@end


