import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class Settings {
  static late SharedPreferences _sp;
  static Settings? _instance;

  Settings._internal();
  factory Settings() {
    if (_instance == null) {
      _instance = Settings._internal();
    }
    return _instance!;
  }
  Future init() async {
    _sp = await SharedPreferences.getInstance();
  }

  Future setfontSize(double size) async {
    _sp.setDouble('fontSize', size);
  }

  double getfontSize() {
    double? fontSize = _sp.getDouble('fontSize');
    if (fontSize == null) {
      fontSize = 16;
    }
    return fontSize;
  }

  Future setPadding(double size) async {
    _sp.setDouble('paddingSize', size);
  }

  double getPadding() {
    double? padding = _sp.getDouble('paddingSize');
    if (padding == null) {
      padding = 0;
    }
    return padding;
  }

  Future setScrollPosition(double position) async {
    _sp.setDouble('scrollPosition', position);
  }

  double getScrollPosition() {
    double? position = _sp.getDouble('scrollPosition');
    // if (position == null) {
    //   position = 0;
    // }
    return position!;
  }
}
