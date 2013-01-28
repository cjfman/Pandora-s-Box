//
//  PandoraAppDelegate.h
//  Pandora's Box
//
//  Created by Charles Franklin on 1/3/13.
//  Copyright (c) 2013 Charles Franklin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import <AVFoundation/AVFoundation.h>
#import "PandoraConnection.h"

@interface PandoraAppDelegate : NSObject <NSApplicationDelegate, NSTableViewDelegate, AVAudioPlayerDelegate>
{
	PandoraConnection *pandora;
	PandoraStation *selectedStation;
	PandoraSong *selectedSong;
	NSMutableArray *stationList;
	AVAudioPlayer *audioPlayer;
	NSTimer *playHeadTimer;
	NSUserDefaults *userDefaults;
	
	// Images
	NSImage *thumbsUpImage;
	NSImage *thumbsDownImage;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSView *windowView;

// Login Sheet
@property (assign) IBOutlet NSPanel *loginWindow;
@property (assign) IBOutlet NSTextField *usernameView;
@property (assign) IBOutlet NSSecureTextField *passwordView;
@property (assign) IBOutlet NSButton *rememberMeView;
@property (assign) IBOutlet NSTextField *loginErrorView;
@property (assign) IBOutlet NSImageView *loginErrorImage;
- (IBAction)login:(id)sender;

// Toolbar Buttons
@property (assign) IBOutlet NSPopUpButton *mainActionButtonView;
@property (assign) IBOutlet NSSegmentedControl *tabSelectionView;
@property (assign) IBOutlet NSSegmentedControl *playbackControls;
- (IBAction)newTabSelected:(id)sender;
- (IBAction)playPause:(id)sender;
- (IBAction)skipSong:(id)sender;
- (IBAction)playPreviousSong:(id)sender;
- (IBAction)audioControlPushed:(id)sender;
- (IBAction)ratingPushed:(id)sender;

// Time Bar
@property (assign) IBOutlet NSView *timeBarView;
@property (assign) IBOutlet NSTextField *elapsedTimeView;
@property (assign) IBOutlet NSTextField *remainingTimeView;
@property (assign) IBOutlet NSSlider *playHeadView;
- (IBAction)songScrubbing:(id)sender;
- (void)updatePlayHead;

// Tab View
@property (assign) IBOutlet NSTabView *mainTabView;

// Stations Tab
@property (assign) IBOutlet NSImageView *stationsTabAlbumView;
@property (assign) IBOutlet NSTextField *stationsTabSongTextView;
@property (assign) IBOutlet NSTableView *stationsTableView;

// Now Playing Tab
@property (assign) IBOutlet NSImageView *playingTabAlbumView;

// Playlist Tab
@property (assign) IBOutlet NSTableView *playlistView;



// Logging in
//- (BOOL)startPandora:()

// Audio Playing Methods
- (void)playNextSong;
- (void)changeStation:(PandoraStation*)newStation;
- (void)changeSong:(PandoraSong*)newSong;
- (void)songSelected;
- (void)clearPlayer;
- (NSString *)timeFormatted:(NSInteger)totalSeconds;

@end
