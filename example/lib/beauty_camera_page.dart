import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'dart:core';
import 'package:flutter/services.dart';

import 'package:zego_faceunity_plugin/zego_faceunity_plugin.dart';

import 'package:zego_express_engine/zego_express_engine.dart';

import 'package:zego_faceunity_plugin_example/utils/zego_config.dart';

class BeautyCameraPage extends StatefulWidget {

  final int screenWidthPx;
  final int screenHeightPx;

  BeautyCameraPage(this.screenWidthPx, this.screenHeightPx);

  @override
  _BeautyCameraPageState createState() => new _BeautyCameraPageState();
}

class _BeautyCameraPageState extends State<BeautyCameraPage> {

  String _title = 'Step3 StartPublishing';
  String _streamID = 's-beauty-camera';

  bool _isPublishing = false;

  int _previewViewID = -1;
  Widget _previewViewWidget;
  ZegoCanvas _previewCanvas;

  int _publishWidth = 0;
  int _publishHeight = 0;
  double _publishCaptureFPS = 0.0;
  double _publishEncodeFPS = 0.0;
  double _publishSendFPS = 0.0;
  double _publishVideoBitrate = 0.0;
  double _publishAudioBitrate = 0.0;
  bool _isHardwareEncode = false;
  String _networkQuality = '';

  bool _isUseMic = true;
  bool _isUseFrontCamera = true;

  TextEditingController _controller = new TextEditingController();

  List<Map<String, dynamic>> beautyParamList = [
    {
      'name': '美白',
      'value': 1.0,
      'min': 0.0,
      'max': 2.0
    },
    {
      'name': '红润',
      'value': 0.5,
      'min': 0.0,
      'max': 2.0
    },
    {
      'name': '磨皮',
      'value': 4.2,
      'min': 0.0,
      'max': 6.0
    },
    {
      'name': '大眼',
      'value': 0.4,
      'min': 0.0,
      'max': 1.0
    },
    {
      'name': '瘦脸',
      'value': 0.0,
      'min': 0.0,
      'max': 1.0
    },
    {
      'name': 'V脸',
      'value': 0.5,
      'min': 0.0,
      'max': 1.0
    },
    {
      'name': '窄脸',
      'value': 0.0,
      'min': 0.0,
      'max': 1.0
    },
    {
      'name': '小脸',
      'value': 0.0,
      'min': 0.0,
      'max': 1.0
    },
    {
      'name': '下巴',
      'value': 0.3,
      'min': 0.0,
      'max': 1.0
    },
    {
      'name': '额头',
      'value': 0.3,
      'min': 0.0,
      'max': 1.0
    },
    {
      'name': '鼻子',
      'value': 0.5,
      'min': 0.0,
      'max': 1.0
    },
    {
      'name': '嘴型',
      'value': 0.4,
      'min': 0.0,
      'max': 1.0
    },
  ];

  @override
  void initState() {
    super.initState();

    if (ZegoConfig.instance.streamID.isNotEmpty) {
      _controller.text = ZegoConfig.instance.streamID;
    }

    ZegoFaceunityPlugin.instance.setCustomVideoCaptureSource(ZegoCustomSourceType.Camera);

    ZegoExpressEngine.instance.enableCustomVideoCapture(true);

    setPublisherCallback();

    if (ZegoConfig.instance.enablePlatformView) {

      setState(() {
        // Create a PlatformView Widget
        _previewViewWidget = ZegoExpressEngine.instance.createPlatformView((viewID) {

          _previewViewID = viewID;

          // Start preview using platform view
          startPreview(viewID);

        });
      });

    } else {

      // Create a Texture Renderer
      ZegoExpressEngine.instance.createTextureRenderer(widget.screenWidthPx, widget.screenHeightPx).then((textureID) {

        _previewViewID = textureID;

        setState(() {
          // Create a Texture Widget
          _previewViewWidget = Texture(textureId: textureID);
        });

        // Start preview using texture renderer
        startPreview(textureID);
      });
    }
  }

  void setPublisherCallback() {

    // Set the publisher state callback
    ZegoExpressEngine.onPublisherStateUpdate = (String streamID, ZegoPublisherState state, int errorCode, Map<String, dynamic> extendedData) {

      if (errorCode == 0) {
        setState(() {
          _isPublishing = true;
          _title = 'Publishing';
        });

        ZegoConfig.instance.streamID = streamID;
        ZegoConfig.instance.saveConfig();

      } else {
        print('Publish error: $errorCode');
      }
    };

    // Set the publisher quality callback
    ZegoExpressEngine.onPublisherQualityUpdate = (String streamID, ZegoPublishStreamQuality quality) {

      setState(() {
        _publishCaptureFPS = quality.videoCaptureFPS;
        _publishEncodeFPS = quality.videoEncodeFPS;
        _publishSendFPS = quality.videoSendFPS;
        _publishVideoBitrate = quality.videoKBPS;
        _publishAudioBitrate = quality.audioKBPS;
        _isHardwareEncode = quality.isHardwareEncode;

        switch (quality.level) {
          case ZegoStreamQualityLevel.Excellent:
            _networkQuality = '☀️';
            break;
          case ZegoStreamQualityLevel.Good:
            _networkQuality = '⛅️️';
            break;
          case ZegoStreamQualityLevel.Medium:
            _networkQuality = '☁️';
            break;
          case ZegoStreamQualityLevel.Bad:
            _networkQuality = '🌧';
            break;
          case ZegoStreamQualityLevel.Die:
            _networkQuality = '❌';
            break;
          default:
            break;
        }
      });
    };

    // Set the publisher video size changed callback
    ZegoExpressEngine.onPublisherVideoSizeChanged = (int width, int height, ZegoPublishChannel channel) {
      setState(() {
        _publishWidth = width;
        _publishHeight = height;
      });
    };
  }

  void startPreview(int viewID) {

    // Set the preview canvas
    _previewCanvas =  ZegoCanvas.view(viewID);

    // Start preview
    ZegoExpressEngine.instance.startPreview(canvas: _previewCanvas);
  }

  @override
  void dispose() {
    super.dispose();

    if (_isPublishing) {
      // Stop publishing
      ZegoExpressEngine.instance.stopPublishingStream();
    }

    // Stop preview
    ZegoExpressEngine.instance.stopPreview();

    // Unregister publisher callback
    ZegoExpressEngine.onPublisherStateUpdate = null;
    ZegoExpressEngine.onPublisherQualityUpdate = null;
    ZegoExpressEngine.onPublisherVideoSizeChanged = null;

    if (ZegoConfig.instance.enablePlatformView) {
      // Destroy preview platform view
      ZegoExpressEngine.instance.destroyPlatformView(_previewViewID);
    } else {
      // Destroy preview texture renderer
      ZegoExpressEngine.instance.destroyTextureRenderer(_previewViewID);
    }

    // Logout room
    ZegoExpressEngine.instance.logoutRoom(ZegoConfig.instance.roomID);

    ZegoFaceunityPlugin.instance.removeCustomVideoCaptureSource();

    ZegoExpressEngine.instance.enableCustomVideoCapture(false);
  }

  void onPublishButtonPressed() {

    _streamID = _controller.text.trim();

    // Start publishing stream
    ZegoExpressEngine.instance.startPublishingStream(_streamID);

  }

  void onCamStateChanged() {

    _isUseFrontCamera = !_isUseFrontCamera;
    //ZegoExpressEngine.instance.useFrontCamera(_isUseFrontCamera);
    ZegoFaceunityPlugin.instance.switchCamera(_isUseFrontCamera ? ZegoCameraPosition.Front : ZegoCameraPosition.Back);
  }

  void onMicStateChanged() {

    setState(() {
      _isUseMic = !_isUseMic;
      ZegoExpressEngine.instance.muteMicrophone(!_isUseMic);
    });
  }

  void onVideoMirroModeChanged(int mode) {
    //ZegoExpressEngine.instance.setVideoMirrorMode(ZegoVideoMirrorMode.values[mode]);
  }

  void setBeautyOption(int index) {
    print('cureent value: ${beautyParamList[index]['value']}');
    switch(beautyParamList[index]['name']) {
      case '美白':
        ZegoFaceunityPlugin.instance.setBeautyOption(faceWhiten: beautyParamList[index]['value']);
        break;
      case '红润':
        ZegoFaceunityPlugin.instance.setBeautyOption(faceRed: beautyParamList[index]['value']);
        break;
      case '磨皮':
        ZegoFaceunityPlugin.instance.setBeautyOption(faceBlur: beautyParamList[index]['value']);
        break;
      case '大眼':
        ZegoFaceunityPlugin.instance.setBeautyOption(eyeEnlarging: beautyParamList[index]['value']);
        break;
      case '瘦脸':
        ZegoFaceunityPlugin.instance.setBeautyOption(cheekThinning: beautyParamList[index]['value']);
        break;
      case 'V脸':
        ZegoFaceunityPlugin.instance.setBeautyOption(cheekV: beautyParamList[index]['value']);
        break;
      case '窄脸':
        ZegoFaceunityPlugin.instance.setBeautyOption(cheekNarrow: beautyParamList[index]['value']);
        break;
      case '小脸':
        ZegoFaceunityPlugin.instance.setBeautyOption(cheekSmall: beautyParamList[index]['value']);
        break;
      case '下巴':
        ZegoFaceunityPlugin.instance.setBeautyOption(chinLevel: beautyParamList[index]['value']);
        break;
      case '额头':
        ZegoFaceunityPlugin.instance.setBeautyOption(foreHeadLevel: beautyParamList[index]['value']);
        break;
      case '鼻子':
        ZegoFaceunityPlugin.instance.setBeautyOption(noseLevel: beautyParamList[index]['value']);
        break;
      case '嘴型':
        ZegoFaceunityPlugin.instance.setBeautyOption(mouthLevel: beautyParamList[index]['value']);
        break;
    }
  }


  Widget showPreviewToolPage() {
    return GestureDetector(

      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).requestFocus(new FocusNode()),

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 50.0),
            ),
            Row(
              children: <Widget>[
                Text('StreamID: ',
                  style: TextStyle(
                      color: Colors.white
                  ),
                )
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
            ),
            TextField(
              controller: _controller,
              style: TextStyle(
                  color: Colors.white
              ),
              decoration: InputDecoration(
                  contentPadding: const EdgeInsets.only(left: 10.0, top: 12.0, bottom: 12.0),
                  hintText: 'Please enter streamID',
                  hintStyle: TextStyle(
                      color: Color.fromRGBO(255, 255, 255, 0.8)
                  ),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Colors.white
                      )
                  ),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Color(0xff0e88eb)
                      )
                  )
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
            ),
            Text(
              'StreamID must be globally unique and the length should not exceed 255 bytes',
              style: TextStyle(
                  color: Colors.white
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 30.0),
            ),
            Container(
              padding: const EdgeInsets.all(0.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                color: Color(0xee0e88eb),
              ),
              width: 240.0,
              height: 60.0,
              child: CupertinoButton(
                child: Text('Start Publishing',
                  style: TextStyle(
                      color: Colors.white
                  ),
                ),
                onPressed: onPublishButtonPressed,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget showPublishingToolPage() {
    return Container(
      padding: EdgeInsets.only(left: 10.0, right: 10.0, bottom: MediaQuery.of(context).padding.bottom + 20.0),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
          ),
          Row(
            children: <Widget>[
              Text('RoomID: ${ZegoConfig.instance.roomID} |  StreamID: ${ZegoConfig.instance.streamID}',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 9
                ),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              Text('Rendering with: ${ZegoConfig.instance.enablePlatformView ? 'PlatformView' : 'TextureRenderer'}',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 9
                ),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              Text('Resolution: $_publishWidth x $_publishHeight',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 9
                ),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              Text('FPS(Capture): ${_publishCaptureFPS.toStringAsFixed(2)}',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 9
                ),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              Text('FPS(Encode): ${_publishEncodeFPS.toStringAsFixed(2)}',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 9
                ),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              Text('FPS(Send): ${_publishSendFPS.toStringAsFixed(2)}',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 9
                ),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              Text('Bitrate(Video): ${_publishVideoBitrate.toStringAsFixed(2)} kb/s',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 9
                ),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              Text('Bitrate(Audio): ${_publishAudioBitrate.toStringAsFixed(2)} kb/s',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 9
                ),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              Text('HardwareEncode: ${_isHardwareEncode ? '✅' : '❎'}',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 9
                ),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              Text('NetworkQuality: $_networkQuality',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 9
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(padding: const EdgeInsets.only(top: 10.0)),
          ),
          Row(
            children: <Widget>[
              CupertinoButton(
                padding: const EdgeInsets.all(0.0),
                pressedOpacity: 1.0,
                borderRadius: BorderRadius.circular(
                    0.0),
                // child: Image(
                //   width: 44.0,
                //   image: ImageIcon
                // ),
                child: Icon(
                  Icons.switch_camera,
                  size: 44.0,
                  color: Colors.white,
                ),
                onPressed: onCamStateChanged,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10.0),
              ),
              CupertinoButton(
                padding: const EdgeInsets.all(0.0),
                pressedOpacity: 1.0,
                borderRadius: BorderRadius.circular(
                    0.0),
                child: Icon(
                  _isUseMic ? Icons.mic_none : Icons.mic_off,
                  size: 44.0,
                  color: Colors.white,
                ),
                onPressed: onMicStateChanged,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10.0),
              )
            ],
          ),
        ],
      ),
    );
  }

  void showBottomSettingPage() {
    showModalBottomSheet<void>(
      barrierColor: Color.fromRGBO(0, 0, 0, 0.1),
      backgroundColor: Colors.transparent,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context1, setBottomSheetState) {
            return Container(
              height: 200.0,
              padding: EdgeInsets.all(20),
              color: Color.fromRGBO(0, 0, 0, 0.8),
              child: ListView.builder(
                itemCount: beautyParamList.length,
                itemBuilder: (BuildContext context, int index) {
                  return Row(
                    children: [
                      Text(beautyParamList[index]['name'], style: TextStyle(color: Colors.white),),
                      Expanded(
                        child: CupertinoSlider(
                          value: beautyParamList[index]['value'],
                          min: beautyParamList[index]['min'],
                          max: beautyParamList[index]['max'],
                          divisions: 20,
                          onChanged: (value) {
                            setBottomSheetState(() {
                              //print("current value: $value");
                              beautyParamList[index]['value'] = value;
                              setBeautyOption(index);
                            });
                          },
                        ),
                      )
                    ],
                  );
                },
              )
            );
          },
        );
      },
    );
  }
  void onSettingsButtonClicked() {
    /*Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) {
      return PublishSettingsPage();
    },fullscreenDialog: true));*/
      //_isUseFrontCamera = !_isUseFrontCamera;
      //ZegoLiveUtils.instance.switchCamera(_isUseFrontCamera ? ZegoCameraPosition.Front : ZegoCameraPosition.Back);
    showBottomSettingPage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text(_title),
        ),
        floatingActionButton: CupertinoButton(
            child: Icon(
              Icons.settings,
              size: 44,
              color: Colors.white,
            ),
            onPressed: onSettingsButtonClicked
        ),
        body: Stack(
          children: <Widget>[
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
              child: _previewViewWidget,
            ),
            _isPublishing ? showPublishingToolPage() : showPreviewToolPage(),
          ],
        )
    );
  }

}