//
//  Utility.m
//  SnapChatProject
//
//  Created by Pham Hieu on 3/30/15.
//  Copyright (c) 2015 Facebook. All rights reserved.
//

#import "Utility.h"

@implementation Utility

+ (NSString*)getDocumentFilePath:(NSString*)name{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:name];
    
    return filePath;
}

@end
