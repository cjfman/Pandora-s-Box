//
//  BottomBar.m
//  Pandora's Box
//
//  Created by Charles Franklin on 7/5/13.
//  Copyright (c) 2013 Charles Franklin. All rights reserved.
//

#import "BottomBar.h"

@implementation BottomBar

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
	// set any NSColor for filling, say white:
    [[NSColor whiteColor] setFill];
    NSRectFill(dirtyRect);
    [super drawRect:dirtyRect];
}

@end
