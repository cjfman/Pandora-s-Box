//
//  PandoraSearchResult.h
//  Pandora's Box
//
//  Created by Charles Franklin on 6/16/13.
//  Copyright (c) 2013 Charles Franklin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSONObject.h"


@class PandoraSearchResult;

@interface PandoraSearchResult : JSONObject {
	NSString* stringValue;
	bool isSong;
}

- (id)initWithDictionary:(NSDictionary*)info;
- (NSString*)description;
- (bool)isArtist;
- (bool)isSong;
- (NSString*)stringValue;
- (NSComparisonResult)compare:(PandoraSearchResult*)b;

@property (retain) NSString* musicToken;
@property (retain) NSString* artistName;
@property (retain) NSString* songName;
@property NSInteger score;
@property bool likelyMatch;

@end