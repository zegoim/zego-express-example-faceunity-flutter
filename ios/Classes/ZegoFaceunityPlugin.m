#import "ZegoFaceunityPlugin.h"
#import "ZegoUtils.h"
#import "ZegoBeautyCamera.h"

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
    
      int sourceType = [ZegoUtils intValue:call.arguments[@"sourceType"]];
      
      if(sourceType == 0) {
          [ZegoBeautyCamera setup];
          
          self.camera = [[ZegoBeautyCamera alloc] init];
          
          [[ZegoCustomVideoCaptureManager sharedInstance] setCustomVideoCaptureHandler:self.camera];
      }
      
      result(nil);
      
  } else if([@"removeCustomVideoCaptureSource" isEqualToString:call.method]) {
      
      if(self.camera) {
          self.camera = nil;
      }
      
      
      result(nil);
      
  } else if([@"switchCamera" isEqualToString:call.method]) {
      
      int position = [ZegoUtils intValue:call.arguments[@"position"]];
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
      
      int fps = [ZegoUtils intValue:call.arguments[@"fps"]];
      
      if(self.camera) {
        [self.camera setCameraFrameRate:fps];
      }
      
      result(nil);
      
  } else if([@"setBeautyOption" isEqualToString:call.method]) {
      
      double faceWhiten = [ZegoUtils doubleValue:call.arguments[@"faceWhiten"]];
      double faceRed = [ZegoUtils doubleValue:call.arguments[@"faceRed"]];
      double faceBlur = [ZegoUtils doubleValue:call.arguments[@"faceBlur"]];
      
      double eyeEnlarging = [ZegoUtils doubleValue:call.arguments[@"eyeEnlarging"]];
      
      double cheekThinning = [ZegoUtils doubleValue:call.arguments[@"cheekThinning"]];
      double cheekV = [ZegoUtils doubleValue:call.arguments[@"cheekV"]];
      double cheekNarrow = [ZegoUtils doubleValue:call.arguments[@"cheekNarrow"]];
      double cheekSmall = [ZegoUtils doubleValue:call.arguments[@"cheekSmall"]];
      
      double chinLevel = [ZegoUtils doubleValue:call.arguments[@"chinLevel"]];
      double foreHeadLevel = [ZegoUtils doubleValue:call.arguments[@"foreHeadLevel"]];
      double noseLevel = [ZegoUtils doubleValue:call.arguments[@"noseLevel"]];
      double mouthLevel = [ZegoUtils doubleValue:call.arguments[@"mouthLevel"]];
      
      
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
