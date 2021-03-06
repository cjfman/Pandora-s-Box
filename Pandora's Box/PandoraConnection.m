//
//  PandoraConnection.m
//  Pandora's Box
//
//  Created by Charles Franklin on 1/3/13.
//  Copyright (c) 2013 Charles Franklin. All rights reserved.
//

#import "PandoraConnection.h"
#import "JSONKit.h"
#import "cjfmanExtentionToNSString.h"
#import "blowfish_koc.h"
#import "PandoraStation.h"

#import <time.h>

#define pandoraVersion 5


// Common
#define kentryPoint @"entryPoint"
#define kPartnerId @"partnerId"
#define kUserId @"userId"
#define kPartnerAuthToken @"partnerAuthToken"
#define kUserAuthToken @"userAuthToken"
#define kSyncTime @"syncTime"
#define kStat @"stat"
#define kEncrypt @"encrypt"
#define kDecrypt @"decrypt"
#define kUsername @"username"
#define kPassword @"password"
#define kChecksum @"checksum"

// partner.login
#define kDeviceModel @"deviceModel"
#define kVersion @"version"


@implementation PandoraConnection

- (id)init {
	if (!(self = [super init])) return self;
	
	// Load Error Codes
	NSString *errorCodesPath = [[NSBundle mainBundle] pathForResource:@"PandoraExceptions" ofType:@"plist"];
	errorCodes = [[NSDictionary dictionaryWithContentsOfFile:errorCodesPath] retain];
	
	// Initialize Other Members
	stationList = [[NSMutableArray alloc] init];
	stations = [[NSMutableDictionary alloc] init];
	
	return self;
}

- (id)initWithPartner:(NSString*)partnerName
{
	if (!(self = [self init])) return self;
	[self setPartner:partnerName];
	return self;
}

- (NSString*)description {
	if (userAuthToken) {
		return [NSString stringWithFormat:
				@"Pandora connection with user: %@", username];
	}
	else
		return @"Pandora connection";
}

- (void)dealloc {
	[partner release];
	[stationList release];
	[stations release];
	[auth_token release];
	[partner_id release];
	[user_id release];
	[userAuthToken release];
	[partnerAuthToken release];
	[errorCodes release];
	[super dealloc];
}

- (void)asynchronousMethod:(SEL)selector
				withObject:(id)parameters
		   completionBlock:(void(^)(id))callback {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		id result = [self performSelector:selector withObject:parameters];

		dispatch_async(dispatch_get_main_queue(), ^{
			callback(result);
		});
	});
}

- (void)setPartner:(NSString *)partnerName {
	// Get Partner Info
	NSString *partnerPath = [[NSBundle mainBundle] pathForResource:@"PartnerInfo" ofType:@"plist"];
	partner = [[[NSDictionary dictionaryWithContentsOfFile:partnerPath] objectForKey:partnerName] copy];
	NSString *encryptKey = [partner objectForKey:kEncrypt];
	NSString *decryptKey = [partner objectForKey:kDecrypt];
	Blowfish_Init(&blowfishCTXEncrypt, (unsigned char*)[encryptKey UTF8String], (int)[encryptKey length]);
	Blowfish_Init(&blowfishCTXDecrypt, (unsigned char*)[decryptKey UTF8String], (int)[decryptKey length]);
}

- (BOOL)partnerLogin:(NSError**)error {
	DDLogInfo(@"Partner Login");
	
	// Prepare JSON Request
	syncTime = 0;
	NSMutableDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
								[partner objectForKey:kUsername], kUsername,
								[partner objectForKey:kPassword], kPassword,
								[partner objectForKey:kDeviceModel], kDeviceModel,
								[NSString stringWithFormat:@"%d", pandoraVersion], kVersion,
								nil];
	//NSError *error = nil;
	NSDictionary *response = [self jsonRequest:@"auth.partnerLogin" withParameters:parameters useTLS:TRUE isEncrypted:FALSE error:error];
	if(response == nil)
	{
		//DDLogError(@"Partner Login Error:\n%@", [*error localizedDescription]);
		return FALSE;
	}
	//DDLogVerbose(@"JSON Response:\n%@", response);
	syncTime = [[self decryptBlowfishMessage:[response objectForKey:kSyncTime]] integerValue];
	startTime = time(NULL);
	partnerAuthToken = [[response objectForKey:kPartnerAuthToken] copy];
	partner_id = [[response objectForKey:kPartnerId] copy];
	return TRUE;
}

- (NSArray*)loginWithUsername:(NSString*) aUsername
				  andPassword:(NSString*) aPassword
						error: (NSError**)error
{
	username = [aUsername copy];
	password = [aPassword copy];
	DDLogInfo(@"Logging in user: %@", username);
	if (!partnerAuthToken) return nil;
	NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObjectsAndKeys:
								@"user", @"loginType",
								username, kUsername,
								password, kPassword,
								partnerAuthToken, kPartnerAuthToken,
								//boolean, @"includePandoraOneInfo,
								//boolean, @"includeSubscriptionExpiration",
								//boolean, @"includeAdAttributes",
								[NSNumber numberWithBool:FALSE], @"returnStationList",
								//boolean, @"includeStationArtUrl",
								//boolean, @"returnGenreStations",
								//boolean, @"includeDemographics",
								//boolean, @"returnCapped",
								nil];
	NSDictionary *response = [self jsonRequest:@"auth.userLogin"
								withParameters:parameters
										useTLS:TRUE
								   isEncrypted:TRUE
										 error:error];
	//DDLogVerbose(@"JSON Response:\n%@", response);
	if (*error) return nil;
	user_id = [[response objectForKey:kUserId] copy];
	userAuthToken =[[response objectForKey:kUserAuthToken] copy];
	maxStations = [[response objectForKey:@"maxStationsAllowed"] intValue];
	return nil; //[self getStationList];
}

- (BOOL)relogin {
	DDLogError(@"Relogging in");
	if (username && password && partner) {
		// Clear credentials
		syncTime = 0;				// Sync Time
		[auth_token release];		// Auth Token
		auth_token = nil;
		[partner_id release];		// Partner ID
		partner_id = nil;
		[user_id release];			// User ID
		user_id = nil;
		[userAuthToken release];	// User Auth Token
		userAuthToken = nil;
		[partnerAuthToken release]; // Parther Auth Token
		partnerAuthToken = nil;
		
		// Initiate relogin
		NSError *error = nil;
		if ([self partnerLogin:&error]) {
			[self loginWithUsername:username andPassword:password error:&error];
			if(!error) {
				return TRUE;
			}
		}
	}
	return FALSE;
}

- (NSArray*)getStationList
{
	if (!partnerAuthToken) return nil;
	if([stationList count]) return stationList;
	DDLogInfo(@"Retrieving Station List");
	NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
	NSError *error = nil;
	
	// Get Stations
	NSDictionary *response = [self jsonRequest:@"user.getStationList"
								withParameters:parameters
										useTLS:FALSE
								   isEncrypted:TRUE
										 error:&error];
	if(!response) return nil;
	NSString *precheck = [response objectForKey:kChecksum];
	
	// Get Checksum
	NSDictionary *checkResponse = [self jsonRequest:@"user.getStationListChecksum"
									 withParameters:parameters
											 useTLS:FALSE
										isEncrypted:TRUE
											  error:&error];
	if(!response) return nil;
	NSString *postcheck = [checkResponse objectForKey:kChecksum];
	if (![precheck isEqualToString:postcheck]) return [self getStationList];
	
	// Create Station Objects
	for (NSDictionary *station in [response objectForKey:@"stations"])
	{
		NSString *name = [station objectForKey:@"stationName"];
		if (!name) continue;
		[stationList addObject:name];
		PandoraStation *newStation = [[PandoraStation alloc] initWithDictionary: station
																	 connection:self];
		[newStation autorelease];
		[stations setObject:newStation
					 forKey:name];
	}	
	return [[stationList retain] autorelease];
}

- (PandoraStation*)getStation:(NSString*)name
{
	if (!stations) return nil;
	PandoraStation *station = [stations objectForKey:name];
	if (!station) return nil;
	return [[station retain] autorelease];
}

- (PandoraStation*)createStation:(PandoraSearchResult *)music {
	NSMutableDictionary *parameters =
	[NSMutableDictionary dictionaryWithObject:[music musicToken]
									   forKey:@"musicToken"];
	NSError *error = nil;
	NSDictionary *result = [self jsonRequest:@"station.createStation"
	   withParameters:parameters
			   useTLS:NO isEncrypted:YES
				error:&error];
	
	if (!result) {
		DDLogError(@"%@", error);
		return nil;
	}
	PandoraStation *station = [[[PandoraStation alloc] initWithDictionary:result
											connection:self]
			autorelease];
	if (station) {
		[stationList addObject:[station stationName]];
		[stations setObject:station forKey:[station stationName]];
	}
	return station;
}

- (BOOL)deleteStation:(PandoraStation *)station {
	if (!station.allowDelete) {
		self.lastError = [NSError errorWithDomain:@"Pandora"
											 code:0
										 userInfo:nil];
		return FALSE;
	}
	NSMutableDictionary *parameters =
	[NSMutableDictionary dictionaryWithObject:[station stationToken]
									   forKey:@"stationToken"];
	NSError *error = nil;
	[self jsonRequest:@"station.deleteStation"
	   withParameters:parameters
			   useTLS:NO
		  isEncrypted:YES
				error:&error];
	if (error)
		return FALSE;
	
	NSString *name = [station stationName];
	[stations removeObjectForKey:name];
	[stationList removeObjectIdenticalTo:name];
	return TRUE;
}

- (NSDictionary*)musicSearch:(NSString *)searchText {
	NSMutableDictionary *parameters =
	[NSMutableDictionary dictionaryWithObjectsAndKeys:
	 searchText, @"searchText",
	 nil];
	NSError *error = nil;
	NSDictionary *response = [self jsonRequest:@"music.search"
								withParameters:parameters
										useTLS:NO
								   isEncrypted:YES
										 error:&error];
	return response;
}

/*******************************************
 JSON Methods
 ******************************************/

- (NSDictionary*)jsonRequest:(NSString*)method
			  withParameters:(NSMutableDictionary*)parameters
					  useTLS:(BOOL)useTLS
				 isEncrypted:(BOOL)isEncrypted
					   error:(NSError**)error {
#ifdef PANDORA_PARSE_DEBUG
	
	NSString *debugResponsesPath = [[NSBundle mainBundle] pathForResource:@"PandoraDebugResponses" ofType:@"plist"];
	NSString *jsonString = [[NSDictionary dictionaryWithContentsOfFile:debugResponsesPath] objectForKey:method];
	return [[jsonString objectFromJSONString] objectForKey:@"result"];
	
#else
    DDLogVerbose(@"Making JSON request: %@\n with parameters:\n%@", method, parameters);
	// Build JSON string
	// Add Common Parameters
	if (syncTime)
	{
		long calculation = syncTime + (time(NULL) - startTime);
		NSNumber *calculatedSyncTime = [NSNumber numberWithLong: calculation];
		[parameters setObject:calculatedSyncTime forKey:kSyncTime];
	}
	if (userAuthToken)
	{
		[parameters setObject:userAuthToken forKey:kUserAuthToken];
	}
	NSMutableString *jsonString = [NSMutableString stringWithString:[parameters JSONString]];
	if (isEncrypted)
	{
		[jsonString setString:[self encryptBlowfishMessage:jsonString]];
	}
	
	// Build URL
	NSMutableString *urlString = [NSMutableString stringWithString:@"http"];
	if (useTLS)
	{
		[urlString appendString:@"s"];
	}
	[urlString appendFormat:@"://%@", [partner objectForKey:kentryPoint]];
	[urlString appendFormat:@"/services/json/?method=%@", method];
	if (partner_id)
	{
		[urlString appendFormat:@"&partner_id=%@", partner_id];
	}
	if (user_id)
	{
		[urlString appendFormat:@"&user_id=%@", user_id];
	}
	if (userAuthToken)
	{
		[urlString appendFormat:@"&auth_token=%@", [PandoraConnection encodeURL:userAuthToken]];
	}
	else if (partnerAuthToken)
	{
		[urlString appendFormat:@"&auth_token=%@", [PandoraConnection encodeURL:partnerAuthToken]];
	}
	
	// Build HTTP Request
	NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
	[request setHTTPMethod:@"POST"];
	[request setValue:@"text/plain" forHTTPHeaderField:@"Content-type"];
	[request setValue:[NSString stringWithFormat:@"%ld", [jsonString length]] forHTTPHeaderField:@"Content-legth"];
	[request setHTTPBody:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
	[request setTimeoutInterval:15];
	
	// Make Synchronous Request
	NSData *jsonData;
	NSURLResponse *urlResponse;
	@synchronized(self) {
		jsonData = [NSURLConnection sendSynchronousRequest:request
										returningResponse:&urlResponse
													error:error];
	}
	if (jsonData == nil) {
		self.lastError = *error;
		return nil;
	}
	//NSString *jsonResult = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    /*
    if ([method isEqualTo:@"station.deleteStation"])
        DDLogVerbose(@"%@", jsonResult);//*/
	
	NSDictionary *response = [jsonData objectFromJSONData];
    DDLogVerbose(@"JSON response:\n%@", response);
	if ([[response objectForKey:kStat] isEqualTo:@"fail"])
	{
		NSInteger code = [[response objectForKey:@"code"] integerValue];
		//NSString *codeString = [NSString stringWithFormat:@"%ld",code];

		// Try to handle error
		// Expired Credentials
		if (code == 1001) {
			if(![self relogin]) {
				[PandoraException raise:@"AuthTimeout"
								   format:@"Authentication has timed out"];
			}
			DDLogError(@"Successfully relogged in. Reattempting: %@", method);
			return [self jsonRequest:method
					  withParameters:parameters
							  useTLS:useTLS
						 isEncrypted:isEncrypted
							   error:error];
		}
		// Invalid Login Credentials
		else if (code == 1002) {
			*error = [NSError errorWithDomain:@"Pandora" code:1002 userInfo:response];
			self.lastError = *error;
			return nil;
		}
		DDLogError(@"Unrecoverable JSON Error:\n%@", response);
		// Pass error to calling method
		//NSString *errorName = [errorCodes objectForKey:codeString];
		*error = [NSError errorWithDomain:@"Pandora" code:code userInfo:response];
		self.lastError = *error;
		return nil;
	}
	
	self.lastError = nil;
	return [[jsonData objectFromJSONData] objectForKey:@"result"];
#endif
}

+ (NSString*)encodeURL: (NSString*) string
{
	CFStringRef urlString =
	CFURLCreateStringByAddingPercentEscapes(
											NULL,
											(CFStringRef)string,
											NULL,
											(CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
											kCFStringEncodingUTF8 );
    return [(NSString *)urlString autorelease];
}

/*******************************************
 Blowfish Methods
 ******************************************/

- (NSString*)encryptBlowfishMessage:(NSString*)message
{
	const char *charMessageTemp = [message UTF8String];
	long l = [message length];
	long padding = (8 - l%8)%8;
	long total = l + padding;
	unsigned char *charMessage = malloc(total*sizeof(unsigned char));
	memcpy(charMessage, charMessageTemp, l);
	for (int i = 0; i < padding; i++)
	{
		charMessage[l + i] = '\0';
	}
	for (int i = 0; i < l; i += 8)
	{
		unsigned char *workingMessage = &charMessage[i];
		[self switchEndian:workingMessage];
		Blowfish_Encrypt(&blowfishCTXEncrypt, (unsigned int *)&workingMessage[4], (unsigned int *)workingMessage);
		[self switchEndian:workingMessage];
	}
	
	return [NSString encodeHex:charMessage length:total];
}

- (NSString*)decryptBlowfishMessage:(NSString*)message
{
	unsigned char *charMessage = [message decodeHex];
	// Assume that message is exactly than 32 hex characters / 64 bits
	unsigned char charResult[17];
	memcpy(charResult, charMessage, 16);
	for(int i = 0; i < 16; i += 8)
	{
		unsigned char *workingMessage = &charResult[i];
		[self switchEndian:workingMessage];
		Blowfish_Decrypt(&blowfishCTXDecrypt, (unsigned int *)&workingMessage[4], (unsigned int *)workingMessage);
		[self switchEndian:workingMessage];
	}
	// Trim off end
	charResult[14] = '\0';
	NSString *result = [NSString stringWithUTF8String:(char*)(&charResult[4])]; // Trim off beginning and make String
	return result;
}

- (void)switchEndian:(unsigned char*)message;
{
	for (int i = 0; i < 4; i++)
	{
		unsigned char c = message[i];
		message[i] = message[7-i];
		message[7-i] = c;
	}
}

@end

@implementation PandoraException
@end
