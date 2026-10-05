import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/native_models.dart';

class GliaSettings {
  const GliaSettings({this.dark = true, this.motion = true, this.haptics = true, this.sound = false, this.shuffle = true, this.lowPower = false, this.delay = 2000, this.speed = 1.0, this.dailyGoal = 25, this.fontScale = 1.0});
  final bool dark, motion, haptics, sound, shuffle, lowPower;
  final int delay, dailyGoal;
  final double speed, fontScale;

  GliaSettings copyWith({bool? dark, bool? motion, bool? haptics, bool? sound, bool? shuffle, bool? lowPower, int? delay, int? dailyGoal, double? speed, double? fontScale}) => GliaSettings(
        dark: dark ?? this.dark, motion: motion ?? this.motion, haptics: haptics ?? this.haptics, sound: sound ?? this.sound,
        shuffle: shuffle ?? this.shuffle, lowPower: lowPower ?? this.lowPower, delay: delay ?? this.delay,
        dailyGoal: dailyGoal ?? this.dailyGoal, speed: speed ?? this.speed, fontScale: fontScale ?? this.fontScale,
      );

  Map<String, dynamic> toJson() => {'dark': dark, 'motion': motion, 'haptics': haptics, 'sound': sound, 'shuffle': shuffle, 'lowPower': lowPower, 'delay': delay, 'dailyGoal': dailyGoal, 'speed': speed, 'fontScale': fontScale};
  factory GliaSettings.fromJson(Map<String, dynamic> j) => GliaSettings(
        dark: j['dark'] ?? true, motion: j['motion'] ?? true, haptics: j['haptics'] ?? true, sound: j['sound'] ?? false,
        shuffle: j['shuffle'] ?? true, lowPower: j['lowPower'] ?? false, delay: (j['delay'] ?? 2000).toInt(), dailyGoal: (j['dailyGoal'] ?? 25).toInt(),
        speed: (j['speed'] ?? 1.0).toDouble(), fontScale: (j['fontScale'] ?? 1.0).toDouble(),
      );
}

class GliaStore extends ChangeNotifier {
  GliaStore(this.data);
  static const _progressKey = 'glia_native_progress_v3';
  static const _settingsKey = 'glia_native_settings_v3';
  final NativeData data;
  SharedPreferences? _prefs;
  Map<String, String> cardState = <String, String>{};
  Map<String, Map<String, dynamic>> answerLog = <String, Map<String, dynamic>>{};
  GliaSettings settings = const GliaSettings();
  int reviewed = 0, correct = 0, streak = 1;
  String? lastVisit;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    try {
      final raw = _prefs!.getString(_progressKey);
      if (raw != null) {
        final j = Map<String, dynamic>.from(jsonDecode(raw));
        cardState = Map<String, String>.from(j['cardState'] ?? {});
        answerLog = (j['answerLog'] as Map? ?? {}).map((k, v) => MapEntry('$k', Map<String, dynamic>.from(v)));
        reviewed = (j['reviewed'] ?? 0).toInt();
        correct = (j['correct'] ?? 0).toInt();
        streak = (j['streak'] ?? 1).toInt();
        lastVisit = j['lastVisit'];
      }
    } catch (_) {}
    try {
      final raw = _prefs!.getString(_settingsKey);
      if (raw != null) settings = GliaSettings.fromJson(Map<String, dynamic>.from(jsonDecode(raw)));
    } catch (_) {}
    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';
    final yesterday = now.subtract(const Duration(days: 1));
    final yd = '${yesterday.year}-${yesterday.month}-${yesterday.day}';
    if (lastVisit != today) {
      streak = lastVisit == yd ? streak + 1 : 1;
      lastVisit = today;
      await save();
    }
    notifyListeners();
  }

  Future<void> save() async {
    await _prefs?.setString(_progressKey, jsonEncode({'cardState': cardState, 'answerLog': answerLog, 'reviewed': reviewed, 'correct': correct, 'streak': streak, 'lastVisit': lastVisit}));
    await _prefs?.setString(_settingsKey, jsonEncode(settings.toJson()));
    notifyListeners();
  }

  Future<void> rateCard(LeitnerCard card, CardResult result) async {
    cardState[card.id] = result.name;
    reviewed++;
    if (result == CardResult.known) correct++;
    await save();
  }

  Future<void> answer(SpellingQuestion q, bool ok) async {
    reviewed++;
    if (ok) correct++;
    answerLog[q.id] = {'sentence': q.sentence, 'lesson': q.lesson, 'answer': q.options[q.correctIndex], 'status': ok ? 'correct' : 'wrong', 'time': DateTime.now().millisecondsSinceEpoch};
    await save();
  }

  Future<void> updateSettings(GliaSettings value) async { settings = value; await save(); }

  Future<void> resetProgress() async { cardState.clear(); answerLog.clear(); reviewed = 0; correct = 0; await save(); }

  Map<String, dynamic> backup() => {'version': 3, 'cardState': cardState, 'answerLog': answerLog, 'reviewed': reviewed, 'correct': correct, 'streak': streak, 'lastVisit': lastVisit, 'settings': settings.toJson()};

  Future<void> restore(Map<String, dynamic> value) async {
    cardState = Map<String, String>.from(value['cardState'] ?? value['status'] ?? {});
    answerLog = (value['answerLog'] as Map? ?? {}).map((k, v) => MapEntry('$k', Map<String, dynamic>.from(v)));
    reviewed = (value['reviewed'] ?? value['answered'] ?? 0).toInt();
    correct = (value['correct'] ?? 0).toInt();
    streak = (value['streak'] ?? 1).toInt();
    lastVisit = value['lastVisit'] ?? value['visit'];
    if (value['settings'] is Map) settings = GliaSettings.fromJson(Map<String, dynamic>.from(value['settings']));
    await save();
  }
}
