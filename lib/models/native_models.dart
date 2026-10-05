import 'dart:convert';

enum CardResult { review, later, known }

class LeitnerCard {
  const LeitnerCard({required this.id, required this.front, required this.back, required this.extra, required this.category, required this.lesson, required this.type});
  final String id, front, back, extra, category, lesson, type;

  factory LeitnerCard.fromJson(Map<String, dynamic> j) => LeitnerCard(
        id: j['id'] as String,
        front: j['front'] as String,
        back: j['back'] as String,
        extra: (j['extra'] ?? '') as String,
        category: j['category'] as String,
        lesson: j['lesson'] as String,
        type: j['type'] as String,
      );

  Map<String, dynamic> toJson() => {'id': id, 'front': front, 'back': back, 'extra': extra, 'category': category, 'lesson': lesson, 'type': type};
}

class SpellingQuestion {
  const SpellingQuestion({required this.id, required this.lesson, required this.sentence, required this.options, required this.correctIndex});
  final String id, lesson, sentence;
  final List<String> options;
  final int correctIndex;

  factory SpellingQuestion.fromJson(Map<String, dynamic> j) => SpellingQuestion(
        id: j['id'] as String,
        lesson: j['lesson'] as String,
        sentence: j['sentence'] as String,
        options: List<String>.from(j['options'] as List),
        correctIndex: (j['correctIndex'] as num).toInt(),
      );
}

class NativeData {
  const NativeData({required this.cards, required this.spelling, required this.persianPack});
  final List<LeitnerCard> cards;
  final List<SpellingQuestion> spelling;
  final List<LeitnerCard> persianPack;
  List<LeitnerCard> get allCards => [...cards, ...persianPack];

  factory NativeData.fromJson(String deckJson, String packJson) {
    final deck = (jsonDecode(deckJson) as List).map((e) => LeitnerCard.fromJson(Map<String, dynamic>.from(e as Map))).toList(growable: false);
    final pack = Map<String, dynamic>.from(jsonDecode(packJson) as Map);
    final questions = (pack['questions'] as List).map((e) => SpellingQuestion.fromJson(Map<String, dynamic>.from(e as Map))).toList(growable: false);
    final vocab = (pack['vocabCards'] as List).map((e) => LeitnerCard.fromJson(Map<String, dynamic>.from(e as Map))).toList(growable: false);
    if (deck.length != 2151 || questions.length != 639 || vocab.length != 434) {
      throw StateError('Native data integrity check failed: ${deck.length}/${questions.length}/${vocab.length}');
    }
    return NativeData(cards: deck, spelling: questions, persianPack: vocab);
  }
}
