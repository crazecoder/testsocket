import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
import 'package:url_launcher/url_launcher.dart';

import '../logic/home_logic.dart';
import '../ui/home.dart';
import '../utils/print_util.dart';

abstract class HomePresenterImpl {
  void start();

  void stop();

  void sendMessage(String text);

  void downloadApk();

  void pickImage(int type);

  void launchUrl(url);

  void saveTheme(bool isDark);
}

class HomePresenter extends HomePresenterImpl {
  HomeLogic _logic;
  HomePageImpl _view;
  var _newVersionName;

  HomePresenter(this._view) {
    _logic = new HomeLogic();
  }

  @override
  void start() async {
    _logic.initPlatformState();
    _start();
    if (Platform.isAndroid) {
      PackageInfo.fromPlatform().then((info) {
        _logic.getApkVersion().then((data) {
          log(info.buildNumber);
          if (int.parse(info.buildNumber) < data["versionCode"]) {
            _newVersionName = data["versionName"];
            _view.showUpdateDialog(_newVersionName);
          }
        });
      });
    }
  }

  String getDeviceName() {
    return _logic.deviceInfo;
  }

  void _start() async {
    await _logic.connectAndListen(
        onServerError: () => _view.showSnackBar("服务器未开启"),
        onReceiver: (message) => _view.receiverMessage(
            message, message.id != _logic.getConnectTimeMills()),
        onError: () => _view.showSnackBar("连接失败，请重新启动"),
        onDone: () => _view.showSnackBar("连接已断开，请检查网络后重新启动"));
  }

  @override
  void stop() {
    _logic.disConnectSocket();
  }

  @override
  void sendMessage(String text) {
    _logic.sendMessage(text, error: () => _view.showSnackBar("消息发送失败，服务器未开启"));
  }

  @override
  void downloadApk() {
    _logic.downloadApk((_received, _total) {
      _view.showDownloadProgress(_received / _total);
    });
  }

  @override
  void pickImage(int type) {
    double width = MediaQuery.of(_view.getContext()).size.width;
    var widthStr = "$width".split(".").elementAt(0);
    _logic.getImage(type, int.parse(widthStr), () {
      _view.showSnackBar("图片可能过大，请重试");
    });
  }

  @override
  void launchUrl(url) async {
    print(url);
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  void saveTheme(bool isDark) {
    _logic.saveThemeType(isDark);
  }
}
