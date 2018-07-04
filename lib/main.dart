import 'package:flutter/material.dart';
import 'ui/home.dart';
import 'constant.dart';
import 'theme.dart';
import 'utils/prefs_util.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
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
