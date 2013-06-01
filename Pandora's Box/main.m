//
//  main.m
//  Pandora's Box
//
//  Created by Charles Franklin on 1/27/13.
//  Copyright (c) 2013 Charles Franklin. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PandoraAppDelegate.h"

int main(int argc, char *argv[])
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool new] init];
	[NSApplication sharedApplication];
	PandoraAppDelegate *delegate = [[[PandoraAppDelegate new] init] autorelease];
	[NSApp setDelegate:delegate];
	[NSApp run];
	[pool release];
}
