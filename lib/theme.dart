import 'package:flutter/material.dart';

class CustomTheme {
  static ThemeData buildLightTheme() {
    final ThemeData base = new ThemeData.light();
    return base.copyWith(
      primaryColor: Colors.blue,
      textTheme: TextTheme(
          body2: TextStyle(color: Colors.white),
          body1: TextStyle(color: Colors.black, fontSize: 16.0),
          button: TextStyle(color: Colors.blue)),
    );
  }

  static ThemeData buildDarkTheme() {
    final ThemeData base = new ThemeData.dark();
    return base.copyWith(
      primaryColor: Colors.blueGrey,
      textTheme: TextTheme(
          body2: TextStyle(color: Colors.white),
          body1: TextStyle(color: Colors.white, fontSize: 16.0),
          button: TextStyle(color: Colors.white)),
    );
  }
}
