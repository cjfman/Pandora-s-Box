//
//  PandoraSeed.h
//  Pandora's Box
//
//  Created by Charles Franklin on 2/12/13.
//  Copyright (c) 2013 Charles Franklin. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PandoraConnection;

@interface PandoraSeed : NSObject {
	PandoraConnection *connection;
}

@property (retain) NSString *artistName;
@property (retain) NSString *songName;
@property (retain) NSString *seedId;
@property (retain) NSDictionary *dateCreated;

- (id)initWithDictionary:(NSDictionary*)info
			  connection:(PandoraConnection*)newConnection;

@end


@class PandoraSearchResult;

@interface PandoraSearchResult : NSObject {
	
}

- (id)initWithDictionary:(NSDictionary*)info;

@property (retain) NSString* musicToken;
@property (retain) NSString* artistName;
@property (retain) NSString* songName;
@property NSInteger score;
@property bool likelyMatch;

@end