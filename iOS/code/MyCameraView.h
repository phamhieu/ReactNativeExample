//
//  MyCameraView.h
//  SnapChatProject
//
//  Created by Pham Hieu on 3/30/15.
//  Copyright (c) 2015 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#define TAKE_PHOTO_FINISH       @"TAKE_PHOTO_FINISH"
#define PHOTO_NAME              @"Snap_Chat_Image.png"

typedef enum : NSUInteger {
    CameraTypeFront = 0,
    CameraTypeBack,
} CameraType;

typedef enum : NSUInteger {
    FlashAuto = 0,
    FlashOn,
    FlashOff
} FlashType;

@interface MyCameraView : UIView

+ (BOOL)doesSupportFlashLight:(CameraType)cameraType;

- (void)toggleCamera:(CameraType)camType;
- (void)toggleFlashlight:(FlashType)_flashMode;
- (void)takePhoto;

@end
