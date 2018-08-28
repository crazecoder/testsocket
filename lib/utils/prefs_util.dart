import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class PrefsUtil {
  PrefsUtil._();
  static Future<bool> isDark() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool("isDark");
  }

  static Future<Null> saveTheme(bool isDark) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool("isDark",isDark);
  }
}
