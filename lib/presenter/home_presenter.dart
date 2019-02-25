import '../logic/home_logic.dart';
import '../ui/home.dart';

abstract class HomePresenterImpl {
  void start();

  void stop();

  void sendMessage(String text);

  void downloadApk();

  void reStart(bool showToast);

  void pickImage(int type);


  void saveTheme(bool isDark);
}

class HomePresenter extends HomePresenterImpl {
  HomeLogic _logic;
  HomePageImpl _view;
//  var _newVersionName;

  HomePresenter(this._view) {
    _logic = new HomeLogic();
  }

  @override
  void start() async {
    _logic.initPlatformState().then((_)=>connect());
//    if (Platform.isAndroid) {
//      PackageInfo.fromPlatform().then((info) {
//        _logic.getApkVersion().then((data) {
//          log(info.buildNumber);
//          if (int.parse(info.buildNumber) < data["versionCode"]) {
//            _newVersionName = data["versionName"];
//            _view.showUpdateDialog(_newVersionName);
//          }
//        });
//      });
//    }
  }

  String getDeviceName() {
    return _logic.deviceInfo;
  }

  void connect() async {
    await _logic.connectAndListen(
        onServerError: () => _view.showSnackBar("服务器未开启"),
        onReceiver: (message) => _view.receiverMessage(
            message, message.id != _logic.getDeviceId()),
        onError: () => _view.showSnackBar("连接失败，请重新启动"),
        onDone: () => _view.showSnackBar("连接已断开，请检查网络后重新启动"));
//    _countdownTimer = Timer.periodic(new Duration(seconds: 5), (timer) {
//      _logic.sendMessage(
//        "",
//        messageType: ConstantValue.HEART,
//        error: () =>_view.showSnackBar("连接断开"),
//      );
//    });
  }

  @override
  void stop() {
    _logic.disConnectSocket();
//    _countdownTimer.cancel();
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
    _logic.getImage(
      type,
      loading: () => _view.showProgress(),
      success: () => _view.hideProgress(),
      error: () {
        _view.hideProgress();
        _view.showSnackBar("图片可能过大，请重试");
      },
    );
  }


  @override
  void saveTheme(bool isDark) {
    _logic.saveThemeType(isDark);
  }

  @override
  void reStart(bool showToast) {
    stop();
    showToast??_view.showSnackBar("重新连接");
    connect();
  }
}
