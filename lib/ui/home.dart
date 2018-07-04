import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:simple_permissions/simple_permissions.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../bean/message.dart';
import '../constant.dart';
import '../presenter/home_presenter.dart';
import '../utils/image_util.dart';
import '../utils/print_util.dart';
import '../widget/update_dialog.dart';
import '../widget/clipboard_text.dart';
import '../utils/string_util.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title, this.themeType,this.changeTheme}) : super(key: key);

  final String title;
  final Function changeTheme;
  final themeType;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with WidgetsBindingObserver, HomePageImpl, AutomaticKeepAliveClientMixin {
  var _controller = new TextEditingController();
  var _messages = <Message>[];
  GlobalKey<ScaffoldState> _key = new GlobalKey();

  var _listController = ScrollController();
  var _count = 0;
  HomePresenter presenter;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  var _isBackground = false;

  GlobalKey<UpdateDialogState> _dialogKey = new GlobalKey();
  var _isDark;

  @override
  Widget build(BuildContext context) {
    _isDark =  widget.themeType??false;
    return new Scaffold(
      key: _key,
      appBar: new AppBar(
        actions: <Widget>[
          new GestureDetector(
            child: new Icon(_isDark ? Icons.brightness_2 : Icons.brightness_5),
            onTap: () {
              setState(() {
                _isDark = !_isDark;
                widget.changeTheme(_isDark);
              });
              presenter.saveTheme(_isDark);
            },
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
        var _username;
        var _style;
        if (_messages[i].type == ConstantValue.NORMAL) {
          _username = '${_messages[i].username} ：';
          _style =
              new TextStyle(color: Theme.of(context).textTheme.body1.color);
        } else if (_messages[i].type == ConstantValue.IMAGE) {
          _username = '${_messages[i].username} ：';
          _style =
              new TextStyle(color: Theme.of(context).textTheme.body1.color);
          return _buildImageItem(_username, _style,
              CompressImage.getImageByte(_messages[i].message));
        } else {
          _username = _messages[i].username;
          _style = new TextStyle(color: Theme.of(context).primaryColor);
        }
        var content = _messages[i].message;
        var gifUrls = getGifUrl(content);
        var contentItem;
        if (gifUrls.length == 0) {
          contentItem = new Expanded(
            child: new ClipBoardText(
              style: _style,
              text: _messages[i].message,
              onCopyComplete: () => showSnackBar("信息复制完成"),
            ),
          );
        } else {
          var gifItems = <Widget>[];
          gifUrls.forEach((_url) {
            gifItems.add(_buildGifItem(_url));
          });
          contentItem = new Expanded(
            child: new Column(
              children: gifItems,
            ),
          );
        }
        return new Container(
          padding: EdgeInsets.only(left: 5.0, right: 5.0),
          child: new Row(
            //对齐
            textBaseline: TextBaseline.alphabetic,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            children: <Widget>[
              new Text(
                _username,
                style: _style,
              ),
              contentItem,
            ],
          ),
        );
      });

  Widget _buildImageItem(_username, _style, _file) => new Container(
        padding: EdgeInsets.only(left: 5.0, right: 5.0),
        child: new Row(
          //对齐
          textBaseline: TextBaseline.alphabetic,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          children: <Widget>[
            new Text(
              _username,
              style: _style,
            ),
            new GestureDetector(
              child: new Container(
                width: ConstantValue.IMAGE_WIDTH,
                height: ConstantValue.IMAGE_HEIGHT,
                child: new Image.memory(_file),
              ),
              onTap: () {
                _showImagePop(_file);
              },
            ),
          ],
        ),
      );

  Widget _buildGifItem(_url) => new Container(
        padding: EdgeInsets.only(left: 5.0, right: 5.0),
        child: new GestureDetector(
          child: new Container(
            width: ConstantValue.IMAGE_WIDTH,
            height: ConstantValue.IMAGE_HEIGHT,
            child: new CachedNetworkImage(
              imageUrl: _url,
              placeholder: new CircularProgressIndicator(),
            ),
          ),
          onTap: () {
            _showGifPop(_url);
          },
        ),
      );

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
                child: new Text("发送",style: new TextStyle(color: Theme.of(context).textTheme.button.color),),
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
    log("start initState....");
    requestPermission();
    WidgetsBinding.instance.addObserver(this);
    _initNotification();
    presenter = new HomePresenter(this);
    presenter.start();
  }

  @override
  void showSnackBar(String text) {
    _key.currentState.showSnackBar(new SnackBar(content: new Text(text)));
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
    }
  }

  @override
  void dispose() {
//    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void receiverMessage(Message message, bool isShowNotification) {
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
        isShowNotification &&
        _isBackground) {
      showNotification(message);
    }
  }

  Widget _buildDialog(String version) {
    return new UpdateDialog(
      _dialogKey,
      version,
      (_msg) {
        showSnackBar(_msg);
      },
      () {
        presenter.downloadApk();
      },
    );
  }

  @override
  void showUpdateDialog(String version) async {
    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => _buildDialog(version),
    );
  }

  void _showGifPop(_url) async {
    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return new GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: new CachedNetworkImage(
              imageUrl: _url,
              placeholder: new RefreshProgressIndicator(),
            ),
          );
        });
  }

  void _showImagePop(bytes) async {
    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return new GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: new Image.memory(bytes),
          );
        });
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
  Future showNotification(Message message) async {
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
      await flutterLocalNotificationsPlugin.show(
          0,
          presenter.getDeviceName() ?? ConstantValue.APP_NAME,
          '正在运行中',
          platformChannelSpecifics);
    } else {
      await flutterLocalNotificationsPlugin.show(
          0,
          ConstantValue.APP_NAME,
          message.type == ConstantValue.IMAGE
              ? "${message.username}：[图片]"
              : "${message.username}：${message.message}",
          platformChannelSpecifics);
    }
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
    SimplePermissions.requestPermission(Permission.WriteExternalStorage);
  }
}

abstract class HomePageImpl {
  void showSnackBar(String text);

  void receiverMessage(Message message, bool isShowNotification);

  void showUpdateDialog(String version);

  void showNotification(Message message);

  void showDownloadProgress(double _progress);

  void requestPermission();

  BuildContext getContext();
}
