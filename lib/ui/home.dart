import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bugly/flutter_bugly.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:toast/toast.dart';
import 'package:connectivity/connectivity.dart';
import '../bean/message.dart' as m;
import '../constant.dart';
import '../presenter/home_presenter.dart';
import '../widget/update_dialog.dart';
import '../widget/message_item.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title, this.themeType, this.changeTheme})
      : super(key: key);

  final String title;
  final Function changeTheme;
  final themeType;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with WidgetsBindingObserver, HomePageImpl, AutomaticKeepAliveClientMixin {
  var _controller = new TextEditingController();
  var _messages = <m.Message>[];
  GlobalKey<ScaffoldState> _key = new GlobalKey();

  var _listController = ScrollController();
  var _count = 0;
  HomePresenter presenter;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  var _isBackground = false;

  GlobalKey<UpdateDialogState> _dialogKey = new GlobalKey();
  var _isDark;
  var subscription;

  @override
  Widget build(BuildContext context) {
    _isDark = widget.themeType ?? false;
    return new Scaffold(
      key: _key,
      appBar: new AppBar(
        actions: <Widget>[
          Container(
            padding: EdgeInsets.only(right: 10),
            child: GestureDetector(
              child:
                  new Icon(_isDark ? Icons.brightness_2 : Icons.brightness_5),
              onTap: () {
                setState(() {
                  _isDark = !_isDark;
                  widget.changeTheme(_isDark);
                });
                presenter.saveTheme(_isDark);
              },
            ),
          ),
        ],
        title: new Text(widget.title),
        centerTitle: true,
        bottom: new PreferredSize(
          preferredSize: Size(0.0, 0.0),
          child: new Text(
            '在线人数：$_count',
            style: TextStyle(color: Theme.of(context).textTheme.body2.color),
          ),
        ),
      ),
      body: new Center(
        child: new Column(
          children: <Widget>[
            new Flexible(
              child: new Container(
                padding: EdgeInsets.only(top: 5.0, bottom: 5.0),
                child: _buildChatMessageList(),
              ),
            ),
            new Divider(
              height: 1.0,
            ),
            _buildBottom(),
          ],
        ),
      ),
    );
  }

  Widget _buildChatMessageList() => new ListView.builder(
      controller: _listController,
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        return MessageItem(
          context,
          scaffoldKey: _key,
          message: _messages[i],
        );
      });

  Widget _buildBottom() => new Container(
        decoration:
            BoxDecoration(color: Theme.of(context).dialogBackgroundColor),
        child: new Row(
          children: <Widget>[
            new Flexible(
              child: new Align(
                child: new Container(
                  padding: EdgeInsets.only(left: 5.0, right: 5.0),
                  child: new TextField(
                    controller: _controller,
                    autofocus: false,
                    autocorrect: false,
                    style: Theme.of(context).textTheme.body1,
                    maxLength: 888,
                    decoration: new InputDecoration(
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
            new IconButton(
              icon: new Icon(Icons.add_circle_outline),
              onPressed: () {
                presenter.pickImage(ConstantValue.GALLERY);
              },
            ),
            new IconButton(
              icon: new Icon(Icons.camera),
              onPressed: () {
                presenter.pickImage(ConstantValue.CAMERA);
              },
            ),
            new CupertinoButton(
                child: new Text(
                  "发送",
                  style: new TextStyle(
                      color: Theme.of(context).textTheme.button.color),
                ),
                onPressed: () {
                  if (_controller.text.trim().length > 0) {
                    presenter.sendMessage(_controller.text);
                    _controller.clear();
                  } else {
                    showSnackBar("请输入有效内容");
                  }
                }),
          ],
        ),
      );

  @override
  void initState() {
    super.initState();
    presenter = new HomePresenter(this);
    FlutterBugly.getUpgradeInfo().then((UpgradeInfo info) {
      if (info != null && info.id != null) {
        showUpdateDialog(info.newFeature, info.apkUrl);
      }
    });
    subscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      result == ConnectivityResult.none
          ? showSnackBar("网络已断开")
          : presenter.reStart(true);
    });
    requestPermission();
    WidgetsBinding.instance.addObserver(this);
    _initNotification();
    presenter.start();
  }

  @override
  void showSnackBar(String text) {
    Toast.show(text, context, backgroundColor: Theme.of(context).primaryColor);
//    _key.currentState.showSnackBar(new SnackBar(content: new Text(text)));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _isBackground = true;
      showNotification(null);
    } else {
      _isBackground = false;
      _cancelAllNotifications();
      presenter.reStart(false);
    }
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  void receiverMessage(m.Message message, bool isShowNotification) {
    if (message.message.isEmpty) return;
    setState(() {
      _messages.add(message);
      _count = message.count;
      _listController.animateTo(
        _listController.position.maxScrollExtent + _listController.offset,
        duration: new Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
    if (message.type != ConstantValue.CONNECTED &&
        message.type != ConstantValue.DISCONNECTED &&
        message.type != ConstantValue.HEART &&
        isShowNotification &&
        _isBackground) {
      showNotification(message);
    }
  }

  Widget _buildDialog(String version, String url) {
    return new UpdateDialog(
      _dialogKey,
      version,
      (_msg) {
        showSnackBar(_msg);
      },
      () {
        presenter.downloadApk(url);
      },
    );
  }

  @override
  void showUpdateDialog(String version, String url) async {
    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => _buildDialog(version, url),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Future<bool> didPopRoute() {
    presenter.stop();
    return new Future<bool>.value(false);
  }

  @override
  BuildContext getContext() => context;

  @override
  Future showNotification(m.Message message) async {
    var channelId = message != null ? "message id" : 'channel id';
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        channelId, 'channel name', 'channel description',
        playSound: false,
        enableVibration: message != null,
        ongoing: _isBackground,
        autoCancel: !_isBackground,
        styleInformation: new DefaultStyleInformation(true, true));
    var iOSPlatformChannelSpecifics =
        new IOSNotificationDetails(presentSound: false);
    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    if (message == null) {
      await flutterLocalNotificationsPlugin.periodicallyShow(
          0,
          presenter.getDeviceName() ?? ConstantValue.APP_NAME,
          '正在运行中',
          RepeatInterval.EveryMinute,
          platformChannelSpecifics);
    } else {
      await flutterLocalNotificationsPlugin.show(0, ConstantValue.APP_NAME,
          getNotificationsContent(message), platformChannelSpecifics);
    }
  }

  String getNotificationsContent(message) {
    if (message.type == ConstantValue.IMAGE)
      return "${message.username}：[图片]";
    else if (message.type == ConstantValue.VIDEO)
      return "${message.username}：[视频]";
    else if (message.type == ConstantValue.GIF)
      return "${message.username}：[GIF]";
    else
      return "${message.username}：${message.message}";
  }

  void _initNotification() {
    var initializationSettingsAndroid =
        new AndroidInitializationSettings('app_icon');
    var initializationSettingsIOS = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future _cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  @override
  void showDownloadProgress(double _progress) {
    setState(() {
      _dialogKey?.currentState?.progress = _progress;
    });
  }

  @override
  void requestPermission() {
//    if (Platform.isAndroid)
//      SimplePermissions.checkPermission(Permission.WriteExternalStorage)
//          .then((_b) {
//        if (!_b) {
//          SimplePermissions.requestPermission(Permission.WriteExternalStorage);
//        }
//      });
  }

  @override
  void hideProgress() {
    Navigator.pop(context);
  }

  @override
  void showProgress() async {
    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => Center(child: CircularProgressIndicator()),
    );
  }

  @override
  void showDownloadFailed() {
    setState(() {
      _dialogKey?.currentState?.progress = 0.0;
    });
    showSnackBar("下载更新失败，请重试");
  }
}

abstract class HomePageImpl {
  void showSnackBar(String text);

  void receiverMessage(m.Message message, bool isShowNotification);

  void showUpdateDialog(String version, String url);

  void showNotification(m.Message message);

  void showProgress();

  void hideProgress();

  void showDownloadProgress(double _progress);

  void showDownloadFailed();

  void requestPermission();

  BuildContext getContext();
}
