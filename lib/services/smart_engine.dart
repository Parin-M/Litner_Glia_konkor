import 'dart:math' as math;
import '../models/native_models.dart';
import 'native_store.dart';

enum SmartDifficulty { easy, medium, hard, critical }

class SmartCardScore {
  const SmartCardScore(this.card, this.difficulty, this.priority);
  final LeitnerCard card;
  final SmartDifficulty difficulty;
  final double priority;
}

class MemoryStability {
  const MemoryStability({required this.card, required this.stability, required this.forgettingRisk, required this.confidence});
  final LeitnerCard card;
  final double stability;
  final double forgettingRisk;
  final double confidence;
}

class ConfusionPair {
  const ConfusionPair(this.a, this.b, this.score);
  final LeitnerCard a;
  final LeitnerCard b;
  final double score;
}

class SmartEngine {
  static List<Map<String, dynamic>> history(GliaStore store, String id) =>
      store.answerHistory[id] ?? const <Map<String, dynamic>>[];

  static int wrongCount(GliaStore store, String id) => history(store, id)
      .where((e) => e['result'] == 'review' || e['result'] == 'wrong' || e['status'] == 'wrong').length;

  static int correctCount(GliaStore store, String id) => history(store, id)
      .where((e) => e['result'] == 'known' || e['status'] == 'correct').length;

  static SmartDifficulty difficulty(GliaStore store, LeitnerCard card) {
    final box = store.boxFor(card.id);
    final wrong = wrongCount(store, card.id);
    if (wrong >= 3) return SmartDifficulty.critical;
    if (wrong >= 1 || box <= 2) return SmartDifficulty.hard;
    if (box == 3) return SmartDifficulty.medium;
    return SmartDifficulty.easy;
  }

  static double falseMastery(GliaStore store, LeitnerCard card) {
    final h = history(store, card.id);
    if (h.length < 3 || store.boxFor(card.id) < 4) return 0;
    final recent = h.reversed.take(3).toList();
    final allCorrect = recent.every((e) => e['result'] == 'known' || e['status'] == 'correct');
    if (!allCorrect) return 0;
    final old = h.take(math.max(0, h.length - 3));
    final oldWrong = old.where((e) => e['result'] == 'review' || e['result'] == 'wrong' || e['status'] == 'wrong').length;
    return oldWrong > 0 ? math.min(1.0, .35 + oldWrong * .12) : .05;
  }

  static double forgettingRisk(GliaStore store, LeitnerCard card) {
    final box = store.boxFor(card.id);
    var risk = (6 - box) / 5.0;
    if (store.isDue(card.id)) risk += .35;
    risk += wrongCount(store, card.id) * .08;
    risk += falseMastery(store, card) * .25;
    return risk.clamp(0.0, 1.0);
  }

  static MemoryStability stability(GliaStore store, LeitnerCard card) {
    final h = history(store, card.id);
    final correct = correctCount(store, card.id);
    final total = h.length;
    final accuracy = total == 0 ? 0.0 : correct / total;
    final stable = ((store.boxFor(card.id) / 5.0) * .65 + accuracy * .35).clamp(0.0, 1.0);
    return MemoryStability(card: card, stability: stable, forgettingRisk: forgettingRisk(store, card), confidence: (stable * 100).roundToDouble());
  }

  static double priority(GliaStore store, LeitnerCard card) {
    var score = (6 - store.boxFor(card.id)) * 20.0;
    score += forgettingRisk(store, card) * 55;
    if (store.isDue(card.id)) score += 45;
    score += wrongCount(store, card.id) * 18;
    score += falseMastery(store, card) * 30;
    return score;
  }

  static List<SmartCardScore> rank(GliaStore store, List<LeitnerCard> cards) {
    final result = cards.map((c) => SmartCardScore(c, difficulty(store, c), priority(store, c))).toList();
    result.sort((a, b) => b.priority.compareTo(a.priority));
    return result;
  }

  static List<LeitnerCard> smartQueue(GliaStore store, List<LeitnerCard> cards, {int limit = 20}) =>
      rank(store, cards).take(limit).map((x) => x.card).toList();

  static List<LeitnerCard> criticalCards(GliaStore store, List<LeitnerCard> cards, {int limit = 30}) =>
      rank(store, cards).where((x) => x.difficulty == SmartDifficulty.critical).take(limit).map((x) => x.card).toList();

  static List<LeitnerCard> recoveryQueue(GliaStore store, List<LeitnerCard> cards, {int limit = 25}) =>
      rank(store, cards).take(limit).map((x) => x.card).toList();

  static List<LeitnerCard> knowledgeChain(GliaStore store, List<LeitnerCard> cards, LeitnerCard start, {int limit = 8}) {
    final sameLesson = cards.where((c) => c.lesson == start.lesson && c.id != start.id).toList();
    return [start, ...smartQueue(store, sameLesson, limit: math.max(1, limit - 1))];
  }

  static Map<String, int> weakLessons(GliaStore store, List<LeitnerCard> cards) {
    final out = <String, int>{};
    for (final c in cards) {
      if (store.boxFor(c.id) <= 2 || !store.isKnown(c.id) || forgettingRisk(store, c) >= .65) {
        out[c.lesson] = (out[c.lesson] ?? 0) + 1;
      }
    }
    final entries = out.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in entries.take(8)) e.key: e.value};
  }

  static int mastery(GliaStore store, List<LeitnerCard> cards) {
    if (cards.isEmpty) return 0;
    final total = cards.fold<int>(0, (sum, c) => sum + store.boxFor(c.id));
    return ((total / (cards.length * 5)) * 100).round().clamp(0, 100);
  }

  static int readiness(GliaStore store, List<LeitnerCard> cards) {
    final base = mastery(store, cards);
    final accuracy = store.reviewed == 0 ? 0 : ((store.correct / store.reviewed) * 100).round();
    final risk = cards.isEmpty ? 0 : (cards.map((c) => forgettingRisk(store, c)).reduce((a, b) => a + b) / cards.length);
    return ((base * .55) + (accuracy * .25) + ((1 - risk) * 100 * .20)).round().clamp(0, 100);
  }

  static String coach(GliaStore store, List<LeitnerCard> cards) {
    final weak = weakLessons(store, cards);
    final due = cards.where((c) => store.isDue(c.id)).length;
    final accuracy = store.reviewed == 0 ? 0 : ((store.correct / store.reviewed) * 100).round();
    final critical = criticalCards(store, cards).length;
    if (store.reviewed == 0) return 'هنوز داده کافی نداریم؛ یک مرور کوتاه شروع کن تا مربی هوشمند الگوی یادگیری‌ات را پیدا کند.';
    if (critical > 0) return '${critical} کارت بحرانی داری. اول آن‌ها را مرور کن؛ بعد سراغ کارت‌های موعددار برو.';
    if (weak.isNotEmpty) return 'تمرکز بعدی روی «${weak.keys.first}» است. ${due} کارت موعددار داری و دقت فعلی‌ات ${accuracy}٪ است.';
    if (accuracy < 70) return 'امروز مرورهای کوتاه و تکراری داشته باش؛ دقت فعلی ${accuracy}٪ است.';
    return 'عملکردت خوب است؛ ${due} کارت موعددار را جمع کن و سپس یک چالش کوتاه انجام بده.';
  }

  static List<LeitnerCard> challenge(GliaStore store, List<LeitnerCard> cards, {int limit = 20}) =>
      rank(store, cards).take(limit).map((x) => x.card).toList();

  static List<SpellingQuestion> adaptiveQuestions(GliaStore store, List<SpellingQuestion> questions, {int limit = 20}) {
    final copy = List<SpellingQuestion>.of(questions);
    copy.sort((a, b) => wrongCount(store, b.id).compareTo(wrongCount(store, a.id)));
    return copy.take(limit).toList();
  }

  static String hint(LeitnerCard card) {
    final words = card.back.trim().split(RegExp(r'\s+')).where((x) => x.isNotEmpty).toList();
    if (words.length > 1) return 'راهنما: به «${words.first}» و مفهوم کلی پاسخ فکر کن.';
    return 'راهنما: معنی و کاربرد «${card.front}» را بدون نگاه کردن به پاسخ به یاد بیاور.';
  }

  static String memoryTrick(LeitnerCard card) =>
      'ترفند حافظه: «${card.front.trim()}» را به «${card.back.trim()}» وصل کن و یک جملهٔ کوتاه شخصی برایش بساز.';

  static String explain(LeitnerCard card) {
    final extra = card.extra.trim();
    if (extra.isNotEmpty) return extra;
    return 'این کارت برای تثبیت ارتباط بین «${card.front}» و «${card.back}» است. ابتدا پاسخ را از حافظه بگو، سپس کارت را برگردان و نتیجه را ثبت کن.';
  }

  static String recoveryCoach(GliaStore store, List<LeitnerCard> cards) {
    final missed = cards.where((c) => !store.isKnown(c.id)).length;
    if (missed == 0) return 'عالیه؛ عقب‌افتادگی نداری.';
    final n = math.min(10, missed);
    return 'برای برگشت بعد از وقفه، امروز فقط ${n} کارت اولویت‌دار را مرور کن؛ جلسه را کوتاه نگه دار و فشار را تدریجی بالا ببر.';
  }
}