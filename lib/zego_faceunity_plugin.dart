
import 'dart:async';

import 'package:flutter/services.dart';

enum ZegoCustomSourceType {
  Camera
}

enum ZegoCameraPosition {
  Front,
  Back
}

class ZegoFaceunityPlugin {
  static const MethodChannel _channel =
      const MethodChannel('zego_faceunity_plugin');

  /// Private constructor
  ZegoFaceunityPlugin._internal();

  static final ZegoFaceunityPlugin instance = ZegoFaceunityPlugin._internal();

  Future<void> setCustomVideoCaptureSource(ZegoCustomSourceType sourceType) async {
    return await _channel.invokeMethod('setCustomVideoCaptureSource', {
      'sourceType': sourceType.index
    });
  }

  Future<void> removeCustomVideoCaptureSource() async {
    return await _channel.invokeMethod('removeCustomVideoCaptureSource');
  }

  Future<void> setCameraFrameRate(int fps) async {
    return await _channel.invokeMethod('setCameraFrameRate', {
      'fps': fps
    });
  }

  Future<bool> switchCamera(ZegoCameraPosition position) async {
    return await _channel.invokeMethod('switchCamera', {
      'position': position.index
    });
  }

  Future<void> setBeautyOption({
    double faceWhiten,
    double faceRed,
    double faceBlur,
    double eyeEnlarging,
    double cheekThinning,
    double cheekV,
    double cheekNarrow,
    double cheekSmall,
    double chinLevel,
    double foreHeadLevel,
    double noseLevel,
    double mouthLevel
  }) async {
    return await _channel.invokeMethod('setBeautyOption', {
      'faceWhiten': faceWhiten??-1.0,
      'faceRed': faceRed??-1.0,
      'faceBlur': faceBlur??-1.0,
      'eyeEnlarging': eyeEnlarging??-1.0,
      'cheekThinning': cheekThinning??-1.0,
      'cheekV': cheekV??-1.0,
      'cheekNarrow': cheekNarrow??-1.0,
      'cheekSmall': cheekSmall??-1.0,
      'chinLevel': chinLevel??-1.0,
      'foreHeadLevel': foreHeadLevel??-1.0,
      'noseLevel': noseLevel??-1.0,
      'mouthLevel': mouthLevel??-1.0
    });
  }
}
