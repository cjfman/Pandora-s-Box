//
//  StationWindowController.h
//  Pandora's Box
//
//  Created by Charles Franklin on 6/8/13.
//  Copyright (c) 2013 Charles Franklin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PandoraConnection.h"
#import "PandoraSeed.h"

@interface StationWindowController : NSWindowController <NSWindowDelegate, NSTextFieldDelegate, NSTableViewDataSource, NSTableViewDelegate> {
	PandoraConnection *pandora;
	NSArray *artists;
	NSArray *songs;
	PandoraSearchResult *tophit;
}
- (void)setPandoraConnection:(PandoraConnection*)aConnection;
- (void)startSheet;
- (void)setTableLength:(CGFloat)length;
- (void)autosetTableLength;
- (void)closeTable;
- (void)alertUser:(NSString *)message;
- (IBAction)action:(id)sender;

@property (retain) NSWindow *mainWindow;

@property (assign) IBOutlet NSPanel *sheet;
@property (assign) IBOutlet NSView *sheetView;

@property (assign) IBOutlet NSTextField *textField;
@property (assign) IBOutlet NSScrollView *scrollView;
@property (assign) IBOutlet NSTableView *tableView;
@property (assign) IBOutlet NSButton *createButton;
@property (assign) IBOutlet NSButton *cancelButton;
@property (assign) IBOutlet NSProgressIndicator *indicator;

@end