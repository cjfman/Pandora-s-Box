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
	if (self.mainWindow) [self.mainWindow release];
	[super dealloc];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
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
	[self.textField setStringValue:@""];
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

- (void)alertUser:(NSString *)message {
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert setMessageText:message];
	[alert runModal];
}

- (IBAction)action:(id)sender {
	NSLog(@"%@", self.createButton);
	NSLog(@"%@", sender);
	if (sender == self.createButton) {
	}
	// Close Modal Sheet
	[NSApp endSheet:self.sheet];
	[self.sheet orderOut:self];
}

/*****************************************
 Text View Deligate Methods
 *****************************************/

- (void)controlTextDidChange:(NSNotification *)aNotification {
	if ([[self.textField stringValue] length] == 0) {
		if (artists) [artists release];
		if (songs) [songs release];
		if (tophit) [tophit release];
		artists = nil;
		songs = nil;
		tophit = nil;
		[self.tableView reloadData];
		[self closeTable];
		return;
	}
	
	static int count = 0;			// Counts how many searches are running
	if (!count++) [self.indicator startAnimation:self];	// Only start on first
	int refnum = count; // To id multiple calls
	
	// Define Callback function
	void (^callback)(NSDictionary*) = ^(NSDictionary* results) {
		if (refnum != count) return;	// Not the most recent request
		if (!results) {
			[self alertUser:@"Couldn't connenct to Pandora"];
			return;
		}
		NSLog(@"%@", results);
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
		[self.tableView reloadData];
		[self autosetTableLength];
		[self.indicator stopAnimation:self];
		count = 0;
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
	NSInteger offset = row;
	while (1) {
		if (tophit) {
			if (offset == 0) {
				string = tophit.stringValue;
				if ([tophit isArtist])
					string = [string stringByAppendingString:@" (artist)"];
				else
					string = [string stringByAppendingString:@" (song)"];
				break;
			}
			offset--;
		}
		if (artists && [artists count]) {
			if (offset < [artists count]) {
				string = [[artists objectAtIndex:offset] stringValue];
				break;
			}
			offset -= [artists count];
		}
		if (songs && [songs count]) {
			if (offset < [songs count]) {
				string = [[songs objectAtIndex:offset] stringValue];
				break;
			}
		}
		string = @"";
		break;
	}
	thisCell.textField.stringValue = string;
	return thisCell;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	NSTableView *tableView = [aNotification object];
	[tableView scrollRowToVisible:[tableView selectedRow]];
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
	return YES;
}

@end
