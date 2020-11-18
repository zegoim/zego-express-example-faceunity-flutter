import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'utils/zego_config.dart';

import 'package:zego_faceunity_plugin_example/beauty_camera_init_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZegoFaceUnityPluginExample',
      theme: ThemeData(

        primarySwatch: Colors.blue,
      ),
      home: HomePage()
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  void initState() {
    super.initState();
    // Load config
    ZegoConfig.instance.init();
  }

  void onEnterBeautyCameraPagePressed() {
    Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) {
        return BeautyCameraInitPage();
      }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ZegoFaceUnityExample'),
      ),
      body: SafeArea(
        child: Center(
          child: CupertinoButton(
            color: Color(0xff0e88eb),
            child: Text('Beauty Camera'),
            onPressed: onEnterBeautyCameraPagePressed
          ),
        )
      )
    );
  }
}