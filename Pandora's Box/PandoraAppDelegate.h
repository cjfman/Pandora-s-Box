//
//  PandoraAppDelegate.h
//  Pandora's Box
//
//  Created by Charles Franklin on 1/3/13.
//  Copyright (c) 2013 Charles Franklin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#import <WebKit/WebKit.h>
#import "PandoraConnection.h"
#import "SPMediaKeyTap.h"

#define audioCacheFolder @"Audio File Cache"

@interface PandoraAppDelegate : NSObject <NSApplicationDelegate, NSTableViewDelegate, AVAudioPlayerDelegate, NSUserInterfaceValidations>
{
	NSString *applicationName;
	NSUserDefaults *userDefaults;
	NSFileManager *fileManager;
	
	// Pandora
	PandoraConnection *pandora;
	PandoraStation *currentStation;
	PandoraSong *currentSong;
	NSMutableArray *stationList;
	NSString *username;
	NSString *password;
	
	// Audio
	AVAudioPlayer *audioPlayer;
	NSTimer *playHeadTimer;
	
	// Images
	NSImage *thumbsUpImage;
	NSImage *thumbsDownImage;
	NSImage *speakerLoud;
	NSImage *speakerMid;
	NSImage *speakerQuiet;
	NSImage *speakerMute;
	NSImage *playSymbol;
	NSImage *pauseSymbol;
	
	//Paths
	NSString *supportPath;
	NSString *audioCachePath;
	
	// Media Key Support
	SPMediaKeyTap *keyTap;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSView *windowView;

// App Delagate Methods
- (void)applicationWillFinishLaunching:(NSNotification *)notification;
- (void)applicationDidFinishLaunching:(NSNotification *)notification;
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender;
- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem;
- (void)applicationWillTerminate:(NSNotification *)notification;

// Login Sheet
@property (assign) IBOutlet NSPanel *loginWindow;
@property (assign) IBOutlet NSTextField *usernameView;
@property (assign) IBOutlet NSSecureTextField *passwordView;
@property (assign) IBOutlet NSButton *rememberMeView;
@property (assign) IBOutlet NSTextField *loginErrorView;
@property (assign) IBOutlet NSImageView *loginErrorImage;
- (void)startLoginSheet;
- (IBAction)login:(id)sender;

// Media Keys
- (void)mediaKeyTap:(SPMediaKeyTap*)keyTap receivedMediaKeyEvent:(NSEvent*)event;

// Menu Bar
@property (assign) IBOutlet NSMenuItem *logoutMenuItem;
@property (assign) IBOutlet NSMenuItem *playPauseMenuItem;
@property (assign) IBOutlet NSMenuItem *nextMenuItem;
@property (assign) IBOutlet NSMenuItem *backMenuItem;
@property (assign) IBOutlet NSMenuItem *tiredMenuItem;
@property (assign) IBOutlet NSMenuItem *debugMenuItem;
- (IBAction)playPause:(id)sender;
- (IBAction)skipSong:(id)sender;
- (IBAction)playPreviousSong:(id)sender;
- (IBAction)logout:(id)sender;
- (IBAction)tired:(id)sender;
- (IBAction)relogin:(id)sender;

// Toolbar Buttons
@property (assign) IBOutlet NSPopUpButton *mainActionButtonView;
@property (assign) IBOutlet NSSegmentedControl *tabSelectionView;
@property (assign) IBOutlet NSSegmentedControl *playbackControls;
@property (assign) IBOutlet NSSlider *volumeSlider;
- (IBAction)newTabSelected:(id)sender;
- (IBAction)audioControlPushed:(id)sender;
- (IBAction)ratingPushed:(id)sender;
- (IBAction)changeVolume:(id)sender;
- (IBAction)fullVolume:(id)sender;
- (IBAction)muteVolume:(id)sender;

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
@property (assign) IBOutlet NSTextField *stationsTabStationNameView;

// Now Playing Tab
@property (assign) IBOutlet NSImageView *playingTabAlbumView;

// Playlist Tab
@property (assign) IBOutlet NSTableView *playlistView;

// Audio Playing Methods
- (void)playNextSong;
- (void)changeStation:(PandoraStation*)newStation;
- (void)changeSong:(PandoraSong*)newSong;
- (void)songSelected;
- (void)stationSelected;
- (void)clearPlayer;
- (NSString *)timeFormatted:(NSInteger)totalSeconds;

// Helper Methods
- (NSInteger)playingSongIndex;
- (NSInteger)selectedSongIndex;
- (PandoraSong*)selectedSong;

@end
