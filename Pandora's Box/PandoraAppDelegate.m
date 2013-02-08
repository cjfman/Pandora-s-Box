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

#define kOpenTab @"openTab"
#define kUsername @"username"
#define kEncryptedPassword @"encryptedPassword"
#define kRememberLogin @"rememberLogin"
#define kOpenStation @"openStation"
#define kPartnerId @"partnerId"
#define kUserId @"userId"
#define kPartnerAuthToken @"partnerAuthToken"
#define kUserAuthToken @"userAuthToken"
#define kSyncTime @"syncTime"

@implementation PandoraAppDelegate

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
	// Load Images
	thumbsDownImage = [[NSImage imageNamed:@"ThumbsDownTemplate.pdf"] retain];
	thumbsUpImage = [[NSImage imageNamed:@"ThumbsUpTemplate.pdf"] retain];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Setup Default Settings
	userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults registerDefaults:
	 [NSDictionary dictionaryWithObjectsAndKeys:
	  [NSNumber numberWithInt:0], kOpenTab,
	  @"none", kUsername,
	  @"none", kEncryptedPassword,
	  [NSNumber numberWithBool:false], kRememberLogin,
	  [NSNumber numberWithInt:1], kOpenStation,
	  @"none", kPartnerId,
	  @"none", kUserId,
	  @"none", kPartnerAuthToken,
	  @"none", kUserAuthToken,
	  [NSNumber numberWithInt:0], kSyncTime,
	  nil]];
	
	[self startLoginSheet];
	
	// Setup UI Elements
	/*
	 [self.windowView addConstraint:[NSLayoutConstraint constraintWithItem:self.mainTabView
	 attribute:NSLayoutAttributeHeight
	 relatedBy:NSLayoutRelationEqual
	 toItem:self.mainTabView
	 attribute:NSLayoutAttributeWidth
	 multiplier:1.0
	 constant:1]];
	 //*/
	[self.stationsTabSongTextView setStringValue:@"No Song Playing"];
	[self.mainTabView selectTabViewItemAtIndex:0]; //[userDefaults integerForKey:kOpenTab]];
	[self.tabSelectionView selectSegmentWithTag:0]; //[userDefaults integerForKey:kOpenTab]];
	playHeadTimer = [[NSTimer timerWithTimeInterval:.1
											 target:self
										   selector:@selector(updatePlayHead)
										   userInfo:nil
											repeats:YES]
					 retain];
	[[NSRunLoop currentRunLoop] addTimer:playHeadTimer forMode:NSDefaultRunLoopMode];
	[self.playlistView setDoubleAction:@selector(songSelected)];
	[self.stationsTableView setDoubleAction:@selector(stationSelected)];
}

- (void)startLoginSheet {
	[NSApp beginSheet: self.loginWindow
	   modalForWindow: self.window
		modalDelegate: nil //self
	   didEndSelector: nil //@selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo: nil];
	[NSApp endSheet:self.loginWindow];
}

- (IBAction)login:(id)sender {
	NSString *username = [self.usernameView stringValue];
	NSString *password = [self.passwordView stringValue];
	//bool remember = [self.rememberMeView state];
	
	// Start Pandora
	pandora = [[PandoraConnection alloc] initWithPartner:@"iOS"];
	NSError *error = nil;
	[pandora loginWithUsername:username andPassword:password error:&error];
	if (error) {
		NSLog(@"Login error:\n%@", error);
		if ([error code] == 1002)
		{
			[self.loginErrorView setHidden:NO];
			[self.loginErrorImage setHidden:NO];
		}
		else
		{
			[self.loginErrorView setStringValue:@"Unknown Error"];
			[self.loginErrorView setHidden:NO];
			[self.loginErrorImage setHidden:NO];
		}
		return;
	}
	
	// Close Modal Sheet
	[self.loginWindow orderOut:self];

	
	// Save Settings
	/*[userDefaults setBool:remember forKey:kRememberLogin];
	 if (remember) {
	 [pandora saveToDefaults:userDefaults];
	 }*/
	
	// Start Station
	stationList = [[NSMutableArray arrayWithArray:[pandora getStationList]] retain];
	[self.stationsTableView reloadData];
	//[self.playlistView reloadData];
	NSInteger first_selected_station = 1; //[userDefaults integerForKey:kOpenStation];
	PandoraStation *station = [pandora getStation:[stationList objectAtIndex:first_selected_station]];
	[self changeStation: station];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return TRUE;
}

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)item {
	BOOL ans = YES;
	if (item == self.logoutMenuItem) {
		ans = (pandora) ? YES : NO;
	}
	else if (item == self.playPauseMenuItem || item == self.nextMenuItem) {
		ans = (selectedStation) ? YES : NO;
	}
	else if (item == self.backMenuItem) {
		ans = (selectedStation && [selectedStation getCurrentIndex] != 0) ? YES : NO;
	}
	return ans;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	[userDefaults setInteger:[self.tabSelectionView selectedSegment] forKey:kOpenTab];
	[userDefaults setInteger:[stationList indexOfObject:[selectedStation stationName]] forKey:kOpenStation];
}

/*****************************************
 Menu Bar Methods
 *****************************************/

- (IBAction)playPause:(id)sender {
	if (audioPlayer) {
		if (audioPlayer.playing) {
			[audioPlayer pause];
		}
		else {
			[audioPlayer play];
		}
	}
	else {
		[self playNextSong];
	}
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
	[self changeSong:[selectedStation setCurrentIndex:[selectedStation getCurrentIndex] - 1]];
}

- (IBAction)logout:(id)sender {
	if (audioPlayer) {
		[audioPlayer stop];
		[audioPlayer release];
		audioPlayer = nil;
	}
	[stationList release];
	[selectedSong release];
	[selectedStation release];
	[pandora release];
	stationList = nil;
	selectedSong = nil;
	selectedStation = nil;
	pandora = nil;
	[self startLoginSheet];
}

/*****************************************
 Tabel View Deligate Methods
 *****************************************/

- (NSInteger)numberOfRowsInTableView:(NSTableView *) view {
	if (view == self.stationsTableView) {
		return [stationList count];
	}
	else if (view == self.playlistView) {
		return [selectedStation count];
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
		PandoraSong *song = [selectedStation getSongAtIndex:row];
		if(!song.enabled) {
			
		}
		if ([thisColName isEqualToString:@"Album Art"]) {
			NSImageView *thisCell = [tableView makeViewWithIdentifier:thisColName owner:self];
			[thisCell setImage:[song albumArt]];
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
			if (row == [selectedStation getCurrentIndex]) {
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
		//return [[selectedStation getSongAtIndex:row] enabled];
	}
	return YES;
}

/*****************************************
 Song Playing Methods
 *****************************************/

- (void)playNextSong {
	[self clearPlayer];
	[self changeSong: [selectedStation getNextSong]];
}

- (void)changeStation:(PandoraStation *)newStation {
	selectedStation = newStation;
	[self.stationsTabStationNameView setStringValue:
	 [newStation stationName]];
	if (audioPlayer) {
		[audioPlayer pause];
	}
	PandoraSong *song = [newStation getCurrentSong];
	[self.playlistView reloadData];
	[self changeSong: song];
}

- (void)changeSong:(PandoraSong *)newSong {
	@synchronized(self) {
		NSLog(@"New Song: %@", newSong.songName);
		
		// Get Song Data
		[newSong loadData];
		if (!newSong.enabled) {
			NSLog(@"Song %@ is disabled", [newSong songName]);
			[self playNextSong];
			return;
		}
		
		selectedSong = newSong;
		
		// Play Song
		if (!(audioPlayer = selectedSong.audioPlayer))
		{
			NSError *error = nil;
			audioPlayer = [[AVAudioPlayer alloc] initWithData:selectedSong.songData
														error:&error];
			if (error) {
				NSLog(@"%@", error);
				return;
			}
			[audioPlayer setDelegate:self];
			selectedSong.audioPlayer = audioPlayer;
		}
		else {
			[audioPlayer retain];
		}
		[audioPlayer play];
		//NSLog(@"Song Duration: %ld", (NSInteger)audioPlayer.duration);
		
		// Setup gui elemets
		[self.window setTitle:[NSString stringWithFormat:@"Playing '%@' on %@",
							   [selectedSong songName],
							   [selectedStation stationName]]];
		[selectedStation cleanPlayList];
		[self.playlistView reloadData];
		[self.playHeadView setMaxValue:[audioPlayer duration]];
		[self.playlistView selectRowIndexes:[NSIndexSet indexSetWithIndex:[selectedStation getCurrentIndex]] byExtendingSelection:NO];
		[self.stationsTabAlbumView setImage:selectedSong.albumArt];
		[self.playingTabAlbumView setImage:selectedSong.albumArt];
		[self.stationsTabSongTextView setStringValue:[NSString stringWithFormat:@"Title: %@\nArtist: %@\nAlbum: %@",
													  [selectedSong songName],
													  [selectedSong artistName],
													  [selectedSong albumName]]];
	}
}

- (void)songSelected {
	[self clearPlayer];
	PandoraSong *song = [selectedStation setCurrentIndex:
						 [self.playlistView selectedRow]];
	if (!song.enabled) {
		NSLog(@"Selected song %@ is disabled", [song songName]);
		return;
	}
	[self changeSong:song];
}

- (void)stationSelected {
	PandoraStation *station = [pandora getStation:
							   [stationList objectAtIndex:
								[self.stationsTableView selectedRow]]];
	NSLog(@"New Station Selected: %@", station.stationName);
	[self changeStation:station];
}

- (void)clearPlayer {
	if (audioPlayer) {
		[audioPlayer pause];
		audioPlayer.currentTime = 0;
		[audioPlayer release];
		audioPlayer = nil;
	}
}

- (NSString *)timeFormatted:(NSInteger)totalSeconds
{
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    //int hours = totalSeconds / 3600;
	
    //return [NSString stringWithFormat:@"%02d:%02d:%02d",hours, minutes, seconds];
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
	switch (selection) {
		case 0:
			[selectedSong rate:YES];
			break;
		case 1:
			[selectedSong rate:NO];
			[self skipSong:sender];
			break;
	}
	[self.playlistView reloadDataForRowIndexes:
	 [NSIndexSet indexSetWithIndex:[selectedStation getCurrentIndex]]
								 columnIndexes:
	 [NSIndexSet indexSetWithIndex:1]];
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

@end