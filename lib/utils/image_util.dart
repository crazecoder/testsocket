import 'dart:convert';
import 'dart:io';

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as Im;
import 'dart:typed_data';

class CompressImage {
  static Future<String> compressImage(CompressObject object) async {
    return compute(_decodeImage, object);
  }

  static String _decodeImage(CompressObject object) {
    Im.Image image = Im.decodeImage(object.imageFile.readAsBytesSync());
    Im.Image smallerImage = Im.copyResize(
        image, object.compressWidth); // choose the size here, it will maintain aspect ratio
    var decodedImageFile = new File(object.path + '/img_${object.rand}.jpg');
    decodedImageFile.writeAsBytesSync(Im.encodeJpg(smallerImage, quality: 85));
    return decodedImageFile.path;
  }

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

class CompressObject {
  File imageFile;
  String path;
  String rand;
  int compressWidth;

  CompressObject(this.imageFile, this.path, this.rand, this.compressWidth);
}
