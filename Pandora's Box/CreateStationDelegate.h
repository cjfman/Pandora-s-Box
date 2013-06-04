//
//  CreateStationDelegate.h
//  Pandora's Box
//
//  Created by Charles Franklin on 6/3/13.
//  Copyright (c) 2013 Charles Franklin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CreateStationDelegate : NSObject <NSApplicationDelegate, NSTableViewDelegate>
{
	
}

@property (assign) IBOutlet NSTextField *searchTextField;
@property (assign) IBOutlet NSTableView *resultsTableView;
@property (assign) IBOutlet NSButton *cancelButton;
@property (assign) IBOutlet NSButton *createButton;
@property (assign) IBOutlet NSProgressIndicator *progressIndicator;

- (IBAction)cancel:(id)sender;
- (IBAction)create:(id)sender;

@end
