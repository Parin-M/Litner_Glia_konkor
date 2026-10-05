import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/native_models.dart';

class GliaSettings {
  const GliaSettings({
    this.dark = true,
    this.theme = 'amber',
    this.motion = true,
    this.haptics = true,
    this.sound = false,
    this.shuffle = true,
    this.lowPower = false,
    this.autoNext = false,
    this.delay = 2000,
    this.speed = 1.0,
    this.dailyGoal = 25,
    this.fontScale = 1.0,
  });

  final bool dark, motion, haptics, sound, shuffle, lowPower, autoNext;
  final String theme;
  final int delay, dailyGoal;
  final double speed, fontScale;

  GliaSettings copyWith({
    bool? dark, bool? motion, bool? haptics, bool? sound, bool? shuffle,
    bool? lowPower, bool? autoNext, int? delay, int? dailyGoal, double? speed, double? fontScale, String? theme,
  }) => GliaSettings(
        dark: dark ?? this.dark,
        motion: motion ?? this.motion,
        haptics: haptics ?? this.haptics,
        sound: sound ?? this.sound,
        shuffle: shuffle ?? this.shuffle,
        lowPower: lowPower ?? this.lowPower,
        autoNext: autoNext ?? this.autoNext,
        theme: theme ?? this.theme,
        delay: delay ?? this.delay,
        dailyGoal: dailyGoal ?? this.dailyGoal,
        speed: speed ?? this.speed,
        fontScale: fontScale ?? this.fontScale,
      );

  Map<String, dynamic> toJson() => {
        'dark': dark, 'motion': motion, 'haptics': haptics, 'sound': sound,
        'shuffle': shuffle, 'lowPower': lowPower, 'autoNext': autoNext, 'theme': theme, 'delay': delay,
        'dailyGoal': dailyGoal, 'speed': speed, 'fontScale': fontScale,
      };

  factory GliaSettings.fromJson(Map<String, dynamic> j) => GliaSettings(
        dark: j['dark'] ?? true,
        motion: j['motion'] ?? true,
        haptics: j['haptics'] ?? true,
        sound: j['sound'] ?? false,
        shuffle: j['shuffle'] ?? true,
        lowPower: j['lowPower'] ?? false,
        autoNext: j['autoNext'] ?? false,
        theme: (j['theme'] ?? 'amber').toString(),
        delay: (j['delay'] ?? 2000).toInt(),
        dailyGoal: (j['dailyGoal'] ?? 25).toInt(),
        speed: (j['speed'] ?? 1.0).toDouble(),
        fontScale: (j['fontScale'] ?? 1.0).toDouble(),
      );
}

class GliaStore extends ChangeNotifier {
  GliaStore(this.data);

  static const _progressKey = 'glia_native_progress_v4';
  static const _settingsKey = 'glia_native_settings_v4';

  final NativeData data;
  SharedPreferences? _prefs;

  /// Current Leitner box for every card. New cards start in box 1.
  Map<String, int> cardBox = <String, int>{};

  /// Unix milliseconds at which a card becomes due.
  Map<String, int> nextReview = <String, int>{};

  /// Kept for compatibility with the previous native version and backups.
  Map<String, String> cardState = <String, String>{};
  Map<String, Map<String, dynamic>> answerLog = <String, Map<String, dynamic>>{};
  Map<String, List<Map<String, dynamic>>> answerHistory = <String, List<Map<String, dynamic>>>{};

  GliaSettings settings = const GliaSettings();
  int reviewed = 0, correct = 0, streak = 1;
  String? lastVisit;

  static const intervals = <int, Duration>{
    1: Duration.zero,
    2: Duration(days: 1),
    3: Duration(days: 3),
    4: Duration(days: 7),
    5: Duration(days: 14),
  };

  int boxFor(String id) => (cardBox[id] ?? 1).clamp(1, 5);
  DateTime dueAt(String id) => DateTime.fromMillisecondsSinceEpoch(nextReview[id] ?? 0);
  bool isDue(String id) => (nextReview[id] ?? 0) <= DateTime.now().millisecondsSinceEpoch;
  bool isKnown(String id) => boxFor(id) >= 5 && !isDue(id);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    try {
      final raw = _prefs!.getString(_progressKey);
      if (raw != null) {
        final j = Map<String, dynamic>.from(jsonDecode(raw));
        cardBox = Map<String, dynamic>.from(j['cardBox'] ?? {}).map(
          (k, v) => MapEntry(k, (v as num).toInt().clamp(1, 5)),
        );
        nextReview = Map<String, dynamic>.from(j['nextReview'] ?? {}).map(
          (k, v) => MapEntry(k, (v as num).toInt()),
        );
        cardState = Map<String, String>.from(j['cardState'] ?? {});
        answerLog = (j['answerLog'] as Map? ?? {}).map(
          (k, v) => MapEntry('$k', Map<String, dynamic>.from(v)),
        );
        answerHistory = (j['answerHistory'] as Map? ?? {}).map((k, v) => MapEntry('$k', (v as List).map((e) => Map<String, dynamic>.from(e)).toList()));
        reviewed = (j['reviewed'] ?? 0).toInt();
        correct = (j['correct'] ?? 0).toInt();
        streak = (j['streak'] ?? 1).toInt();
        lastVisit = j['lastVisit'];
      }
    } catch (_) {}

    // Migrate the old native status-only format into real Leitner boxes.
    if (cardBox.isEmpty && cardState.isNotEmpty) {
      for (final e in cardState.entries) {
        cardBox[e.key] = e.value == 'known' ? 5 : 1;
        nextReview[e.key] = e.value == 'known' ? DateTime.now().add(const Duration(days: 14)).millisecondsSinceEpoch : 0;
      }
    }

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
    await _prefs?.setString(_progressKey, jsonEncode({
      'version': 4,
      'cardBox': cardBox,
      'nextReview': nextReview,
      'cardState': cardState,
      'answerLog': answerLog,
      'answerHistory': answerHistory,
      'reviewed': reviewed,
      'correct': correct,
      'streak': streak,
      'lastVisit': lastVisit,
    }));
    await _prefs?.setString(_settingsKey, jsonEncode(settings.toJson()));
    notifyListeners();
  }

  Duration _adaptiveInterval(int box, List<Map<String, dynamic>> history) {
    final base = intervals[box] ?? Duration.zero;
    if (history.length < 2 || base == Duration.zero) return base;
    final recent = history.reversed.take(5).toList();
    final wrong = recent.where((e) => e['result'] == 'review' || e['result'] == 'wrong').length;
    final corrects = recent.where((e) => e['result'] == 'known').length;
    if (wrong >= 2) return Duration(milliseconds: (base.inMilliseconds * .45).round());
    if (corrects >= 3) return Duration(milliseconds: (base.inMilliseconds * 1.35).round());
    return base;
  }

  Future<void> rateCard(LeitnerCard card, CardResult result) async {
    final current = boxFor(card.id);
    final now = DateTime.now();

    switch (result) {
      case CardResult.review:
        cardBox[card.id] = 1;
        nextReview[card.id] = now.millisecondsSinceEpoch;
        cardState[card.id] = 'review';
        break;
      case CardResult.later:
        cardBox[card.id] = current;
        final delay = intervals[current] ?? Duration.zero;
        nextReview[card.id] = now.add(delay).millisecondsSinceEpoch;
        cardState[card.id] = current >= 5 ? 'known' : 'later';
        break;
      case CardResult.known:
        final nextBox = current < 5 ? current + 1 : 5;
        cardBox[card.id] = nextBox;
        final history = answerHistory[card.id] ?? const <Map<String, dynamic>>[];
        nextReview[card.id] = now.add(_adaptiveInterval(nextBox, history)).millisecondsSinceEpoch;
        cardState[card.id] = nextBox >= 5 ? 'known' : 'learning';
        correct++;
        break;
    }

    reviewed++;
    final event = <String, dynamic>{'box': cardBox[card.id], 'result': result.name, 'time': now.millisecondsSinceEpoch};
    answerLog[card.id] = event;
    final history = answerHistory.putIfAbsent(card.id, () => <Map<String, dynamic>>[]);
    history.add(event);
    if (history.length > 20) history.removeRange(0, history.length - 20);
    await save();
  }

  Future<void> answer(SpellingQuestion q, bool ok) async {
    reviewed++;
    if (ok) correct++;
    final event = <String, dynamic>{'sentence': q.sentence, 'lesson': q.lesson, 'answer': q.options[q.correctIndex], 'status': ok ? 'correct' : 'wrong', 'time': DateTime.now().millisecondsSinceEpoch};
    answerLog[q.id] = event;
    final history = answerHistory.putIfAbsent(q.id, () => <Map<String, dynamic>>[]);
    history.add(event);
    if (history.length > 20) history.removeRange(0, history.length - 20);
    await save();
  }

  Future<void> updateSettings(GliaSettings value) async {
    settings = value;
    await save();
  }

  Future<void> resetProgress() async {
    cardBox.clear();
    nextReview.clear();
    cardState.clear();
    answerLog.clear();
    answerHistory.clear();
    reviewed = 0;
    correct = 0;
    streak = 1;
    await save();
  }

  Map<String, dynamic> backup() => {
        'version': 4,
        'cardBox': cardBox,
        'nextReview': nextReview,
        'cardState': cardState,
        'answerLog': answerLog,
        'reviewed': reviewed,
        'correct': correct,
        'streak': streak,
        'lastVisit': lastVisit,
        'settings': settings.toJson(),
      };

  Future<void> restore(Map<String, dynamic> value) async {
    cardBox = Map<String, dynamic>.from(value['cardBox'] ?? {}).map(
      (k, v) => MapEntry(k, (v as num).toInt().clamp(1, 5)),
    );
    nextReview = Map<String, dynamic>.from(value['nextReview'] ?? {}).map(
      (k, v) => MapEntry(k, (v as num).toInt()),
    );
    cardState = Map<String, String>.from(value['cardState'] ?? value['status'] ?? {});

    // Import backups created by the previous native version.
    if (cardBox.isEmpty && cardState.isNotEmpty) {
      for (final e in cardState.entries) {
        cardBox[e.key] = e.value == 'known' ? 5 : 1;
        nextReview[e.key] = e.value == 'known' ? DateTime.now().add(const Duration(days: 14)).millisecondsSinceEpoch : 0;
      }
    }

    answerLog = (value['answerLog'] as Map? ?? {}).map(
      (k, v) => MapEntry('$k', Map<String, dynamic>.from(v)),
    );
    answerHistory = (value['answerHistory'] as Map? ?? {}).map((k, v) => MapEntry('$k', (v as List).map((e) => Map<String, dynamic>.from(e)).toList()));
    reviewed = (value['reviewed'] ?? value['answered'] ?? 0).toInt();
    correct = (value['correct'] ?? 0).toInt();
    streak = (value['streak'] ?? 1).toInt();
    lastVisit = value['lastVisit'] ?? value['visit'];
    if (value['settings'] is Map) {
      settings = GliaSettings.fromJson(Map<String, dynamic>.from(value['settings']));
    }
    await save();
  }
}
