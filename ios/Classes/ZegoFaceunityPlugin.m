#import "ZegoFaceunityPlugin.h"
#import "ZegoFaceUnityUtils.h"
#import "ZegoBeautyCamera.h"
#import <objc/message.h>

@interface ZegoFaceunityPlugin()

@property (nonatomic, strong) ZegoBeautyCamera *camera;

@end

@implementation ZegoFaceunityPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"zego_faceunity_plugin"
            binaryMessenger:[registrar messenger]];
  ZegoFaceunityPlugin* instance = [[ZegoFaceunityPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {

  if ([@"setCustomVideoCaptureSource" isEqualToString:call.method]) {

      int sourceType = [ZegoFaceUnityUtils intValue:call.arguments[@"sourceType"]];

      if(sourceType == 0) {
          [ZegoBeautyCamera setup];

          self.camera = [[ZegoBeautyCamera alloc] init];

          // [[ZegoCustomVideoCaptureManager sharedInstance] setCustomVideoCaptureHandler:self.camera];
          // 走 runtime 解决 Swift 动态库工程无法 import 其他库的问题

          Class managerClass = NSClassFromString(@"ZegoCustomVideoCaptureManager");
          SEL managerSelector = NSSelectorFromString(@"sharedInstance");
          id sharedManager = ((id (*)(id, SEL))objc_msgSend)(managerClass, managerSelector);

          SEL setCustomVideoCaptureHandlerSelector = NSSelectorFromString(@"setCustomVideoCaptureHandler:");
          ((void (*)(id, SEL, id))objc_msgSend)(sharedManager, setCustomVideoCaptureHandlerSelector, self.camera);
      }

      result(nil);

  } else if([@"removeCustomVideoCaptureSource" isEqualToString:call.method]) {

      if(self.camera) {
          self.camera = nil;
      }


      result(nil);

  } else if([@"switchCamera" isEqualToString:call.method]) {

      int position = [ZegoFaceUnityUtils intValue:call.arguments[@"position"]];
      AVCaptureDevicePosition pos = AVCaptureDevicePositionUnspecified;
      switch (position) {
          case 0:
              pos = AVCaptureDevicePositionFront;
              break;
          case 1:
              pos = AVCaptureDevicePositionBack;
          default:
              break;
      }
      BOOL ret = self.camera ? [self.camera switchCamera:pos] : NO;

      result(@(ret));

  } else if([@"setCameraFrameRate" isEqualToString:call.method]) {

      int fps = [ZegoFaceUnityUtils intValue:call.arguments[@"fps"]];

      if(self.camera) {
        [self.camera setCameraFrameRate:fps];
      }

      result(nil);

  } else if([@"setBeautyOption" isEqualToString:call.method]) {

      double faceWhiten = [ZegoFaceUnityUtils doubleValue:call.arguments[@"faceWhiten"]];
      double faceRed = [ZegoFaceUnityUtils doubleValue:call.arguments[@"faceRed"]];
      double faceBlur = [ZegoFaceUnityUtils doubleValue:call.arguments[@"faceBlur"]];

      double eyeEnlarging = [ZegoFaceUnityUtils doubleValue:call.arguments[@"eyeEnlarging"]];

      double cheekThinning = [ZegoFaceUnityUtils doubleValue:call.arguments[@"cheekThinning"]];
      double cheekV = [ZegoFaceUnityUtils doubleValue:call.arguments[@"cheekV"]];
      double cheekNarrow = [ZegoFaceUnityUtils doubleValue:call.arguments[@"cheekNarrow"]];
      double cheekSmall = [ZegoFaceUnityUtils doubleValue:call.arguments[@"cheekSmall"]];

      double chinLevel = [ZegoFaceUnityUtils doubleValue:call.arguments[@"chinLevel"]];
      double foreHeadLevel = [ZegoFaceUnityUtils doubleValue:call.arguments[@"foreHeadLevel"]];
      double noseLevel = [ZegoFaceUnityUtils doubleValue:call.arguments[@"noseLevel"]];
      double mouthLevel = [ZegoFaceUnityUtils doubleValue:call.arguments[@"mouthLevel"]];


      if(self.camera) {
          if(faceWhiten >= 0) {
              [self.camera setWhitenParam:faceWhiten];
          }

          if(faceRed >= 0) {
              [self.camera setRedParam:faceRed];
          }

          if(faceBlur >= 0) {
              [self.camera setBlurParam:faceBlur];
          }

          if(eyeEnlarging >= 0) {
              [self.camera setEnlargingParam:eyeEnlarging];
          }

          if(cheekThinning >= 0) {
              [self.camera setThinningParam:cheekThinning];
          }

          if(cheekV >= 0) {
              [self.camera setVParam:cheekV];
          }

          if(cheekNarrow >= 0) {
              [self.camera setNarrowParam:cheekNarrow];
          }

          if(cheekSmall >= 0) {
              [self.camera setSmallParam:cheekSmall];
          }

          if(chinLevel >= 0) {
              [self.camera setChinParam:chinLevel];
          }

          if(foreHeadLevel >= 0) {
              [self.camera setForeheadParam:foreHeadLevel];
          }

          if(noseLevel >= 0) {
              [self.camera setNoseParam:noseLevel];
          }

          if(mouthLevel >= 0) {
              [self.camera setMouthParam:mouthLevel];
          }
      }

      result(nil);

  } else {
    result(FlutterMethodNotImplemented);
  }
}

@end
