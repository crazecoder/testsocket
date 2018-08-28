class ConstantValue {
  static const DEBUG = false;
  static const APP_NAME = "阅后即焚";

  static const IP = "your server ip";
  static const BASE_URL = "http://$IP";
  static const HTTP_VERSION_PORT = ":8080";
  static const HTTP_VERSION_URL = '$BASE_URL$HTTP_VERSION_PORT/version';
  static const HTTP_DOWNLOAD_PORT = ":8081";
  static const HTTP_DOWNLOAD_URL = '$BASE_URL$HTTP_DOWNLOAD_PORT/update.apk';

//  static const SOCKET_URL = "ws://IP:6011/ws";
  static const SOCKET_URL = "ws://$IP:8080/ws";

  static const NORMAL = 0;
  static const CONNECTED = 1;
  static const DISCONNECTED = -1;
  static const IMAGE = 2;

  static const IMAGE_WIDTH = 150.0;
  static const IMAGE_HEIGHT = 150.0;


  static const GALLERY = 10;
  static const CAMERA = 20;
}
