import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:glia_leitner/models/native_models.dart';
import 'package:glia_leitner/services/native_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const card = LeitnerCard(
    id: 'test-card-1',
    front: 'remember',
    back: 'به خاطر آوردن',
    extra: '',
    category: 'english',
    lesson: 'test',
    type: 'vocabulary',
  );
  const secondCard = LeitnerCard(
    id: 'test-card-2',
    front: 'study',
    back: 'مطالعه کردن',
    extra: '',
    category: 'english',
    lesson: 'test',
    type: 'vocabulary',
  );
  const question = SpellingQuestion(
    id: 'test-question-1',
    lesson: 'test',
    sentence: 'نمونه',
    options: ['درست', 'نادرست'],
    correctIndex: 0,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('daily counters are tracked and mastery follows the Leitner box', () async {
    final data = NativeData(cards: const [card], spelling: const [question], persianPack: const [secondCard]);
    final store = GliaStore(data);
    await store.init();

    for (var i = 0; i < 5; i++) {
      await store.rateCard(card, CardResult.known);
    }

    expect(store.boxFor(card.id), 5);
    expect(store.isKnown(card.id), isTrue);
    expect(store.reviewed, 5);
    expect(store.correct, 5);
    expect(store.dailyReviewed, 5);
    expect(store.dailyCorrect, 5);
    expect(store.streak, 1);
  });

  test('invalid backup does not partially replace progress', () async {
    final data = NativeData(cards: const [card], spelling: const [question], persianPack: const [secondCard]);
    final store = GliaStore(data);
    await store.init();
    await store.rateCard(card, CardResult.known);
    final before = store.reviewed;

    await expectLater(
      store.restore({
        ...store.backup(),
        'cardBox': {'test-card-1': 'not-a-number'},
      }),
      throwsA(isA<FormatException>()),
    );

    expect(store.reviewed, before);
    expect(store.boxFor(card.id), 2);
  });
}
