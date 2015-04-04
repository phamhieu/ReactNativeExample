//
//  MyCameraView.m
//  SnapChatProject
//
//  Created by Pham Hieu on 3/30/15.
//  Copyright (c) 2015 Facebook. All rights reserved.
//

#import "MyCameraViewManager.h"

#import "MyCameraView.h"
#import "Utility.h"

#import "RCTUIManager.h"
#import "RCTConvert.h"
#import "RCTSparseArray.h"
#import "RCTEventDispatcher.h"

#import <FBSDKMessengerShareKit/FBSDKMessengerShareKit.h>

@implementation RCTConvert (MyCameraView)
RCT_ENUM_CONVERTER(CameraType, (@{@"camera-front": @(CameraTypeFront),
                                  @"camera-back": @(CameraTypeBack)}),
                                CameraTypeBack, integerValue)
@end
     
@implementation MyCameraViewManager
                                                    
#pragma mark - React Native

- (UIView *)view{
    return [[MyCameraView alloc] init];
}

RCT_EXPORT_VIEW_PROPERTY(cameraType, CameraType);

- (void)toggleCamera:(int)camType reactTag:(NSNumber *)reactTag{
    RCT_EXPORT();
    
    [self.bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, RCTSparseArray *viewRegistry) {
        id view = viewRegistry[reactTag];
        if (![view isKindOfClass:[MyCameraView class]]) {
            RCTLogError(@"Invalid view returned from registry, expecting MyCameraView, got: %@", view);
        }
        [view toggleCamera:camType];
    }];
}

- (void)toggleFlash:(int)flashType reactTag:(NSNumber *)reactTag{
    RCT_EXPORT();
    
    [self.bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, RCTSparseArray *viewRegistry) {
        id view = viewRegistry[reactTag];
        if (![view isKindOfClass:[MyCameraView class]]) {
            RCTLogError(@"Invalid view returned from registry, expecting MyCameraView, got: %@", view);
        }
        [view toggleFlashlight:flashType];
    }];
}

- (void)takePhoto:(NSNumber *)reactTag{
    RCT_EXPORT();
    
    [self.bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, RCTSparseArray *viewRegistry) {
        id view = viewRegistry[reactTag];
        if (![view isKindOfClass:[MyCameraView class]]) {
            RCTLogError(@"Invalid view returned from registry, expecting MyCameraView, got: %@", view);
        }
        // register for finish takePhoto notification
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(takePhotoFinishHandler:)
                                                     name:TAKE_PHOTO_FINISH object:nil];
        
        [view takePhoto];
    }];
}

- (void)sharePhoto:(NSString*)text positionY:(int)posY{
    RCT_EXPORT();
    
    //DebugLog(@"text:%@  posY:%d", text, posY);
    
    // generate image with user input text as water mark
    NSString *filePath = [Utility getDocumentFilePath:PHOTO_NAME];
    UIImage *image = [UIImage imageWithContentsOfFile:filePath];
    
    UIImage *imageWithText = [self drawText:text inImage:image atPoint:(CGPoint){0,posY}];
    
    if ([FBSDKMessengerSharer messengerPlatformCapabilities] & FBSDKMessengerPlatformCapabilityImage) {
        [FBSDKMessengerSharer shareImage:imageWithText withOptions:nil];
    }
}

- (void)checkFlashLightSupport:(int)cameraType callback:(RCTResponseSenderBlock)callback
{
    RCT_EXPORT();
    
    BOOL hasFlash = [MyCameraView doesSupportFlashLight:cameraType];
    return callback(@[@(hasFlash)]);
}

#pragma mark - Helper


- (void)takePhotoFinishHandler:(NSNotification*)notif{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:notif.name object:nil];
    
    BOOL result = [notif.object boolValue];
    if (result){
        NSString *filePath = [Utility getDocumentFilePath:PHOTO_NAME];
        //DebugLog(@"filePath filePath %@", filePath);
        [self.bridge.eventDispatcher sendDeviceEventWithName:@"takePhotoFinishData"
                                                        body:@{@"name": filePath}];
        [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:@""]]];
    } else {
        // show ERROR alert or something
    }
}

static const int TextHeight = 36;
- (UIImage*)drawText:(NSString*)text
             inImage:(UIImage*)image
             atPoint:(CGPoint)point{
    UIGraphicsBeginImageContext(image.size);
    [image drawInRect:CGRectMake(0,0,image.size.width,image.size.height)];
    
    CGRect rect = CGRectMake(point.x, point.y, image.size.width, TextHeight);
    [[UIColor colorWithRed:51/255.0 green:102/255.0 blue:204/255.0 alpha:0.8] set];
    CGContextFillRect(UIGraphicsGetCurrentContext(),rect);
    
    UIColor *textColor = [UIColor whiteColor];
    UIFont *font = [UIFont boldSystemFontOfSize:28];
    // center align
    NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
    paragraphStyle.alignment                = NSTextAlignmentCenter;
    NSDictionary *att = @{NSFontAttributeName:font, NSForegroundColorAttributeName:textColor,
                          NSParagraphStyleAttributeName:paragraphStyle};
    
    [text drawInRect:rect withAttributes:att];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

@end