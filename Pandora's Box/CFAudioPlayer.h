//
//  CFAudioPlayer.h
//  Pandora's Box
//
//  Created by Charles Franklin on 6/25/13.
//  Copyright (c) 2013 Charles Franklin. All rights reserved.
//

#ifndef GNUstep
#import <AVFoundation/AVFoundation.h>

@interface CFAudioPlayer : AVAudioPlayer
#else
@interface CFAudioPlayer : NSObject {
	BOOL playing;
}

- (id)initWithData:(NSData *)data;
- (void)play;
- (void)pause;
- (void)stop;

// Setters and Getters
- (BOOL)playing;
- (BOOL)isPlaying;
- (NSTimeInterval)currentTime;
- (void)setCurrentTime:(NSTimeInterval)time;
- (float)volume;
- (void)setVolume:(float)newTime;
- (NSTimeInterval)duration;
- (void)setDelegate:(id)aDelegate;

#endif

@end
