//
//  PandoraAppDelegate.h
//  Pandora's Box
//
//  Created by Charles Franklin on 1/3/13.
//  Copyright (c) 2013 Charles Franklin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#import "PandoraConnection.h"
#import "SPMediaKeyTap.h"
#import "StationWindowController.h"

#define audioCacheFolder @"Audio File Cache"

@interface PandoraAppDelegate : NSObject <NSApplicationDelegate, NSTableViewDelegate, AVAudioPlayerDelegate, NSUserInterfaceValidations>
{
	NSString *applicationName;
	NSUserDefaults *userDefaults;
	NSFileManager *fileManager;
	StationWindowController *stationController;
	
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
	NSImage *openDrawer;
	NSImage *closeDrawer;
	
	//Paths
	NSString *supportPath;
	NSString *audioCachePath;
	
	// Media Key Support
	SPMediaKeyTap *keyTap;
	
	// Constraints
	NSArray *stationsScrollViewConstraints;
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
@property (assign) IBOutlet NSMenuItem *toggleStationsMenuItem;
- (IBAction)playPause:(id)sender;
- (IBAction)skipSong:(id)sender;
- (IBAction)playPreviousSong:(id)sender;
- (IBAction)logout:(id)sender;
- (IBAction)tired:(id)sender;
- (IBAction)relogin:(id)sender;
- (IBAction)getLyricsMenuItem:(id)sender;
- (IBAction)toggleStationList:(id)sender;
- (IBAction)debugAction:(id)sender;

// Toolbar Buttons
@property (assign) IBOutlet NSSegmentedControl *tabSelectionView;
@property (assign) IBOutlet NSSegmentedControl *playbackControls;
@property (assign) IBOutlet NSSlider *volumeSlider;
@property (assign) IBOutlet NSButton *toggleStationsButton;
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

// Stations Table
@property (assign) IBOutlet NSTableView *stationsTableView;
@property (assign) IBOutlet NSScrollView *stationsScrollView;

// Tab View
@property (assign) IBOutlet NSTabView *mainTabView;

// Song Info Tab
@property (assign) IBOutlet NSImageView *songTabAlbumView;
@property (assign) IBOutlet NSTextField *songTabSongTextView;
@property (assign) IBOutlet NSTextView *lyricsView;

// Album Art Tab
@property (assign) IBOutlet NSImageView *albumTabAlbumView;

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
- (void)alertUser:(NSString*)message;

// Error Handling
- (void)errorHandler:(NSError*)error;

@end
