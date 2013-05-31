//
//  cjfmanExtentionToNSString.h
//  Pandora's Box
//
//  Created by Charles Franklin on 1/5/13.
//  Copyright (c) 2013 Charles Franklin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (cjfmanExtentionToNSString)

- (unsigned int)hexIntValue;
- (unsigned char*)decodeHex;
+ (NSString*)encodeHex:(unsigned char*)charString length:(unsigned long)l;
- (NSString*)toAlphaNumeric;

@end