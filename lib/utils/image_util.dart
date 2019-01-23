import 'dart:convert';
import 'dart:io';

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as Im;
import 'dart:typed_data';

class CompressImage {
  //忽略构造函数，即不支持new
  CompressImage._();

  static Future<String> compressImage(CompressObject object) async {
    return compute(_decodeImage, object);
  }

  static String _decodeImage(CompressObject object) {
    Im.Image image = Im.decodeImage(object.imageFile.readAsBytesSync());
    var pw = image.width / image.height;
    var ph = image.height / image.width;
    int targetSize;
    if ((pw < 1 && pw > 0.5625) || (ph < 1 && ph > 0.5625)) {
      if (image.width > 1664 || image.height > 1664) {
        targetSize = 300;
      } else
        targetSize = 150;
    }
    if ((pw < 0.5625 && pw > 0.5) || (ph < 0.5625 && ph > 0.5)) {
      targetSize = 200;
    }
    if ((pw < 0.5 && pw > 0) || (ph < 0.5 && ph > 0)) {
      targetSize = 500;
    }
    if (image.width > object.compressWidth ||
        object.imageFile.lengthSync() / 1024 > targetSize) {
      Im.Image smallerImage = Im.copyResize(
          image,
          object.compressWidth > image.width
              ? image.width
              : object
                  .compressWidth); // choose the size here, it will maintain aspect ratio
      var decodedImageFile = new File(object.path + '/img_${object.rand}.jpg');
      _compressImage(smallerImage, decodedImageFile, targetSize);

      return decodedImageFile.path;
    } else {
      return object.imageFile.path;
    }
  }

  static _compressImage(Im.Image image, File file, targetSize) {
    if (file.existsSync()) {
      file.deleteSync();
    }
    file.writeAsBytesSync(Im.encodeJpg(image, quality: 85));
    var decodedImageFileSize = file.lengthSync();
    if (decodedImageFileSize / 1024 > targetSize) {
      _compressImage(image, file, targetSize);
    }
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
