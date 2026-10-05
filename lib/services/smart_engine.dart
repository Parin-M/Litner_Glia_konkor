import '../models/native_models.dart';
import 'native_store.dart';

enum SmartDifficulty { easy, medium, hard, critical }

class SmartCardScore {
  const SmartCardScore(this.card, this.difficulty, this.priority);
  final LeitnerCard card;
  final SmartDifficulty difficulty;
  final double priority;
}

class SmartEngine {
  static SmartDifficulty difficulty(GliaStore store, LeitnerCard card) {
    final box = store.boxFor(card.id);
    final log = store.answerLog[card.id];
    if (log == null) {
      return box <= 1 ? SmartDifficulty.hard : SmartDifficulty.medium;
    }
    final result = log['result'] ?? log['status'] ?? '';
    if (result == 'review' || result == 'wrong') {
      return SmartDifficulty.critical;
    }
    if (box <= 2) return SmartDifficulty.hard;
    if (box == 3) return SmartDifficulty.medium;
    return SmartDifficulty.easy;
  }

  static double priority(GliaStore store, LeitnerCard card) {
    final box = store.boxFor(card.id);
    var score = (6 - box) * 20.0;
    if (store.isDue(card.id)) score += 45;
    final log = store.answerLog[card.id];
    if (log != null) {
      final result = log['result'] ?? log['status'] ?? '';
      if (result == 'review' || result == 'wrong') score += 35;
    }
    return score;
  }

  static List<SmartCardScore> rank(GliaStore store, List<LeitnerCard> cards) {
    final result = cards
        .map((c) => SmartCardScore(c, difficulty(store, c), priority(store, c)))
        .toList();
    result.sort((a, b) => b.priority.compareTo(a.priority));
    return result;
  }

  static List<LeitnerCard> smartQueue(
    GliaStore store,
    List<LeitnerCard> cards, {
    int limit = 20,
  }) {
    return rank(store, cards).take(limit).map((x) => x.card).toList();
  }

  static Map<String, int> weakLessons(
    GliaStore store,
    List<LeitnerCard> cards,
  ) {
    final out = <String, int>{};
    for (final c in cards) {
      if (store.boxFor(c.id) <= 2 || !store.isKnown(c.id)) {
        out[c.lesson] = (out[c.lesson] ?? 0) + 1;
      }
    }
    final entries = out.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in entries.take(8)) e.key: e.value};
  }

  static int mastery(GliaStore store, List<LeitnerCard> cards) {
    if (cards.isEmpty) return 0;
    final total = cards.fold<int>(0, (sum, c) => sum + store.boxFor(c.id));
    return ((total / (cards.length * 5)) * 100).round().clamp(0, 100);
  }

  static int readiness(GliaStore store, List<LeitnerCard> cards) {
    final base = mastery(store, cards);
    final accuracy = store.reviewed == 0
        ? 0
        : ((store.correct / store.reviewed) * 100).round();
    return ((base * .65) + (accuracy * .35)).round().clamp(0, 100);
  }

  static String coach(GliaStore store, List<LeitnerCard> cards) {
    final weak = weakLessons(store, cards);
    final due = cards.where((c) => store.isDue(c.id)).length;
    final accuracy = store.reviewed == 0
        ? 0
        : ((store.correct / store.reviewed) * 100).round();

    if (store.reviewed == 0) {
      return 'هنوز داده کافی نداریم؛ یک مرور کوتاه شروع کن تا مربی هوشمند الگوی یادگیری‌ات را پیدا کند.';
    }
    if (weak.isNotEmpty) {
      final weakLesson = weak.keys.first;
      return 'تمرکز بعدی روی «$weakLesson» است. $due کارت موعددار داری و دقت فعلی‌ات $accuracy٪ است.';
    }
    if (accuracy < 70) {
      return 'امروز بهتر است مرورهای کوتاه و تکراری داشته باشی؛ دقت فعلی $accuracy٪ است.';
    }
    return 'عملکردت خوب است؛ $due کارت موعددار را جمع کن و سپس یک چالش کوتاه انجام بده.';
  }

  static List<LeitnerCard> challenge(
    GliaStore store,
    List<LeitnerCard> cards, {
    int limit = 20,
  }) {
    final ranked = rank(store, cards);
    return ranked.take(limit).map((x) => x.card).toList();
  }
}
