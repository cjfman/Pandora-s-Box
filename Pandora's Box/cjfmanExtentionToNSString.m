//
//  cjfmanExtentionToNSString.m
//  Pandora's Box
//
//  Created by Charles Franklin on 1/5/13.
//  Copyright (c) 2013 Charles Franklin. All rights reserved.
//

#import "cjfmanExtentionToNSString.h"

@implementation NSString (cjfmanExtentionToNSString)

- (unsigned int)hexIntValue
{
    NSScanner *scanner;
    unsigned int result;
	
    scanner = [NSScanner scannerWithString: self];
	
    [scanner scanHexInt: &result];
	
    return result;
}

- (unsigned char*)decodeHex
{
	unsigned long l = [self length];
	if (l%2 != 0) return 0;
	unsigned char* result = malloc(l/2*sizeof(unsigned char));
	for (int i = 0; i < l; i += 2)
	{
		result[i/2] = [[self substringWithRange:NSMakeRange(i, 2)] hexIntValue];
		//NSLog(@"Char %d: %i", i/2, result[i/2]);
	}
	return result;
}

+ (NSString*)encodeHex:(unsigned char*)charString length:(unsigned long)l
{
	NSMutableString *tempString = [NSMutableString stringWithCapacity:l*2];
	for (int i = 0; i < l; i++)
	{
		[tempString appendFormat:@"%02x", charString[i]];
	}
	return [NSString stringWithString:tempString];
}

@end