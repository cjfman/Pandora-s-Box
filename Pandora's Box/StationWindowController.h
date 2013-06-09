//
//  StationWindowController.h
//  Pandora's Box
//
//  Created by Charles Franklin on 6/8/13.
//  Copyright (c) 2013 Charles Franklin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PandoraConnection.h"

@interface StationWindowController : NSWindowController <NSWindowDelegate, NSTextFieldDelegate> {
	PandoraConnection *pandora;
}
- (void)setPandoraConnection:(PandoraConnection*)aConnection;
- (void)startSheet;
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