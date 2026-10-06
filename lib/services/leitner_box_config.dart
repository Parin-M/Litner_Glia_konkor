import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeitnerBoxConfig extends ChangeNotifier {
  static const _key = 'glia_leitner_box_names_v1';
  static const defaultNames = <String>['خانه ۱', 'خانه ۲', 'خانه ۳', 'خانه ۴', 'خانه ۵'];

  List<String> names = List<String>.from(defaultNames);
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    try {
      final raw = _prefs!.getString(_key);
      if (raw != null) {
        final values = List<String>.from(jsonDecode(raw));
        if (values.length == 5 && values.every((e) => e.trim().isNotEmpty)) names = values;
      }
    } catch (_) {}
    notifyListeners();
  }

  String name(int box) => names[(box.clamp(1, 5)) - 1];

  Future<void> rename(int box, String value) async {
    final index = box.clamp(1, 5) - 1;
    final text = value.trim();
    if (text.isEmpty) return;
    names[index] = text;
    await _prefs?.setString(_key, jsonEncode(names));
    notifyListeners();
  }

  Future<void> reset() async {
    names = List<String>.from(defaultNames);
    await _prefs?.setString(_key, jsonEncode(names));
    notifyListeners();
  }
}
