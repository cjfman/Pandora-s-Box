//
//  StationWindowController.m
//  Pandora's Box
//
//  Created by Charles Franklin on 6/8/13.
//  Copyright (c) 2013 Charles Franklin. All rights reserved.
//

#import "StationWindowController.h"

@implementation StationWindowController

- (id)init {
	self = [super initWithWindowNibName:@"StationWindowController"
								  owner:self];
	return self;
}

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc {
	[pandora release];
	[self.mainWindow release];
	[super dealloc];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    NSLog(@"Sheet Loaded");
}

- (void)setPandoraConnection:(PandoraConnection*)aConnection {
	if (pandora) {
		[pandora release];
	}
	pandora = [aConnection retain];
}

- (void)startSheet {
	[self window]; // Load the sheet from xib
	[self.indicator setUsesThreadedAnimation:YES];
	// Hide Scroll View and get frame
	NSRect frame = [self.scrollView frame];
	CGFloat hdiff = frame.size.height;
	[self.scrollView setAlphaValue:0];
	// Reize and position sheet accordingly
	frame = [self.sheet frame];
	frame.size.height -= hdiff;
	frame.origin.y += hdiff;
	[self.sheet setFrame:frame display:NO];
	// Start Sheet
	[NSApp beginSheet: self.sheet
	   modalForWindow: self.mainWindow
		modalDelegate: nil //self
	   didEndSelector: nil //@selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo: nil];
	[self.sheet setPreventsApplicationTerminationWhenModal:NO];
}

- (IBAction)action:(id)sender {
	NSLog(@"%@", self.createButton);
	NSLog(@"%@", sender);
	if (sender == self.createButton) {
		CGFloat diff = 100;
		// Create new frame for sheet
		NSRect sheetFrame = [self.sheet frame];
		sheetFrame.size.height += diff;
		sheetFrame.origin.y -= diff;
		// Start Animation
		[NSAnimationContext beginGrouping];
		[[self.scrollView animator] setAlphaValue:1];
		[self.sheet setFrame:sheetFrame display:YES animate:YES];
		[NSAnimationContext endGrouping];
		return;
	}
	// Close Modal Sheet
	[NSApp endSheet:self.sheet];
	[self.sheet orderOut:self];
}

- (void)controlTextDidChange:(NSNotification *)aNotification {
	[self.indicator startAnimation:self];
	//NSDictionary *results = [pandora musicSearch:[self.textField stringValue]];
	[pandora asynchronousMethod:@selector(musicSearch:)
					 withObject:[self.textField stringValue]
				completionBlock:^(NSDictionary* results) {
					NSLog(@"%@", results);
				}];
	[self.indicator stopAnimation:self];
}

@end
