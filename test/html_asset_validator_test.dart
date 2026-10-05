import 'package:flutter_test/flutter_test.dart';
import 'package:glia_leitner/services/html_asset_validator.dart';

void main() {
  const validator = HtmlAssetValidator();

  test('accepts the expected Leitner HTML markers', () {
    const html = '''
<!DOCTYPE html>
<div id="app"></div>
<div id="flipCard"></div>
<div id="judgeRow"></div>
<script>
function buildDeck() {}
function buildStudyDeck(cat) {}
localStorage.getItem('x');
localStorage.setItem('x', 'y');
</script>
''';

    expect(() => validator.validate(html), returnsNormally);
  });

  test('rejects a broken or partial HTML asset', () {
    expect(
      () => validator.validate('<html></html>'),
      throwsA(isA<StateError>()),
    );
  });
}
