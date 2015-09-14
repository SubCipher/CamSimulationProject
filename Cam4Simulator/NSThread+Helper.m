//
//  NSThread+Helper.m
//  Cam4Simulator
//
//  Created by MacMan on 9/14/15.
//  Copyright (c) 2015 MacManApp. All rights reserved.
//

#import "NSThread+Helper.h"

@implementation NSThread (Helper)
+ (void)executeOnMainThread:(void (^)())block
{
    if (!block) return;
    
    if ([[NSThread currentThread] isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^ {
            block();
        });
    }
}

@end
