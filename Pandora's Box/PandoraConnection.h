//
//  PandoraConnection.h
//  Pandora's Box
//
//  Created by Charles Franklin on 1/3/13.
//  Copyright (c) 2013 Charles Franklin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "blowfish_koc.h"
#import "PandoraStation.h"
#import "PandoraSearchResult.h"
#import "DDLog.h"

//#define PANDORA_PARSE_DEBUG
//#define SONG_DOWNLOAD_DEBUG

static const int ddLogLevel = LOG_LEVEL_VERBOSE;


@interface PandoraConnection : NSObject
{
	NSDictionary *partner;
	NSMutableArray *stationList;
	NSMutableDictionary *stations;
	NSString *auth_token;
	NSString *partner_id;
	NSString *user_id;
	NSString *userAuthToken;
	NSString *partnerAuthToken;
	NSInteger syncTime;
	NSInteger startTime;
	NSInteger maxStations;
	NSDictionary *errorCodes;
	BLOWFISH_CTX blowfishCTXEncrypt;
	BLOWFISH_CTX blowfishCTXDecrypt;
	
	NSString *username;
	NSString *password;
}

@property (assign) NSError *lastError;

- (id)init;
- (id)initWithPartner:(NSString*)partnerName;
- (NSString*)description;
- (void)asynchronousMethod:(SEL)selector
				withObject:(id)parameters
		   completionBlock:(void(^)(id))callback;

// Pandora Methods
- (void)setPartner:(NSString*)partnerName;
- (BOOL)partnerLogin:(NSError**)error;
- (NSArray*)loginWithUsername:(NSString*) username
				  andPassword:(NSString*) password
						error:(NSError**)error;
- (BOOL)relogin;
- (NSMutableArray*)getStationList;
- (PandoraStation*)getStation:(NSString*)name;
- (PandoraStation*)createStation:(PandoraSearchResult*)music;
- (BOOL)deleteStation:(PandoraStation*)station;
- (NSDictionary*)musicSearch:(NSString*)searchText;

// JSON
- (NSDictionary*)jsonRequest:(NSString*)method
			  withParameters:(NSDictionary*)parameters
					  useTLS:(BOOL)useTLS
				 isEncrypted:(BOOL)isEncrypted error:(NSError**)error;
+ (NSString*)encodeURL:(NSString*)string;

// Blowfish
- (NSString*)encryptBlowfishMessage:(NSString*)message;
- (NSString*)decryptBlowfishMessage:(NSString*)message;
- (void)switchEndian:(unsigned char*)message;

@end


/********************************
 Exceptions
 *******************************/

@interface PandoraException : NSException
@end

@interface NSString (HexIntValue)
- (unsigned int)hexIntValue;
@end