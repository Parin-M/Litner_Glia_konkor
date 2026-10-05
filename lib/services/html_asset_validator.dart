class HtmlAssetValidator {
  const HtmlAssetValidator();

  void validate(String html) {
    const requiredMarkers = <String>[
      '<!DOCTYPE html>',
      'id="app"',
      'id="flipCard"',
      'id="judgeRow"',
      'function buildDeck()',
      'function buildStudyDeck(',
      'localStorage.getItem',
      'localStorage.setItem',
    ];

    final missing = <String>[
      for (final marker in requiredMarkers)
        if (!html.contains(marker)) marker,
    ];

    if (missing.isNotEmpty) {
      throw StateError(
        'فایل HTML مرجع ناقص یا تغییر داده شده است. '
        'نشانگرهای مفقود: ${missing.join(', ')}',
      );
    }
  }
}
