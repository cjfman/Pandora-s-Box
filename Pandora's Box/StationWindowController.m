//
//  StationWindowController.m
//  Pandora's Box
//
//  Created by Charles Franklin on 6/8/13.
//  Copyright (c) 2013 Charles Franklin. All rights reserved.
//

#import "StationWindowController.h"
#import "PandoraSeed.h"

#define CHAR_HEIGHT 22
#define HEADER_HEIGHT 17

@implementation StationWindowController

- (id)init {
	self = [super initWithWindowNibName:@"StationWindowController"
								  owner:self];
	target = nil;
	pandora = nil;
	artists = nil;
	songs = nil;
	tophit = nil;
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
	if (pandora) [pandora release];
	if (artists) [artists release];
	if (songs) [songs release];
	if (tophit) [tophit release];
	if (target) [target release];
	if (self.mainWindow) [self.mainWindow release];
	[super dealloc];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
}

- (void)setTarget:(id)aTarget callbackSelector:(SEL)selector {
	if (!aTarget) return;
	target = [aTarget retain];
	finalCallback = selector;
}

- (void)setPandoraConnection:(PandoraConnection*)aConnection {
	if (pandora) {
		[pandora release];
	}
	pandora = [aConnection retain];
}

- (void)startSheet {
	[self window]; // Load the sheet from xib
	// Set up GUI
	[self.indicator setUsesThreadedAnimation:YES];
	[self.textField setStringValue:@""];
	[self.createButton setEnabled:NO];
	[self.messageLabel setHidden:YES];
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

- (void)setTableLength:(CGFloat)length {
	// Create new frame for sheet
	// Auto Contraints will stretch the Table
	NSInteger max = self.mainWindow.frame.size.height / 2;
	length = MIN(length, max);
	NSRect sheetFrame = [self.sheet frame];
	CGFloat diff = length - [self.scrollView frame].size.height;
	sheetFrame.size.height += diff;
	sheetFrame.origin.y -= diff;
	// Start Animation
	[NSAnimationContext beginGrouping];
	[[self.scrollView animator] setAlphaValue:1];
	[self.sheet setFrame:sheetFrame display:YES animate:YES];
	[NSAnimationContext endGrouping];
	return;
}

- (void)closeTable {
	// Hide Scroll View and get frame
	NSRect frame = [self.scrollView frame];
	CGFloat hdiff = frame.size.height;
	// Reize and position sheet accordingly
	frame = [self.sheet frame];
	frame.size.height -= hdiff;
	frame.origin.y += hdiff;
	[NSAnimationContext beginGrouping];
	[[self.scrollView animator] setAlphaValue:0];
	[self.sheet setFrame:frame display:YES animate:YES];
	[NSAnimationContext endGrouping];
}

- (void)autosetTableLength {
	NSInteger entries = [self numberOfRowsInTableView:self.tableView];
	CGFloat height = entries * CHAR_HEIGHT + HEADER_HEIGHT;
	[self setTableLength:height];
}

- (PandoraSearchResult*)resultForRow:(NSInteger)row {
	NSInteger offset = row;
	if (tophit) {
		if (offset == 0) {
			return tophit;
		}
		offset--;
	}
	if (artists && [artists count]) {
		if (offset < [artists count]) {
			return [artists objectAtIndex:offset];
		}
		offset -= [artists count];
	}
	if (songs && [songs count]) {
		if (offset < [songs count]) {
			return [songs objectAtIndex:offset];
		}
	}
	return nil;
}

- (void)clearResults {
	// Search field is empty
	[self.messageLabel setHidden:YES];
	[self.createButton setEnabled:NO];
	// Clear any previous results
	if (artists) [artists release];
	if (songs) [songs release];
	if (tophit) [tophit release];
	artists = nil;
	songs = nil;
	tophit = nil;
	[self.tableView reloadData];
	[self closeTable];
}

- (void)createStation {
	PandoraSearchResult *seed = [self resultForRow:[self.tableView selectedRow]];
	PandoraStation *station = [pandora createStation:seed];
	if (target)
		[target performSelector:finalCallback withObject:station];
}

- (void)alertUser:(NSString *)message {
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert setMessageText:message];
	[alert runModal];
}

- (IBAction)action:(id)sender {
	if (sender == self.createButton) {
		[self.indicator startAnimation:self];
		[self createStation];
		[self.indicator stopAnimation:self];
	}
	// Close Modal Sheet
	[self clearResults];
	[self.indicator stopAnimation:self];
	[NSApp endSheet:self.sheet];
	[self.sheet orderOut:self];
}

/*****************************************
 Text View Deligate Methods
 *****************************************/

- (void)controlTextDidChange:(NSNotification *)aNotification {
	if ([[self.textField stringValue] length] == 0) {
		[self clearResults];
		return;
	}
	
	static int count = 0;			// Counts how many searches are running
	if (!count++) [self.indicator startAnimation:self];	// Only start on first
	int refnum = count; // To id multiple calls
	
	// Define Callback function
	void (^callback)(NSDictionary*) = ^(NSDictionary* results) {
		if (refnum != count) return;	// Not the most recent request
		if (!results) {
			[self alertUser:@"Unknown Error Conducting Search"];
			return;
		}
		//DDLogInfo(@"%@", results);
		// Clear old lists
		if (artists) [artists release];
		if (songs) [songs release];
		if (tophit) [tophit release];
		artists = nil;
		songs = nil;
		tophit = nil;
		
		NSMutableArray *swap = [NSMutableArray array];
		
		// Populate artists list
		for (NSDictionary *info in [results objectForKey:@"artists"]) {
			PandoraSearchResult *result = [[PandoraSearchResult alloc]
										   initWithDictionary:info];
			if ([result likelyMatch])
				tophit = result;
			else {
				[swap addObject:result];
				[result release];
			}
		}
		[swap sortUsingSelector:@selector(compare:)];
		artists = [[NSArray arrayWithArray:swap] retain];
									
		// Populate artists list
		[swap removeAllObjects];
		for (NSDictionary *info in [results objectForKey:@"songs"]) {
			PandoraSearchResult *result = [[PandoraSearchResult alloc]
										   initWithDictionary:info];
			[swap addObject:result];
			[result release];
		}
		[swap sortUsingSelector:@selector(compare:)];
		songs = [[NSArray arrayWithArray:swap] retain];
		
		// Setup GUI
		[self.tableView reloadData];
		[self.indicator stopAnimation:self];
		if ([self numberOfRowsInTableView:self.tableView]) {
			[self autosetTableLength];
			[self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0]
						byExtendingSelection:NO];
			[self.messageLabel setHidden:YES];
		}
		else {
			[self clearResults];
			[self.messageLabel setHidden:NO];
		}
		count = 0;	// The last request has come in
	};
	[pandora asynchronousMethod:@selector(musicSearch:)
					 withObject:[self.textField stringValue]
				completionBlock:callback];
}

/*****************************************
 Tabel View Deligate Methods
 *****************************************/

- (NSInteger)numberOfRowsInTableView:(NSTableView *) view {
	NSInteger count = 0;
	if (artists) count += [artists count];
	if (songs)   count += [songs count];
	if (tophit)  count++;
	return count;
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
				  row:(NSInteger)row {
	NSString *thisColName = [tableColumn identifier];
	NSTableCellView *thisCell = [tableView makeViewWithIdentifier:thisColName
															owner:self];
	NSString *string;
	PandoraSearchResult *result = [self resultForRow:row];
	string = [result stringValue];
	if (result == tophit) {
		if ([tophit isArtist])
			string = [string stringByAppendingString:@" (artist)"];
		else
			string = [string stringByAppendingString:@" (song)"];
	}
	thisCell.textField.stringValue = string;
	return thisCell;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	NSTableView *tableView = [aNotification object];
	NSInteger row = [tableView selectedRow];
	if (row == -1)
		[self.createButton setEnabled:NO];
	else {
		[tableView scrollRowToVisible:row];
		[self.createButton setEnabled:YES];
	}
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
	return YES;
}

@end
