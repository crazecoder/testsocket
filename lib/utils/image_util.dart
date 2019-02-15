import 'dart:convert';
import 'dart:io';

import 'dart:typed_data';

class CompressImage {
  //忽略构造函数，即不支持new
  CompressImage._();


  static String getImageBase64(File image) {
    var bytes = image.readAsBytesSync();
    var base64 = base64Encode(bytes);
    return base64;
  }

  static File getImageFile(String base64) {
    var bytes = base64Decode(base64);
    return File.fromRawPath(bytes);
  }

  static Uint8List getImageByte(String base64) {
    return base64Decode(base64);
  }
}
