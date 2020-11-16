package im.zego.zego_faceunity_plugin;

import android.content.Context;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;


import im.zego.zego_express_engine.internal.ZegoUtils;
import im.zego.zego_express_engine.ZegoCustomVideoCaptureManager;

/** ZegoFaceunityPlugin */
public class ZegoFaceunityPlugin implements FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;
  private Context mContext;
  private ZegoBeautyCamera mCamera;

  void setFlutterContext(Context context) {
    mContext = context;
  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor(), "zego_faceunity_plugin");
    channel.setMethodCallHandler(this);

    Context appContext = flutterPluginBinding.getApplicationContext();
    this.setFlutterContext(appContext);
  }

  // This static function is optional and equivalent to onAttachedToEngine. It supports the old
  // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
  // plugin registration via this function while apps migrate to use the new Android APIs
  // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
  //
  // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
  // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
  // depending on the user's project. onAttachedToEngine or registerWith must both be defined
  // in the same class.
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "zego_faceunity_plugin");
    ZegoFaceunityPlugin plugin = new ZegoFaceunityPlugin();
    plugin.setFlutterContext(registrar.context());
    channel.setMethodCallHandler(new ZegoFaceunityPlugin());
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals("setCustomVideoCaptureSource")) {
      int sourceType = ZegoUtils.intValue((Number) call.argument("sourceType"));
      if(sourceType == 0) {
        ZegoBeautyCamera.setup(mContext);

        mCamera = new ZegoBeautyCamera(mContext);
        ZegoCustomVideoCaptureManager.getInstance().setCustomVideoCaptureHandler(mCamera);
      }

      result.success(null);
    } else if (call.method.equals("removeCustomVideoCaptureSource")) {

      if(mCamera != null) {
        mCamera = null;
      }

      result.success(null);

    } else if(call.method.equals("switchCamera")) {

      int position = ZegoUtils.intValue((Number) call.argument("position"));
      if(mCamera != null) {
        mCamera.switchCamera(position);
      }

      result.success(null);

    } else if(call.method.equals("setCameraFrameRate")) {

      int fps = ZegoUtils.intValue((Number) call.argument("fps"));
      if(mCamera != null) {
        mCamera.setFrameRate(fps);
      }

      result.success(null);

    } else if(call.method.equals("setBeautyOption")) {

      float faceWhiten = ZegoUtils.floatValue((Number) call.argument("faceWhiten"));
      float faceRed = ZegoUtils.floatValue((Number) call.argument("faceRed"));
      float faceBlur = ZegoUtils.floatValue((Number) call.argument("faceBlur"));

      float eyeEnlarging = ZegoUtils.floatValue((Number) call.argument("eyeEnlarging"));

      float cheekThinning = ZegoUtils.floatValue((Number) call.argument("cheekThinning"));
      float cheekV = ZegoUtils.floatValue((Number) call.argument("cheekV"));
      float cheekNarrow = ZegoUtils.floatValue((Number) call.argument("cheekNarrow"));
      float cheekSmall = ZegoUtils.floatValue((Number) call.argument("cheekSmall"));

      float chinLevel = ZegoUtils.floatValue((Number) call.argument("chinLevel"));
      float foreHeadLevel = ZegoUtils.floatValue((Number) call.argument("foreHeadLevel"));
      float noseLevel = ZegoUtils.floatValue((Number) call.argument("noseLevel"));
      float mouthLevel = ZegoUtils.floatValue((Number) call.argument("mouthLevel"));

      if(mCamera != null) {

        if(faceWhiten >= 0) {
          mCamera.setWhitenParam(faceWhiten);
        }

        if(faceRed >= 0) {
          mCamera.setRedParam(faceRed);
        }

        if(faceBlur >= 0) {
          mCamera.setBlurParam(faceBlur);
        }

        if(eyeEnlarging >= 0) {
          mCamera.setEnlargingParam(eyeEnlarging);
        }

        if(cheekThinning >= 0) {
          mCamera.setThinningParam(cheekThinning);
        }

        if(cheekV >= 0) {
          mCamera.setVParam(cheekV);
        }

        if(cheekNarrow >= 0) {
          mCamera.setNarrowParam(cheekNarrow);
        }

        if(cheekSmall >= 0) {
          mCamera.setSmallParam(cheekSmall);
        }

        if(chinLevel >= 0) {
          mCamera.setChinParam(chinLevel);
        }

        if(foreHeadLevel >= 0) {
          mCamera.setForeheadParam(foreHeadLevel);
        }

        if(noseLevel >= 0) {
          mCamera.setNoseParam(noseLevel);
        }

        if(mouthLevel >= 0) {
          mCamera.setMouthParam(mouthLevel);
        }
      }

      result.success(null);


    } else {
      result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }
}
