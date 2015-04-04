//
//  MyCameraView.m
//  SnapChatProject
//
//  Created by Pham Hieu on 3/30/15.
//  Copyright (c) 2015 Facebook. All rights reserved.
//

#import "MyCameraView.h"

#import "Utility.h"

@implementation MyCameraView{
    AVCaptureStillImageOutput   *_stillImageOutput;
    AVCaptureSession            *captureSession;
    
    AVCaptureDevice             *cameraDevice;
}

#pragma mark - Util

+ (BOOL)doesSupportFlashLight:(CameraType)cameraType{
    AVCaptureDevicePosition devicePosition = AVCaptureDevicePositionBack;
    if (cameraType == CameraTypeFront) devicePosition = AVCaptureDevicePositionFront;
    
    for (AVCaptureDevice *_device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if (_device.position == devicePosition) {
            return [_device hasFlash];
        }
    }
    
    return NO;
}

#pragma mark - Init

- (id)init{
    if ((self = [super initWithFrame:(CGRect){0,0,320,320}])){
        //NSLog(@"[self getAvailableFrame] = %@", NSStringFromCGRect([self getAvailableFrame]));
        //NSLog(@"cameraType = %lu", _cameraType);
        
        AVCaptureDevice *device = [self getCameraDevice:AVCaptureDevicePositionFront];
        cameraDevice = device;
        if (device){
            [self showLiveCameraPreview:device];
        } //else [self showAlertWithTitle:@"No Camera" andMessage:@"Sorry, your device has no camera."];
    }
    return self;
}

- (void)showLiveCameraPreview:(AVCaptureDevice*)_device{
    NSLog(@"self.layer %@  self.bounds: %@", self.layer, NSStringFromCGRect(self.bounds));
    //----- SHOW LIVE CAMERA PREVIEW -----
    captureSession = [[AVCaptureSession alloc] init];
    captureSession.sessionPreset = AVCaptureSessionPresetMedium;
    
    // create image output object
    NSDictionary *outputSettings = @{AVVideoCodecKey:AVVideoCodecJPEG};
    _stillImageOutput = [AVCaptureStillImageOutput new];
    _stillImageOutput.outputSettings = outputSettings;
    [captureSession addOutput:_stillImageOutput];
    
    AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:captureSession];
    captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    captureVideoPreviewLayer.frame = self.bounds;
    [self.layer addSublayer:captureVideoPreviewLayer];
    
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:_device error:&error];
    if (!input) {
        // Handle the error appropriately.
        NSLog(@"ERROR: trying to open camera: %@", error);
    }
    [captureSession addInput:input];
    [captureSession startRunning];
}

- (void)toggleCamera:(CameraType)camType{
    AVCaptureDevice *_device;
    if(camType == CameraTypeFront){
        _device = [self getCameraDevice:AVCaptureDevicePositionFront];
        
    } else {
        _device = [self getCameraDevice:AVCaptureDevicePositionBack];
    }
    
    if (!_device) {
        return;
    } else {
        cameraDevice = _device;
        
        AVCaptureDeviceInput *oldInput = [captureSession.inputs lastObject];
        AVCaptureDeviceInput *newInput = [AVCaptureDeviceInput deviceInputWithDevice:_device
                                                                               error:nil];
        [captureSession beginConfiguration];
        [captureSession removeInput:oldInput];
        [captureSession addInput:newInput];
        [captureSession commitConfiguration];
    }
}

- (void)toggleFlashlight:(FlashType)_flashMode
{
    if([cameraDevice hasFlash]){
        // Start session configuration
        [captureSession beginConfiguration];
        [cameraDevice lockForConfiguration:nil];
        
        // Set torch to on
        [cameraDevice setFlashMode:[self convertFlashType:_flashMode]];
        
        [cameraDevice unlockForConfiguration];
        [captureSession commitConfiguration];
        
        // Start the session
        [captureSession startRunning];
    }
}

// Reference: https://github.com/IFTTT/FastttCamera
- (void)takePhoto{
    AVCaptureConnection *videoConnection = nil;
    
    for (AVCaptureConnection *connection in [_stillImageOutput connections]) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                videoConnection = connection;
                break;
            }
        }
        
        if (videoConnection) {
            break;
        }
    }
    
    if ([videoConnection isVideoOrientationSupported]) {
        [videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    }
    
    if ([videoConnection isVideoMirroringSupported]) {
        [videoConnection setVideoMirrored:[self doesVideoMirrored]];
    }
#if TARGET_IPHONE_SIMULATOR
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIImage *fakeImage = [UIImage imageNamed:@"fakeCaptureImage.png"];
        BOOL saveSuccessfully = [self saveImageToFile:fakeImage];
        // notify take photo finish
        [[NSNotificationCenter defaultCenter] postNotificationName:TAKE_PHOTO_FINISH
                                                            object:[NSNumber numberWithBool:saveSuccessfully]];
    });
#else
    [_stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:
     ^(CMSampleBufferRef imageDataSampleBuffer, NSError *error){
           if (!imageDataSampleBuffer) return;
        
           NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
         
           dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
               UIImage *image = [UIImage imageWithData:imageData];
               [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
                   UIImage *cropped = [self scaleAndCropImage:image];
                   BOOL saveSuccessfully = [self saveImageToFile:cropped];
                   // notify take photo finish
                   [[NSNotificationCenter defaultCenter] postNotificationName:TAKE_PHOTO_FINISH
                                                                       object:[NSNumber numberWithBool:saveSuccessfully]];
               }];
           });
       }];
#endif
}

- (BOOL)saveImageToFile:(UIImage*)image{
    // Create path.
    NSString *filePath = [Utility getDocumentFilePath:PHOTO_NAME];
    
    // Save image.
    return [UIImageJPEGRepresentation(image, 100) writeToFile:filePath atomically:YES];
}

#pragma mark - Image Utils

const CGSize expectedSize = (CGSize){640, 640};

- (UIImage *)scaleAndCropImage:(UIImage *)imageToCrop
{
    float scaleRatio =  expectedSize.width / imageToCrop.size.width;
    CGSize scaleSize = (CGSize){expectedSize.width, imageToCrop.size.height * scaleRatio};
    UIImage *scaleImage = [self imageWithImage:imageToCrop scaledToSize:scaleSize];
    CGRect rect = (CGRect){0, (scaleImage.size.height - expectedSize.height)/2, expectedSize.width, expectedSize.height};
    CGImageRef imageRef = CGImageCreateWithImageInRect([scaleImage CGImage], rect);
    UIImage *cropped = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return cropped;
}

- (UIImage*)imageWithImage:(UIImage *)image
              scaledToSize:(CGSize)newSize{
    float heightToWidthRatio = image.size.height / image.size.width;
    float scaleFactor = 1;
    if(heightToWidthRatio > 0) {
        scaleFactor = newSize.height / image.size.height;
    } else {
        scaleFactor = newSize.width / image.size.width;
    }
    
    CGSize newSize2 = newSize;
    newSize2.width = image.size.width * scaleFactor;
    newSize2.height = image.size.height * scaleFactor;
    
    UIGraphicsBeginImageContext(newSize2);
    [image drawInRect:CGRectMake(0,0,newSize2.width,newSize2.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

#pragma mark - Helper

- (AVCaptureFlashMode)convertFlashType:(FlashType)type{
    switch (type) {
        case FlashAuto:
            return AVCaptureFlashModeAuto;
            break;
        case FlashOn:
            return AVCaptureFlashModeOn;
            break;
        default:
            return AVCaptureFlashModeOff;
            break;
    }
}

- (BOOL)doesVideoMirrored{
    if(cameraDevice.position == AVCaptureDevicePositionBack){ // camera back doesn't need to mirror
        return NO;
    }
    // set mirror
    return YES;
}

- (AVCaptureDevice*)getCameraDevice:(AVCaptureDevicePosition)devicePosition{
    for (AVCaptureDevice *_device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if (_device.position == devicePosition) {
            return _device;
        }
    }
    return nil;
}

- (void)showAlertWithTitle:(NSString*)title andMessage:(NSString*)message{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"Dismiss"
                                              otherButtonTitles:nil, nil];
    [alertView show];
}

@end
