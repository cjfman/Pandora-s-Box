//
//  CFAudioPlayer.m
//  Pandora's Box
//
//  Created by Charles Franklin on 6/25/13.
//  Copyright (c) 2013 Charles Franklin. All rights reserved.
//

#import "CFAudioPlayer.h"

@implementation CFAudioPlayer

#ifndef GNUstep
#else

- (id)initWithData:(NSData *)data {
	if (!(self = [super init])) return;
	return self;
}

- (void)play {
	
}

- (void)pause {
	
}

- (void)stop {
	
}

// Setters and Getters

- (BOOL)playing {
	return NO;
}

- (BOOL)isPlaying {
	return NO;
}

- (NSTimeInterval)currentTime {
	return 0;
}

- (void)setCurrentTime:(NSTimeInterval)time {
	
}

- (float)volume {
	return 0;
}

- (void)setVolume:(float)newVolume {
	
}

- (NSTimeInterval)duration {
	
}

- (void)setDelegate:(id)aDelegate {
	
}

#endif

@end
