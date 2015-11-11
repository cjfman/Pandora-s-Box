//
//  PandoraStation.h
//  Pandora's Box
//
//  Created by Charles Franklin on 1/3/13.
//  Copyright (c) 2013 Charles Franklin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PandoraSong.h"
#import "JSONObject.h"

@class PandoraConnection;

@interface PandoraStation : JSONObject
{
	PandoraConnection *connection;
	NSMutableArray *playList;
	NSInteger currentIndex;
}

// Station Info
@property (copy) NSString *stationName;
@property (copy) NSString *stationId;
@property (copy) NSDictionary *dateCreated;
@property (copy) NSString *stationToken;
@property (copy) NSArray *genre;
@property (copy) NSArray *quickMixStationIds;

// Additional Info
//@property (copy) NSDictionary *music;
@property (copy) NSString *stationDetailUrl;
@property (copy) NSString *stationSharingUrl;
//@property (copy) NSString *artUrl;
@property (retain) NSMutableArray *seedSongs;
@property (retain) NSMutableArray *seedArtists;

// Station Properties
@property BOOL allowAddMusic;
@property BOOL isShared;
@property BOOL allowDelete;
@property BOOL isQuickMix;
@property BOOL allowRename;

// Only have these so that KVC will work
@property BOOL suppressVideoAds;
@property BOOL requiresCleanAds;

- (id)initWithDictionary: info connection:(PandoraConnection*)newConnection;
- (NSString*)description;
- (void)requestExtendedInfo;
- (NSArray*)getPlaylist;

// Songs
- (PandoraSong *) getCurrentSong;
- (PandoraSong *) getNextSong;
- (PandoraSong *) getSongAtIndex:(NSInteger)index;
- (NSInteger)count;
- (NSInteger)getCurrentIndex;
- (PandoraSong *)setCurrentIndex:(NSInteger)index;
- (NSInteger)indexOfSong:(PandoraSong*)song;
- (NSIndexSet*)isDirty;
- (void)cleanPlayList;
- (void)removeSong:(PandoraSong*)song;

@end
