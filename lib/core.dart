import 'package:flutter/material.dart';

abstract final class GColors {
  static const bg = Color(0xFF071226);
  static const surface = Color(0xFF0D1B33);
  static const surface2 = Color(0xFF122542);
  static const border = Color(0x263C7CB8);
  static const gold = Color(0xFFE9AF4E);
  static const gold2 = Color(0xFFF4CE79);
  static const cyan = Color(0xFF20D8E6);
  static const cyan2 = Color(0xFF67F2F5);
  static const green = Color(0xFF37D6A0);
  static const red = Color(0xFFFF647A);
  static const purple = Color(0xFFA66CFF);
  static const text = Color(0xFFF1F5FF);
  static const dim = Color(0xFF91A0BA);
}

abstract final class GConst {
  static const name = 'گلیا کنکور';
  static const version = '2.0.0';
  static const originalAsset = 'assets/generated_original_deck.json';
  static const packAsset = 'assets/generated_persian_pack.json';
  static const logoAsset = 'assets/glia_icon.png';
  static const channel = 'https://t.me/Glia_konkor';
  static const originalCount = 2151;
  static const spellingCount = 639;
  static const packVocabCount = 434;
}

ThemeData gliaTheme({required bool dark, required double fontScale}) {
  final base = dark ? Brightness.dark : Brightness.light;
  return ThemeData(
    useMaterial3: true,
    brightness: base,
    scaffoldBackgroundColor: dark ? GColors.bg : const Color(0xFFF4F1E9),
    colorScheme: ColorScheme.fromSeed(
      seedColor: GColors.cyan,
      brightness: base,
    ),
    textTheme: ThemeData(brightness: base).textTheme.apply(
      fontSizeFactor: fontScale,
      bodyColor: dark ? GColors.text : const Color(0xFF241E12),
      displayColor: dark ? GColors.text : const Color(0xFF241E12),
    ),
    appBarTheme: const AppBarTheme(centerTitle: false),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? const Color(0xE90A1930) : Colors.white,
      indicatorColor: GColors.cyan.withValues(alpha: .18),
    ),
  );
}
