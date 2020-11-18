//
//  ZegoBeautyCamera.h
//  Pods
//
//  Created by lizhanpeng@ZEGO on 2020/9/16.
//

#ifndef ZegoBeautyCamera_h
#define ZegoBeautyCamera_h

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
// #import <zego_express_engine/ZegoCustomVideoCaptureManager.h>

@interface ZegoBeautyCamera : NSObject

+ (void)setup;

// switch camera(front or back)
- (BOOL)switchCamera:(AVCaptureDevicePosition)position;

// set the framerate of camera
- (void)setCameraFrameRate:(int)framerate;

// == set beauty param(begin) ==
- (void)setWhitenParam:(double)whiten;

- (void)setRedParam:(double)red;

- (void)setBlurParam:(double)blur;

- (void)setEnlargingParam:(double)enlarging;

- (void)setThinningParam:(double)thinning;

- (void)setVParam:(double)v;

- (void)setNarrowParam:(double)narrow;

- (void)setSmallParam:(double)small;

- (void)setChinParam:(double)chin;

- (void)setForeheadParam:(double)forehead;

- (void)setNoseParam:(double)nose;

- (void)setMouthParam:(double)mouth;

- (void)resetBeautyOption;

// == set beauty param(end) ==

@end

#endif /* ZegoBeautyCamera_h */
