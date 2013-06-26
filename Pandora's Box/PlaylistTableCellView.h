//
//  PlaylistTableCellView.h
//  Pandora's Box
//
//  Created by Charles Franklin on 1/27/13.
//  Copyright (c) 2013 Charles Franklin. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PlaylistTableCellView : NSTableCellView

@property (assign) IBOutlet NSImageView *ratingImage;
@property (assign) IBOutlet NSProgressIndicator *indicator;

@end
