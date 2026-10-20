import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glia_leitner/models/native_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled learning data parses and has unique card IDs', () async {
    final data = NativeData.fromJson(
      await rootBundle.loadString('assets/generated_original_deck.json'),
      await rootBundle.loadString('assets/generated_persian_pack.json'),
    );

    expect(data.cards, isNotEmpty);
    expect(data.spelling, isNotEmpty);
    expect(data.persianPack, isNotEmpty);
    final cardIds = data.allCards.map((card) => card.id).toSet();
    final questionIds = data.spelling.map((question) => question.id).toSet();
    expect(cardIds.length, data.allCards.length);
    expect(questionIds.length, data.spelling.length);
    expect(cardIds.intersection(questionIds), isEmpty);
    expect(
      data.spelling.every((question) =>
          question.correctIndex >= 0 && question.correctIndex < question.options.length),
      isTrue,
    );
  });
}
