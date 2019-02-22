import 'dart:convert';
import 'dart:io';

import 'package:device_info/device_info.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter_luban/flutter_luban.dart';

import '../bean/message.dart';
import '../utils/image_util.dart';
import '../constant.dart';
import '../utils/print_util.dart';
import '../utils/prefs_util.dart';
import '../utils/string_util.dart';

abstract class HomeLogicImpl {
  Future getApkVersion();

  void downloadApk(Function f);

  void _installApk(String path);

  void connectSocket({Function onReceiver});

  void disConnectSocket();

  void sendMessage(String text, {int messageType, Function error});

  connectAndListen({Function onServerError});

  initPlatformState();

  getImage(int type, {Function loading, Function success, Function error});

  String getDeviceId();

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

  String _deviceId;

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
    if (_isConnected) return;
    _isConnected = true;
    socket = await WebSocket.connect(ConstantValue.SOCKET_URL);
//    _connectTimeMills = DateTime.now().millisecondsSinceEpoch;
    if (!_isReConnect) {
      Message m = Message(
          _deviceId, "已连接", _deviceInfo, ConstantValue.CONNECTED,DateTime.now().millisecondsSinceEpoch);
      var jsonStr = m.toJson();
      log(jsonStr);
      socket.add(jsonStr);
    }
    _reConnectCount++;
    socket.listen(
      (event) {
        var map = json.decode(event);
        var msg = Message.fromJson(map);
        onReceiver(msg);
        _isConnected = true;
        _isReConnect = true;
        log("Server: $event");
        _reConnectCount = 0;
      },
      onError: (_error) {
        log("error==========");
        onError();
        socket.close().then((_) {
          log("socket.close....");
          connectSocket(
              onReceiver: onReceiver, onDone: onDone, onError: onError);
        });
      },
      onDone: () {
        _isConnected = false;
        if (_reConnectCount >= _maxReConnect2Tips) onDone();
        socket.close().then((_) {
          log("socket.close....");
          connectSocket(
              onReceiver: onReceiver, onDone: onDone, onError: onError);
        });
      },
      cancelOnError: true,
    );
  }

  @override
  void downloadApk(Function f) async {
    Directory tempDir = await getExternalStorageDirectory();
    String tempPath = tempDir.path;
    String savePath = '$tempPath/update.apk';
    await dio.download('${ConstantValue.HTTP_DOWNLOAD_URL}', savePath,
        onReceiveProgress: f);
    _installApk(savePath);
  }

  @override
  void _installApk(String path) async {
    log(path);
    log(Uri.file(path));
    OpenFile.open(path);
  }

  @override
  void disConnectSocket() {
    if (!_isConnected) return;
    Message m =
        Message(_deviceId, "", _deviceInfo, ConstantValue.DISCONNECTED,DateTime.now().millisecondsSinceEpoch);
    var jsonStr = m.toJson();
    log(jsonStr);
    socket.add(jsonStr);
    _isConnected = false;
//    socket.close().then((_) {
//      log("socket.close....");
//    });
  }

  @override
  void sendMessage(String text,
      {int messageType = ConstantValue.NORMAL, Function error}) {
//    if (!_isConnected) {
//      connectAndListen(onServerError: error);
//    }
    var urls = getVideoUrl(text);
    if (urls.length > 0) {
      messageType = ConstantValue.VIDEO;
    }
    var urls1 = getGifUrl(text);
    if (urls1.length > 0) {
      messageType = ConstantValue.GIF;
    }
    var message = Message(_deviceId, text, _deviceInfo, messageType,DateTime.now().millisecondsSinceEpoch);
    var jsonStr = message.toJson();
    log(jsonStr);
    socket.add(jsonStr);
  }

  @override
  Future<Null> initPlatformState() async {
    log("start deviceinfo....");
    DeviceInfoPlugin deviceInfo = new DeviceInfoPlugin();
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      _deviceInfo = androidInfo.model ?? "android模拟器";
      _deviceId = androidInfo.androidId;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      _deviceInfo = iosInfo.utsname.machine ?? "iOS模拟器";
      _deviceId = iosInfo.identifierForVendor;
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
      if (!_isConnected)
        connectSocket(onError: onError, onDone: onDone, onReceiver: onReceiver);
    }, onError: (_error) {
      log(_error.toString());
      _isConnected = false;
      onServerError();
    });
  }

  @override
  getImage(int type,
      {Function loading, Function success, Function error}) async {
    File imageFile;
    if (type == ConstantValue.GALLERY) {
      imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
    } else {
      imageFile = await ImagePicker.pickImage(source: ImageSource.camera);
    }
    if (imageFile == null) return;
    String base64;
    final tempDir = await getTemporaryDirectory();
    loading();
    CompressObject compressObject = CompressObject(
      imageFile: imageFile,
      //image
      path: tempDir.path,
      //compress to path
      quality: 85,
      //first compress quality, default 80
      step: 9,
      //compress quality step, The bigger the fast, Smaller is more accurate, default 6
      mode: CompressMode.LARGE2SMALL, //default AUTO
    );
    String filePath = await Luban.compressImage(compressObject);
    File file = new File(filePath);
    base64 = CompressImage.getImageBase64(file);
    sendMessage(base64, messageType: ConstantValue.IMAGE, error: error);
    success();
  }

  @override
  String getDeviceId() => _deviceId;

  @override
  saveThemeType(bool isDark) {
    PrefsUtil.saveTheme(isDark);
  }
}
