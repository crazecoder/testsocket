import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bugly/flutter_bugly.dart';
import 'ui/home.dart';
import 'constant.dart';
import 'theme.dart';
import 'utils/prefs_util.dart';

void main() {
  debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  FlutterBugly.postCatchedException(() {
    runApp(MyApp());
  });
}

class MyApp extends StatefulWidget {
  MyApp() {
    FlutterBugly.init(
      androidAppId: "2a7d4fd48b",
//      iOSAppId: "",
//      autoDownloadOnWifi: true,
      enableNotification: true,
    );
  }

  @override
  State<StatefulWidget> createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDark = false;

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: ConstantValue.APP_NAME,
      debugShowCheckedModeBanner: ConstantValue.DEBUG,
      theme: _isDark
          ? CustomTheme.buildDarkTheme()
          : CustomTheme.buildLightTheme(),
      home: new MyHomePage(
        title: ConstantValue.APP_NAME,
        themeType: _isDark,
        changeTheme: (_b) {
          setState(() {
            _isDark = _b;
          });
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    PrefsUtil.isDark().then((_b) {
      setState(() {
        _isDark = _b ?? false;
      });
    });
  }
}
