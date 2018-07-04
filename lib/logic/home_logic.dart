import 'dart:convert';
import 'dart:io';

import 'package:device_info/device_info.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';

import '../bean/message.dart';
import '../constant.dart';
import '../utils/image_util.dart';
import '../utils/print_util.dart';
import '../utils/prefs_util.dart';


abstract class HomeLogicImpl {
  Future getApkVersion();

  void downloadApk(Function f);

  void _installApk(String path);

  void connectSocket({Function onReceiver});

  void disConnectSocket();

  void sendMessage(String text, {int messageType, Function error});

  connectAndListen({Function onServerError});

  initPlatformState();

  getImage(int type, int width, Function error);

  int getConnectTimeMills();

  saveThemeType(bool isDark);
}

class HomeLogic extends HomeLogicImpl {
  static const platform = const MethodChannel('app.channel.shared.data');
  WebSocket socket;
  Dio dio;

  var _reConnectCount = 0;
  final _maxReConnect2Tips = 10;

  var _isConnected = false;
  bool _isReConnect = false;

  var _deviceInfo;

  int _connectTimeMills = 0;

  HomeLogic() {
    dio = new Dio();
    dio.options.connectTimeout = 5000; //5s
    dio.options.receiveTimeout = 3000;
  }

  @override
  Future<Map> getApkVersion() async {
    Response response = await dio.get('${ConstantValue.HTTP_VERSION_URL}');
    log(response.data);
    return response.data;
  }

  @override
  void connectSocket(
      {Function onReceiver, Function onError, Function onDone}) async {
    socket = await WebSocket.connect(ConstantValue.SOCKET_URL);
    _connectTimeMills = DateTime.now().millisecondsSinceEpoch;
    if (!_isReConnect) {
      Message m = Message(
          _connectTimeMills, "已连接", _deviceInfo, ConstantValue.CONNECTED);
      var jsonStr = m.toJson();
      log(jsonStr);
      socket.add(jsonStr);
    }
    _reConnectCount++;
    socket.listen((event) {
      var map = json.decode(event);
      var msg = Message.fromJson(map);
      onReceiver(msg);
      _isConnected = true;
      _isReConnect = true;
      log("Server: $event");
      _reConnectCount = 0;
    }, onError: (_error) {
      log("error==========");
      onError();
      socket.close().then((_) {
        log("socket.close....");
        connectSocket(onReceiver: onReceiver, onDone: onDone, onError: onError);
      });
    }, onDone: () {
      _isConnected = false;
      if (_reConnectCount >= _maxReConnect2Tips) onDone();
      socket.close().then((_) {
        log("socket.close....");
        connectSocket(onReceiver: onReceiver, onDone: onDone, onError: onError);
      });
    }, cancelOnError: true);
  }

  @override
  void downloadApk(Function f) async {
    Directory tempDir = await getExternalStorageDirectory();
    String tempPath = tempDir.path;
    String savePath = '$tempPath/update.apk';
    await dio.download('${ConstantValue.HTTP_DOWNLOAD_URL}', savePath,
        onProgress: f);
    _installApk(savePath);
  }

  @override
  void _installApk(String path) async {
    log(path);
    log(Uri.file(path));
    Map<String, String> map = {"path": path};
    await platform.invokeMethod("install", map);
  }

  @override
  void disConnectSocket() {
    Message m = Message(
        _connectTimeMills, "已断开", _deviceInfo, ConstantValue.DISCONNECTED);
    var jsonStr = m.toJson();
    log(jsonStr);
    socket.add(jsonStr);
//    socket.close().then((_) {
//      log("socket.close....");
//    });
  }

  @override
  void sendMessage(String text,
      {int messageType = ConstantValue.NORMAL, Function error}) {
    if (!_isConnected) {
      connectAndListen(onServerError: error);
    }
    var message = Message(_connectTimeMills, text, _deviceInfo, messageType);
    var jsonStr = message.toJson();
    log(jsonStr);
    socket.add(jsonStr);
  }

  @override
  initPlatformState() async {
    log("start deviceinfo....");
    DeviceInfoPlugin deviceInfo = new DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      _deviceInfo = androidInfo.model;
      _deviceInfo ?? "android模拟器";
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      _deviceInfo = iosInfo.utsname.machine;
      _deviceInfo ?? "iOS模拟器";
    }
  }

  get deviceInfo => _deviceInfo;

  @override
  connectAndListen(
      {Function onServerError,
      Function onReceiver,
      Function onError,
      Function onDone}) {
    runZoned(() {
      connectSocket(onError: onError, onDone: onDone, onReceiver: onReceiver);
    }, onError: (_error) {
      log(_error);
      _isConnected = false;
      onServerError();
    });
  }

  @override
  getImage(int type, int width, Function error) async {
    var imageFile;
    if (type == ConstantValue.GALLERY) {
      imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
    } else {
      imageFile = await ImagePicker.pickImage(source: ImageSource.camera);
    }
    if (imageFile == null) return;
    final tempDir = await getTemporaryDirectory();
    var rand = "temp";
    CompressObject compressObject =
        new CompressObject(imageFile, tempDir.path, rand, width);
    String filePath = await CompressImage.compressImage(compressObject);
    File file = new File(filePath);
    String base64 = CompressImage.getImageBase64(file);
    sendMessage(base64, messageType: ConstantValue.IMAGE, error: error);
  }

  @override
  int getConnectTimeMills() => _connectTimeMills;

  @override
  saveThemeType(bool isDark) {
    PrefsUtil.saveTheme(isDark);
  }
}
