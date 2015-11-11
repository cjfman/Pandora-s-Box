//
//  JSONObject.m
//  Pandora's Box
//
//  Created by Charles Franklin on 11/11/15.
//  Copyright (c) 2015 Charles Franklin. All rights reserved.
//

#import "JSONObject.h"

@implementation JSONObject

- (void)setValuesForKeysWithDictionary:(NSDictionary*)info
{
    for (NSString *key in info) {
        @try {
            [self setValue:[info objectForKey:key] forKey:key];
        }
        @catch (NSException *exception) {
            // Do nothing
        }
    }
}

@end
