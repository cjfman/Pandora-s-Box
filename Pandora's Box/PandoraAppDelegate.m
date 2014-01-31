//
//  PandoraAppDelegate.m
//  Pandora's Box
//
//  Created by Charles Franklin on 1/3/13.
//  Copyright (c) 2013 Charles Franklin. All rights reserved.
//

#import "PandoraAppDelegate.h"
#import "PandoraConnection.h"
#import "PlaylistTableCellView.h"
#import "SSKeychain.h"
#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"
#import "DDFileLogger.h"
#import "DDLog.h"

#define kOpenTab @"openTab"
#define kUsername @"username"
#define kEncryptedPassword @"encryptedPassword"
#define kRememberLogin @"rememberLogin"
#define kOpenStation @"openStation"
#define kVolume @"volume"
#define kStationsVisible @"stationsVisible"


@implementation PandoraAppDelegate

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
	applicationName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];

	// Setup Support Files
	fileManager = [[NSFileManager defaultManager] retain];
	supportPath = [[[NSString stringWithFormat:
					@"~/Library/Application Support/%@", applicationName]
				   stringByExpandingTildeInPath] retain];
	[fileManager createDirectoryAtPath:supportPath
							  withIntermediateDirectories:NO
											   attributes:nil
													error:nil];
	audioCachePath = [[NSString alloc] initWithFormat:@"%@/%@", supportPath, audioCacheFolder];
	[fileManager createDirectoryAtPath:audioCachePath
		   withIntermediateDirectories:NO
							attributes:nil
								 error:nil];
    logsPath = [[NSString alloc] initWithFormat:@"%@/%@", supportPath, logsFolder];
    [fileManager createDirectoryAtPath:logsPath
           withIntermediateDirectories:NO
                            attributes:nil
                                 error:nil];
	
	// Load Images
	thumbsDownImage = [[NSImage imageNamed:@"ThumbsDownTemplate.pdf"] retain];
	thumbsUpImage = [[NSImage imageNamed:@"ThumbsUpTemplate.pdf"] retain];
	speakerLoud = [[NSImage imageNamed:@"SpeakerLoudTemplate.pdf"] retain];
	speakerMid = [[NSImage imageNamed:@"SpeakerMidTemplate.pdf"] retain];
	speakerQuiet = [[NSImage imageNamed:@"SpeakerQuietTemplate.pdf"] retain];
	speakerMute = [[NSImage imageNamed:@"SpeakerMuteTemplate.pdf"] retain];
	playSymbol = [[NSImage imageNamed:@"audioControlPlayTemplate.pdf"] retain];
	pauseSymbol = [[NSImage imageNamed:@"audioControlPauseTemplate.pdf"] retain];
	openDrawer = [[NSImage imageNamed:@"OpenDrawerTemplate.pdf"] retain];
	closeDrawer = [[NSImage imageNamed:@"CloseDrawerTemplate.pdf"] retain];
	
#ifdef DEBUG
	[self.debugMenuItem setEnabled:YES];
	[self.debugMenuItem setHidden:NO];
#endif
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Setup console and terminal logging
    [DDLog addLogger:[DDASLLogger sharedInstance] withLogLevel:LOG_LEVEL_ERROR];
    [DDLog addLogger:[DDTTYLogger sharedInstance] withLogLevel:LOG_LEVEL_INFO];
    
    // Setup verbose file logging
    DDLogFileManagerDefault *docsFileManager = [[DDLogFileManagerDefault alloc]
                                            initWithLogsDirectory:
                                                [logsPath stringByAppendingString:@"/Verbose"]];
    DDFileLogger *fileLogger = [[DDFileLogger alloc] initWithLogFileManager:docsFileManager];
    fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
    fileLogger.logFileManager.maximumNumberOfLogFiles = 2;
    [DDLog addLogger:fileLogger withLogLevel:LOG_LEVEL_VERBOSE];
    
    // Setup info file logging
    docsFileManager = [[DDLogFileManagerDefault alloc]
                       initWithLogsDirectory:
                       [logsPath stringByAppendingString:@"/Info"]];
    fileLogger = [[DDFileLogger alloc] initWithLogFileManager:docsFileManager];
    fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
    fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
    [DDLog addLogger:fileLogger withLogLevel:LOG_LEVEL_INFO];
    
    // Setup error file logging
    docsFileManager = [[DDLogFileManagerDefault alloc]
                       initWithLogsDirectory:
                       [logsPath stringByAppendingString:@"/Error"]];
    fileLogger = [[DDFileLogger alloc] initWithLogFileManager:docsFileManager];
    fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
    fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
    [DDLog addLogger:fileLogger withLogLevel:LOG_LEVEL_ERROR];
    
	// Setup Default Settings
	userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults registerDefaults:
	 [NSDictionary dictionaryWithObjectsAndKeys:
	  [NSNumber numberWithInt:2], kOpenTab,
	  @"", kUsername,
	  [NSNumber numberWithBool:false], kRememberLogin,
	  [NSNumber numberWithInt:1], kOpenStation,
	  [NSNumber numberWithFloat:.5], kVolume,
	  [SPMediaKeyTap defaultMediaKeyUserBundleIdentifiers],kMediaKeyUsingBundleIdentifiersDefaultsKey,
	  [NSNumber numberWithInt:250], kStationsVisible,
	  nil]];
	  
	// Media Key Support
	keyTap = [[SPMediaKeyTap alloc] initWithDelegate:self];
	if([SPMediaKeyTap usesGlobalMediaKeyTap])
		[keyTap startWatchingMediaKeys];
	else
		DDLogInfo(@"Media key monitoring disabled");
	
	// Setup GUI Elements
	// Constraints
	// Square Constraint for Album Art
	[self.windowView addConstraint:[NSLayoutConstraint constraintWithItem:self.mainTabView
	 attribute:NSLayoutAttributeHeight
	 relatedBy:NSLayoutRelationEqual
	 toItem:self.mainTabView
	 attribute:NSLayoutAttributeWidth
	 multiplier:1.0
	 constant:1]];
	[self.albumTabAlbumView setImageScaling:NSScaleToFit];
	// Station List Width Constraint
	NSInteger stationsWidth = [[userDefaults objectForKey:kStationsVisible] integerValue];
	stationsViewConstraints =
	[[NSLayoutConstraint constraintsWithVisualFormat:
	  [NSString stringWithFormat:@"H:[view(%ld)]", stationsWidth]
											options:NSLayoutFormatDirectionLeadingToTrailing
											metrics:nil
											  views:@{@"view":self.stationsView}]
	 retain];
	[self.windowView addConstraints:stationsViewConstraints];
	// Set Toggle Stations Controls
	if (stationsWidth) {
		[self.toggleStationsMenuItem setTitle:@"Hide Stations"];
		[self.toggleStationsButton setImage:closeDrawer];
	}
	else {
		[self.toggleStationsMenuItem setTitle:@"Show Stations"];
		[self.toggleStationsButton setImage:openDrawer];
	}
	// Other GUI Setup
	[self.songTabSongTextView setStringValue:@"No Song Playing"];
	[self.mainTabView selectTabViewItemAtIndex:[userDefaults integerForKey:kOpenTab]];
	[self.tabSelectionView selectSegmentWithTag:[userDefaults integerForKey:kOpenTab]];
	[self.songTabIndicator setCanDrawConcurrently:YES];
	// Setup the playhead in the timebar
	playHeadTimer = [[NSTimer timerWithTimeInterval:.1
											 target:self
										   selector:@selector(updatePlayHead)
										   userInfo:nil
											repeats:YES]
					 retain];
	[[NSRunLoop currentRunLoop] addTimer:playHeadTimer forMode:NSDefaultRunLoopMode];
	[self.playlistView setDoubleAction:@selector(songSelected)];
	[self.stationsTableView setDoubleAction:@selector(stationSelected)];
	[self.volumeSlider setFloatValue:[userDefaults floatForKey:kVolume]];
	
	
	// Login
	if ([userDefaults boolForKey:kRememberLogin]) {
		// Login using saved credentials from keychain
		username = [userDefaults objectForKey:kUsername];
		password = [SSKeychain passwordForService:applicationName account:username];
		if (password) {
			[self login:nil];
			return;
		}
	}
	
	// Start Modal Login Sheet
	[self startLoginSheet];
}

- (void)startLoginSheet {
	[NSApp beginSheet: self.loginWindow
	   modalForWindow: self.window
		modalDelegate: nil //self
	   didEndSelector: nil //@selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo: nil];
	[self.loginWindow setPreventsApplicationTerminationWhenModal:NO];
	[self.usernameView setStringValue:@""];
	[self.passwordView setStringValue:@""];
	[self.rememberMeView setState:false];
	[self.loginIndicator setCanDrawConcurrently:YES];
    [self.loginIndicator stopAnimation:self];
}

- (IBAction)login:(id)sender {
	[self.loginIndicator startAnimation:self];
	
	// Start Pandora
	if (!pandora) {
		pandora = [[PandoraConnection alloc] initWithPartner:@"iOS"];
		NSError *error = nil;
		[pandora partnerLogin:&error];
		if (error) {
			[self errorHandler:error];
			return;
		}
	}
	
	// If sender, than get login credentials from sheet
	// otherwise use credentials preset by caller
	if (sender) {
		// Get Values from sheet
		username = [[self.usernameView stringValue] copy];
		password = [self.passwordView stringValue];
#ifndef PANDORA_PARSE_DEBUG
		bool remember = [self.rememberMeView state];
#endif
		
		NSError *error = nil;
		[pandora loginWithUsername:username andPassword:password error:&error];
		if (error) {
			[self.loginIndicator stopAnimation:self];
			[self errorHandler:error];
			return;
		}
		
		// Close Modal Sheet
		[NSApp endSheet:self.loginWindow];
		[self.loginWindow orderOut:self];
		
#ifndef PANDORA_PARSE_DEBUG
		// Save the username and password in the keychain
		 if (remember) {
			 // Delete any previous entry
			 for (NSString *oldUsername in [SSKeychain allAccounts]) {
				 [SSKeychain deletePasswordForService:applicationName
											  account:oldUsername];
			 }
			 // Save password to keychain
			 BOOL keySet = [SSKeychain setPassword:password
										forService:applicationName
										   account:username];
			 if (keySet) {
				 // Save user to settings
				 [userDefaults setBool:remember forKey:kRememberLogin];
				 [userDefaults setObject:username forKey:kUsername];
			 }
			 else {
				 DDLogError(@"Failed to save to keychain");
				 [userDefaults setBool:FALSE forKey:kRememberLogin];
			 }
		 }
#endif
	}
	else {
		// Login with preset credentials
		NSError *error = nil;
		[pandora loginWithUsername:username andPassword:password error:&error];
		if (error) {
			[self errorHandler:error];
			return;
		}
	}
		
	// Start Station
	stationList = [[pandora getStationList] retain];
	[self.stationsTableView reloadData];
	NSInteger stationIndex = [userDefaults integerForKey:kOpenStation];
	// Check bounds
	if (stationIndex >= [stationList count]) {
		stationIndex = 0;
	}
	PandoraStation *station = [pandora getStation:[stationList objectAtIndex:stationIndex]];
	[self changeStation: station];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return TRUE;
}

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item {
	BOOL ans = YES;
	if (item == self.logoutMenuItem) {
		// Should only be able to log out if logged in
		ans = (pandora) ? YES : NO;
	}
	else if (item == self.playPauseMenuItem || item == self.nextMenuItem
			 || item == self.tiredMenuItem) {
		// Should only work if a station is playing music
		ans = (currentStation) ? YES : NO;
	}
	else if (item == self.backMenuItem) {
		// Should only work if there is a song to go back to
		ans = (currentStation && [currentStation getCurrentIndex] != 0) ? YES : NO;
	}
	else if (item == self.toggleStationsMenuItem) {
		ans = (pandora) ? YES : NO;
	}
	else if (item == self.createStationMenuItem) {
		ans = (pandora) ? YES : NO;
	}
	else if (item == self.deleteStationMenuItem) {
		ans = (self.selectedStationIndex != -1) && self.selectedStation.allowDelete;
	}
	return ans;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Save layout at other settings
	[userDefaults setInteger:[self.tabSelectionView selectedSegment] forKey:kOpenTab];
	[userDefaults setInteger:[stationList indexOfObject:[currentStation stationName]]
					  forKey:kOpenStation];
	[userDefaults setFloat:[self.volumeSlider floatValue] forKey:kVolume];
	[userDefaults setInteger:self.stationsView.frame.size.width  forKey:kStationsVisible];
	
	// Clear Cache
	NSError *error = nil;
	NSArray *files = [fileManager contentsOfDirectoryAtPath:audioCachePath error:&error];
	if (error) {
		DDLogError(@"%@", error);
	}
	else {
		for (NSString *file in files) {
			[fileManager removeItemAtPath:[NSString stringWithFormat:@"%@/%@",
										   audioCachePath,
										   file]
									error:&error];
		}
		if (error) {
			DDLogError(@"%@", error);
		}
	}
}

/*****************************************
 Station Creation Sheet
 *****************************************/

- (void)startStationSheet {
	if (!stationController) {
		stationController = [[StationWindowController alloc] init];
		[stationController setTarget:self callbackSelector:@selector(stationCreated:)];
		[stationController setMainWindow:self.window];
		[stationController setPandoraConnection:pandora];
	}
	[stationController startSheet];
}

- (void)stationCreated:(PandoraStation *)station {
	[self.stationsTableView reloadData];
	DDLogInfo(@"Created Station: %@:", [station stationName]);
	[self changeStation:station];
}

- (IBAction)addDelStation:(id)sender {
	NSInteger selection = [sender selectedSegment];
	switch (selection) {
		case 0:
			[self startStationSheet];
			break;
		case 1:
			[self deleteStation:sender];
			break;
	}
}

/*****************************************
 Media Key Support
 *****************************************/

/*
 * Code Provided by https://github.com/nevyn/SPMediaKeyTap
 */
-(void)mediaKeyTap:(SPMediaKeyTap*)keyTap receivedMediaKeyEvent:(NSEvent*)event;
{
	NSAssert([event type] == NSSystemDefined
			 && [event subtype] == SPSystemDefinedEventMediaKeys,
			 @"Unexpected NSEvent in mediaKeyTap:receivedMediaKeyEvent:");
	// magic code
	int keyCode = (([event data1] & 0xFFFF0000) >> 16);
	int keyFlags = ([event data1] & 0x0000FFFF);
	BOOL keyIsPressed = (((keyFlags & 0xFF00) >> 8)) == 0xA;
	//int keyRepeat = (keyFlags & 0x1);
	
	if (keyIsPressed) {
		switch (keyCode) {
			case NX_KEYTYPE_PLAY:
				[self playPause:nil];
				break;
				
			case NX_KEYTYPE_FAST:
				[self playNextSong];
				break;
				
			case NX_KEYTYPE_REWIND:
				[self playPreviousSong:nil];
				break;
			default:
				break;
			// More cases defined in hidsystem/ev_keymap.h
		}
	}
}

/*****************************************
 Menu Bar Methods
 *****************************************/

- (IBAction)playPause:(id)sender {
	if (audioPlayer) {
		if (audioPlayer.playing) {
			[audioPlayer pause];
			[self.playbackControls setImage:playSymbol forSegment:1];
		}
		else {
			[audioPlayer play];
			[self.playbackControls setImage:pauseSymbol forSegment:1];
		}
	}
	else {
		[self playNextSong];
	}
	
	// Update UI
	NSInteger index = [self playingSongIndex];
	[self.playlistView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:index]
						 columnIndexes:[NSIndexSet indexSetWithIndex:1]];
}

- (IBAction)skipSong:(id)sender {
	[self clearPlayer];
	[self playNextSong];
}

- (IBAction)playPreviousSong:(id)sender {
	if ([audioPlayer currentTime] > 1) {
		[audioPlayer setCurrentTime:0];
		return;
	}
	[self clearPlayer];
	[self changeSong:[currentStation setCurrentIndex:
					  [currentStation getCurrentIndex] - 1]];
}

- (IBAction)logout:(id)sender {
	DDLogInfo(@"Logging out");
	// Deallocate memory
	if (audioPlayer) {
		[audioPlayer stop];
		[audioPlayer release];
		audioPlayer = nil;
	}
	[stationList release];
	[currentSong release];
	[currentStation release];
	[pandora release];
	stationList = nil;
	currentSong = nil;
	currentStation = nil;
	pandora = nil;
	
	// Remove password from keychain
	if ([userDefaults boolForKey:kRememberLogin]) {
		[userDefaults setBool:FALSE forKey:kRememberLogin];
		NSError *error = nil;
		[SSKeychain deletePasswordForService:applicationName account:username error:&error];
		if (error) {
			DDLogError(@"Failed to remove %@ from keychain\n%@", username, error);
		}
	}
	[username release];
	username = nil;
	[password release];
	password = nil;
	
	[self startLoginSheet];
}

- (IBAction)tired:(id)sender {
	PandoraSong *song = [self selectedSong];
	if (song) {
		[song sleep];
	}
	if (song == currentSong) {
		[self playNextSong];
	}
}

- (IBAction)relogin:(id)sender {
	[pandora relogin];
}

- (IBAction)getLyricsMenuItem:(id)sender {
	if (currentSong) {
		[currentSong loadLyrics];
	}
}

- (IBAction)toggleStationList:(id)sender {
	static Boolean running = false;
	if (running) {
		return;
	}
	running = true;
	[sender setEnabled:NO];
	NSRect frame = [self.stationsView frame];
	NSRect wframe = [self.window frame];
	NSInteger diff = frame.size.width;
	if (diff) {
		frame.size.width = 0;
		wframe.size.width -= diff;
		[self.toggleStationsMenuItem setTitle:@"Show Stations"];
		[self.toggleStationsButton setImage:openDrawer];
	}
	else {
		diff = 250;
		frame.size.width = diff;
		wframe.size.width += diff;
		[self.toggleStationsMenuItem setTitle:@"Hide Stations"];
		[self.toggleStationsButton setImage:closeDrawer];
	}
	
	// Clear old contraints
	if (stationsViewConstraints) {
		[self.windowView removeConstraints:stationsViewConstraints];
		[stationsViewConstraints release];
		stationsViewConstraints = nil;
	}
	
	// Start Animation
	[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext] setCompletionHandler:^{
		stationsViewConstraints =
		[[NSLayoutConstraint constraintsWithVisualFormat:
		  [NSString stringWithFormat:@"H:[view(%d)]", (int)frame.size.width]
												 options:NSLayoutFormatDirectionLeadingToTrailing
												 metrics:nil
												   views:@{@"view":self.stationsView}]
		 retain];
		[self.windowView addConstraints:stationsViewConstraints];
		[sender setEnabled:YES];
		running = false;
	}];
	[[self.stationsView animator] setFrame:frame];
	[[self.window animator] setFrame:wframe display:YES animate:YES];
	[NSAnimationContext endGrouping];
}

- (IBAction)newStation:(id)sender {
	if (!pandora) {
		return;
	}
	[self startStationSheet];
}

- (IBAction)deleteStation:(id)sender {
	if ([self selectedStationIndex] == -1 || !pandora) {
		// No station is selected
		return;
	}
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert setMessageText:[NSString stringWithFormat:
						   @"Are you sure you want to delete \n\"%@\" ?",
						   [[self selectedStation] stationName]]];
	[alert addButtonWithTitle:@"Cancel"];
	[alert addButtonWithTitle:@"Delete"];
	[alert beginSheetModalForWindow:self.window
					  modalDelegate:self
					 didEndSelector:@selector(deletePromptDidEnd:returnCode:contextInfo:)
						contextInfo:nil];
}

- (void)deletePromptDidEnd:(NSAlert *)a returnCode:(NSInteger)code contextInfo:(void *)ci {
	if (code == NSAlertFirstButtonReturn) {
		// Cancel was hit
		return;
	}
	else if (code == NSAlertSecondButtonReturn) {
		// Delete the station
		PandoraStation *station = [self selectedStation];
		if ([pandora deleteStation:station]) {
			DDLogInfo(@"Deleted station: %@", station.stationName);
			[self.stationsTableView reloadData];
			if (station == currentStation) {
				// Play first station
				[self changeStation:[pandora getStation:[stationList objectAtIndex:0]]];
			}
		}
		else {
			DDLogError(@"Faild to deleted station: %@\n%@", station.stationName, [pandora lastError]);
		}
	}
}

- (IBAction)debugAction:(id)sender {
	[self startStationSheet];
}

/*****************************************
 Tabel View Deligate Methods
 *****************************************/

- (NSInteger)numberOfRowsInTableView:(NSTableView *) view {
	if (view == self.stationsTableView) {
		return [stationList count];
	}
	else if (view == self.playlistView) {
		return [currentStation count];
	}
	return 0;
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
				  row:(NSInteger)row {
	NSString *thisColName = [tableColumn identifier];
	if (tableView == self.stationsTableView) {
		NSTableCellView *thisCell = [tableView makeViewWithIdentifier:thisColName owner:self];
		thisCell.textField.stringValue = [stationList objectAtIndex:row];
		return thisCell;
	}
	else if (tableView == self.playlistView) {
		PandoraSong *song = [currentStation getSongAtIndex:row];
		if(!song.enabled) {
			
		}
		if ([thisColName isEqualToString:@"Album Art"]) {
			NSTableCellView *thisCell = [tableView makeViewWithIdentifier:thisColName owner:self];
			[thisCell.imageView setImage:[song albumArt]];
			return thisCell;
		}
		else if ([thisColName isEqualToString:@"Info"]) {
			PlaylistTableCellView *thisCell = [tableView makeViewWithIdentifier:thisColName owner:self];
			
			// Info
			thisCell.textField.stringValue = [NSString stringWithFormat:@"Title: %@\nArtist: %@\nAlbum: %@",
											  [song songName],
											  [song artistName],
											  [song albumName]];
			
			// Now Playing
			if ([audioPlayer isPlaying]) {
				[thisCell.imageView setImage:speakerLoud];
			}
			else {
				[thisCell.imageView setImage:speakerMute];
			 }//*/
			if (row == [currentStation getCurrentIndex] && !song.loading) {
				[thisCell.imageView setHidden:NO];
			}
			else {
				[thisCell.imageView setHidden:YES];
			}
			
			// Rating
			if ([song songRating]) {
				if (song.songRating == 1) {
					[thisCell.ratingImage setImage:thumbsUpImage];
				}
				else if (song.songRating == -1) {
					[thisCell.ratingImage setImage:thumbsDownImage];
				}
				[thisCell.ratingImage setHidden:NO];
			}
			else {
				[thisCell.ratingImage setHidden:YES];
			}
			
			// ----THIS IS A TEST----
			//*
			[thisCell.indicator setCanDrawConcurrently:YES];
			if (!song.loading) {
				[thisCell.indicator stopAnimation:self];
			}
			else {
				[thisCell.indicator startAnimation:self];
			}
			
			return thisCell;
		}
	}
	return nil;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	NSTableView *tableView = [aNotification object];
	if (tableView == self.stationsTableView) {
		[tableView scrollRowToVisible:[tableView selectedRow]];
	}
	if (tableView == self.playlistView) {
		[tableView scrollRowToVisible:[tableView selectedRow]];
	}
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
	if (tableView == self.playlistView) {
		return YES;
	}
	else if (tableView == self.stationsTableView) {
		return YES;
	}
	return NO;
}

- (void)reloadTable:(NSTableView*)table row:(NSInteger)row {
	// Check bounds
	if (row >= [table numberOfRows]) return;
	// Specified Row
	NSIndexSet *rowSet = [NSIndexSet indexSetWithIndex:row];
	// All Columns
	NSIndexSet *colSet = [NSIndexSet indexSetWithIndexesInRange:
						  NSMakeRange(0, [table numberOfColumns])];
	[table reloadDataForRowIndexes:rowSet
					 columnIndexes:colSet];
}

- (void)reloadTable:(NSTableView*)table
			  start:(NSInteger)start
			 length:(NSInteger)length {
	// Check bounds
	if (start >= [table numberOfRows]) return;
	if (start + length > [table numberOfRows]) return;
	// Specified Rows
	NSIndexSet *rowSet = [NSIndexSet indexSetWithIndexesInRange:
						  NSMakeRange(start, length)];
	// All Columns
	NSIndexSet *colSet = [NSIndexSet indexSetWithIndexesInRange:
						  NSMakeRange(0, [table numberOfColumns])];
	[table reloadDataForRowIndexes:rowSet
					 columnIndexes:colSet];
}

/*****************************************
 Song Playing Methods
 *****************************************/

- (void)playNextSong {
	[self clearPlayer];
	[self changeSong:[currentStation getNextSong]];
}

- (void)changeStation:(PandoraStation *)newStation {
	DDLogInfo(@"Station changed: %@", newStation.stationName);
	currentStation = newStation;
	if (audioPlayer) {
		[audioPlayer pause];
	}
	
	// Change Window Title
	[self.window setTitle:[NSString stringWithFormat:@"%@",
						   [currentStation stationName]]];
	
	
	PandoraSong *song = [newStation getCurrentSong];
	[self.playlistView reloadData];
	[self changeSong: song];
}

- (void)changeSong:(PandoraSong *)newSong {
	if (!newSong) {
		[currentStation cleanPlayList];
		[self.playlistView reloadData];
		[self errorHandler:[pandora lastError]];
		return;
	}
	DDLogInfo(@"New Song: %@", newSong.songName);
	
	NSInteger lastSongIndex = [currentStation indexOfSong:currentSong];
	NSInteger songIndex = [currentStation indexOfSong:newSong];
	currentSong = newSong;
	
	static int count = 0;
	int call_id = ++count;
	
	// Get Song Data Asynchronously
	[newSong asynchronousLoadWithCallback:^{
		NSInteger index = [currentStation indexOfSong:newSong];
		if (call_id != count) {
			[self reloadTable:self.playlistView row:index];
			return;
		}
		count = 0;
		
		if (!newSong.enabled) {
			DDLogError(@"Song %@ is disabled", [newSong songName]);
			[self playNextSong];
			return;
		}
		
		// Play Song
		if (!(audioPlayer = currentSong.audioPlayer)) {
			[currentStation cleanPlayList];
			return;
		}
		[audioPlayer retain];
		[audioPlayer setDelegate:self];
		[audioPlayer setVolume:[self.volumeSlider floatValue]];
		[self playPause:nil];
		[currentSong saveSong:audioCachePath];
		
		// Setup GUI
		[self.lyricsView setString:[currentSong lyrics]];
		[self.lyricsView scrollToBeginningOfDocument:nil];
		[self.playHeadView setMaxValue:[audioPlayer duration]];
		[self.songTabIndicator stopAnimation:self];
		[self.songTabAlbumView setImage:currentSong.albumArt];
		[self.lyricsView setString:[currentSong lyrics]];
		[self.lyricsView scrollToBeginningOfDocument:nil];
	
		// Reload row
		[self reloadTable:self.playlistView row:index];
		[self.playlistView selectRowIndexes:
		 [NSIndexSet indexSetWithIndex:index]
					   byExtendingSelection:NO];
		
		// Clean play list
		NSIndexSet *dirtySet = [currentStation isDirty];
		if (dirtySet) {
			[currentStation cleanPlayList];
			[self.playlistView removeRowsAtIndexes:dirtySet
									 withAnimation:NSTableViewAnimationEffectFade];
		}
	}];

	// Setup gui elemets
	// Only reload nessessary table rows
	[self reloadTable:self.playlistView row:songIndex];
	[self reloadTable:self.playlistView row:lastSongIndex];
	[self.songTabAlbumView setImage:currentSong.albumArt];
	// Load New Rows
	if ([self.playlistView numberOfRows] < [currentStation count]) {
		NSInteger rcount = [self.playlistView numberOfRows];
		NSInteger add = [currentStation count] - rcount;
		[self.playlistView insertRowsAtIndexes:
		 [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(rcount, add)]
								 withAnimation:NSTableViewAnimationSlideDown];
	}
	[self.playlistView deselectAll:self];
	[self.albumTabAlbumView setImage:currentSong.albumArt];
	// Song Tab View
	[self.songTabAlbumView setImage:nil];
	[self.songTabSongTextView setStringValue:
	 [NSString stringWithFormat:@"Title: %@\nArtist: %@\nAlbum: %@",
	  [currentSong songName],
	  [currentSong artistName],
	  [currentSong albumName]]];
	[self.lyricsView setString:[currentSong lyrics]];
	[self.lyricsView scrollToBeginningOfDocument:nil];
	[self.songTabIndicator startAnimation:self];
}

- (void)songSelected {
	PandoraSong *song = [currentStation setCurrentIndex:
						 [self.playlistView selectedRow]];
	if (!song) return;
	if (song == currentSong) {
		if (audioPlayer) {
			if (![audioPlayer isPlaying]) {
				[audioPlayer play];
			}
			return;
		}
	}
	
	[self clearPlayer];
	[self changeSong:song];
}

- (void)stationSelected {
	PandoraStation *station = [pandora getStation:
							   [stationList objectAtIndex:
								[self.stationsTableView selectedRow]]];
	[self changeStation:station];
}

- (void)clearPlayer {
	if (audioPlayer) {
		[audioPlayer pause];
		audioPlayer.currentTime = 0;
		[audioPlayer release];
		audioPlayer = nil;
		[currentSong clean];
	}
}

- (NSString *)timeFormatted:(NSInteger)totalSeconds
{
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
	
	return [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
}

/*****************************************
 AVAudioPlayer Deligate Methods
 *****************************************/

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player
					   successfully:(BOOL)flag {
	if (player == audioPlayer) {
		[self clearPlayer];
		[self playNextSong];
	}
}

/*****************************************
 Toolbar Methods
 *****************************************/

- (IBAction)newTabSelected:(id)sender {
	[self.mainTabView selectTabViewItemAtIndex:[sender selectedSegment]];
}

- (IBAction)audioControlPushed:(id)sender {
	NSInteger selection = [sender selectedSegment];
	switch (selection) {
		case 0:
			[self playPreviousSong:sender];
			break;
		case 1:
			[self playPause:sender];
			break;
		case 2:
			[self skipSong:sender];
			break;
	}
}

- (IBAction)ratingPushed:(id)sender {
	NSInteger selection = [sender selectedSegment];
	PandoraSong *song = [self selectedSong];
	if (!song) return;
	NSInteger index = [self selectedSongIndex];
	if (index < 0) return;
	switch (selection) {
		case 0:
			[song rate:YES];
			break;
		case 1:
			[song rate:NO];
			if (song == currentSong)
				[self skipSong:sender];
			break;
	}
	[self.playlistView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:index]
								 columnIndexes:[NSIndexSet indexSetWithIndex:1]];
}

- (IBAction)changeVolume:(id)sender {
	if (audioPlayer)
		audioPlayer.volume = [self.volumeSlider floatValue];
}

- (IBAction)fullVolume:(id)sender {
	if (audioPlayer) {
		audioPlayer.volume = 1;
	}
	[self.volumeSlider setFloatValue:1];
}

- (IBAction)muteVolume:(id)sender {
	if (audioPlayer) {
		audioPlayer.volume = 0;
	}
	[self.volumeSlider setFloatValue:0];
}

- (IBAction)songScrubbing:(id)sender {
	[audioPlayer setCurrentTime:[self.playHeadView doubleValue]];
}

- (void)updatePlayHead {
	if (audioPlayer) {
		NSTimeInterval duration = [audioPlayer duration];
		NSTimeInterval currentTime = [audioPlayer currentTime];
		[self.playHeadView setDoubleValue:currentTime];
		[self.elapsedTimeView setStringValue:[self timeFormatted:currentTime]];
		[self.remainingTimeView setStringValue:[NSString stringWithFormat:@"-%@", [self timeFormatted:(NSInteger)duration - (NSInteger)currentTime]]];
	}
}

/*****************************************
 Helper Methods
 *****************************************/

- (NSInteger)playingSongIndex {
	return [currentStation getCurrentIndex];
}

- (NSInteger)selectedSongIndex {
	if ([self.tabSelectionView selectedSegment] == 2) {
		return [self.playlistView selectedRow];
	}
	return [currentStation getCurrentIndex];
}

- (PandoraSong *)selectedSong {
	return [currentStation getSongAtIndex:[self selectedSongIndex]];
}

- (NSInteger)selectedStationIndex {
	return [self.stationsTableView selectedRow];
}

- (PandoraStation *)selectedStation {
	return [pandora getStation:[stationList objectAtIndex:[self selectedStationIndex]]];
}

- (void)alertUser:(NSString *)message {
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert setMessageText:message];
	[alert runModal];
}

- (void)errorHandler:(NSError *)error {
	if ([[error domain] isEqualTo:NSURLErrorDomain]) {
		// Network is disconnected
		if ([error code] == -1009) {
			[self alertUser:@"Could not connect to Pandora.\nPlease check your network connection."];
			DDLogError(@"%@", [error localizedDescription]);
		}
		else {
			DDLogError(@"Login error:\n%@", error);
			[self alertUser:@"Unknown Network Error"];
		}
		[pandora release];
		pandora = nil;
	}
	else if([[error domain] isEqualTo:@"Pandora"]) {
		// Bad username/password
		if ([error code] == 1002)
		{
			DDLogError(@"Invalid User Credentials");
			[self alertUser:@"Invalid User Credentials"];
		}
		// Unknown Error
		else
		{
			DDLogError(@"Login error:\n%@", error);
			[self alertUser:@"Unknown Pandora Error"];
			[pandora release];
			pandora = nil;
		}
	}
	// Unknown Error
	else {
		DDLogError(@"Login error:\n%@", error);
		[self alertUser:@"An unknown error has occurred"];
		[pandora release];
		pandora = nil;
	}
	[pandora setLastError:nil];
	return;
}

@end