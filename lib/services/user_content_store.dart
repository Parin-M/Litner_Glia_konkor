import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserDeck {
  const UserDeck({
    required this.id,
    required this.name,
    this.description = '',
    this.color = 0xFF78D9D6,
    this.createdAt = 0,
  });

  final String id;
  final String name;
  final String description;
  final int color;
  final int createdAt;

  UserDeck copyWith({String? name, String? description, int? color}) => UserDeck(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        color: color ?? this.color,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'color': color,
        'createdAt': createdAt,
      };

  factory UserDeck.fromJson(Map<String, dynamic> j) => UserDeck(
        id: '${j['id']}',
        name: '${j['name'] ?? 'دسته جدید'}',
        description: '${j['description'] ?? ''}',
        color: (j['color'] ?? 0xFF78D9D6) as int,
        createdAt: (j['createdAt'] ?? 0) as int,
      );
}

class UserCard {
  const UserCard({
    required this.id,
    required this.deckId,
    required this.front,
    required this.back,
    this.extra = '',
    this.lesson = '',
    this.frontImage,
    this.backImage,
    this.box = 1,
    this.nextReview = 0,
    this.createdAt = 0,
    this.reviewed = 0,
    this.correct = 0,
  });

  final String id;
  final String deckId;
  final String front;
  final String back;
  final String extra;
  final String lesson;
  final String? frontImage;
  final String? backImage;
  final int box;
  final int nextReview;
  final int createdAt;
  final int reviewed;
  final int correct;

  bool get isDue => nextReview <= DateTime.now().millisecondsSinceEpoch;

  UserCard copyWith({
    String? deckId,
    String? front,
    String? back,
    String? extra,
    String? lesson,
    String? frontImage,
    String? backImage,
    int? box,
    int? nextReview,
    int? reviewed,
    int? correct,
  }) => UserCard(
        id: id,
        deckId: deckId ?? this.deckId,
        front: front ?? this.front,
        back: back ?? this.back,
        extra: extra ?? this.extra,
        lesson: lesson ?? this.lesson,
        frontImage: frontImage ?? this.frontImage,
        backImage: backImage ?? this.backImage,
        box: box ?? this.box,
        nextReview: nextReview ?? this.nextReview,
        createdAt: createdAt,
        reviewed: reviewed ?? this.reviewed,
        correct: correct ?? this.correct,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'deckId': deckId,
        'front': front,
        'back': back,
        'extra': extra,
        'lesson': lesson,
        'frontImage': frontImage,
        'backImage': backImage,
        'box': box,
        'nextReview': nextReview,
        'createdAt': createdAt,
        'reviewed': reviewed,
        'correct': correct,
      };

  factory UserCard.fromJson(Map<String, dynamic> j) => UserCard(
        id: '${j['id']}',
        deckId: '${j['deckId']}',
        front: '${j['front'] ?? ''}',
        back: '${j['back'] ?? ''}',
        extra: '${j['extra'] ?? ''}',
        lesson: '${j['lesson'] ?? ''}',
        frontImage: j['frontImage']?.toString(),
        backImage: j['backImage']?.toString(),
        box: ((j['box'] ?? 1) as num).toInt().clamp(1, 5),
        nextReview: ((j['nextReview'] ?? 0) as num).toInt(),
        createdAt: ((j['createdAt'] ?? 0) as num).toInt(),
        reviewed: ((j['reviewed'] ?? 0) as num).toInt(),
        correct: ((j['correct'] ?? 0) as num).toInt(),
      );
}

class UserContentStore extends ChangeNotifier {
  static const _decksKey = 'glia_user_decks_v1';
  static const _cardsKey = 'glia_user_cards_v1';
  static const _backupVersion = 1;

  List<UserDeck> decks = <UserDeck>[];
  List<UserCard> cards = <UserCard>[];
  Directory? _root;
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final base = await getApplicationDocumentsDirectory();
    _root = Directory('${base.path}/glia_user_media');
    await _root!.create(recursive: true);
    try {
      decks = ((_prefs!.getString(_decksKey) == null)
              ? <dynamic>[]
              : jsonDecode(_prefs!.getString(_decksKey)!))
          .map<UserDeck>((e) => UserDeck.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      cards = ((_prefs!.getString(_cardsKey) == null)
              ? <dynamic>[]
              : jsonDecode(_prefs!.getString(_cardsKey)!))
          .map<UserCard>((e) => UserCard.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      decks = <UserDeck>[];
      cards = <UserCard>[];
    }
    notifyListeners();
  }

  String _id(String prefix) => '$prefix-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(99999)}';

  Future<void> _save() async {
    await _prefs?.setString(_decksKey, jsonEncode(decks.map((e) => e.toJson()).toList()));
    await _prefs?.setString(_cardsKey, jsonEncode(cards.map((e) => e.toJson()).toList()));
    notifyListeners();
  }

  UserDeck? deck(String id) {
    for (final d in decks) {
      if (d.id == id) return d;
    }
    return null;
  }

  List<UserCard> cardsFor(String deckId) => cards.where((c) => c.deckId == deckId).toList();

  Future<UserDeck> addDeck(String name, {String description = '', int color = 0xFF78D9D6}) async {
    final d = UserDeck(id: _id('deck'), name: name.trim().isEmpty ? 'دسته جدید' : name.trim(), description: description.trim(), color: color, createdAt: DateTime.now().millisecondsSinceEpoch);
    decks.add(d);
    await _save();
    return d;
  }

  Future<void> updateDeck(UserDeck deck) async {
    final i = decks.indexWhere((x) => x.id == deck.id);
    if (i >= 0) {
      decks[i] = deck;
      await _save();
    }
  }

  Future<void> deleteDeck(String deckId) async {
    cards.removeWhere((c) => c.deckId == deckId);
    decks.removeWhere((d) => d.id == deckId);
    await _save();
  }

  Future<String> saveImage(Uint8List bytes, {String extension = 'jpg'}) async {
    final safeExt = extension.toLowerCase().replaceAll('.', '').replaceAll(RegExp(r'[^a-z0-9]'), '');
    final file = File('${_root!.path}/${_id('img')}.$safeExt');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<UserCard> addCard({
    required String deckId,
    required String front,
    required String back,
    String extra = '',
    String lesson = '',
    Uint8List? frontImage,
    String frontExtension = 'jpg',
    Uint8List? backImage,
    String backExtension = 'jpg',
    int box = 1,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final card = UserCard(
      id: _id('card'),
      deckId: deckId,
      front: front.trim(),
      back: back.trim(),
      extra: extra.trim(),
      lesson: lesson.trim(),
      frontImage: frontImage == null ? null : await saveImage(frontImage, extension: frontExtension),
      backImage: backImage == null ? null : await saveImage(backImage, extension: backExtension),
      box: box.clamp(1, 5),
      nextReview: 0,
      createdAt: now,
    );
    cards.add(card);
    await _save();
    return card;
  }

  Future<void> updateCard(UserCard card, {Uint8List? newFrontImage, String frontExtension = 'jpg', Uint8List? newBackImage, String backExtension = 'jpg'}) async {
    final i = cards.indexWhere((x) => x.id == card.id);
    if (i < 0) return;
    var value = card;
    if (newFrontImage != null) value = value.copyWith(frontImage: await saveImage(newFrontImage, extension: frontExtension));
    if (newBackImage != null) value = value.copyWith(backImage: await saveImage(newBackImage, extension: backExtension));
    cards[i] = value;
    await _save();
  }

  Future<void> deleteCard(String id) async {
    final i = cards.indexWhere((x) => x.id == id);
    if (i < 0) return;
    final card = cards.removeAt(i);
    for (final p in [card.frontImage, card.backImage]) {
      if (p != null) {
        try {
          await File(p).delete();
        } catch (_) {}
      }
    }
    await _save();
  }

  Future<void> rate(UserCard card, bool known) async {
    final i = cards.indexWhere((x) => x.id == card.id);
    if (i < 0) return;
    final current = cards[i];
    final now = DateTime.now();
    final nextBox = known ? min(5, current.box + 1) : 1;
    const days = <int>[0, 0, 1, 3, 7, 14];
    cards[i] = current.copyWith(
      box: nextBox,
      nextReview: now.add(Duration(days: days[nextBox])).millisecondsSinceEpoch,
      reviewed: current.reviewed + 1,
      correct: current.correct + (known ? 1 : 0),
    );
    await _save();
  }

  UserCard? byId(String id) {
    for (final c in cards) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<Uint8List> buildBackup({Map<String, dynamic>? progress}) async {
    final archive = Archive();
    final manifest = <String, dynamic>{
      'format': 'GLIA_BACKUP',
      'version': _backupVersion,
      'createdAt': DateTime.now().toIso8601String(),
      'mediaIncluded': true,
    };
    archive.addFile(ArchiveFile.string('manifest.json', jsonEncode(manifest)));
    archive.addFile(ArchiveFile.string('decks.json', jsonEncode(decks.map((e) => e.toJson()).toList())));
    archive.addFile(ArchiveFile.string('cards.json', jsonEncode(cards.map((e) => e.toJson()).toList())));
    if (progress != null) archive.addFile(ArchiveFile.string('progress.json', jsonEncode(progress)));

    final paths = <String>{};
    for (final card in cards) {
      for (final p in [card.frontImage, card.backImage]) {
        if (p == null || p.isEmpty || !paths.add(p)) continue;
        final file = File(p);
        if (!await file.exists()) continue;
        final name = p.replaceAll('\\', '/').split('/').last;
        archive.addFile(ArchiveFile.bytes('media/$name', await file.readAsBytes()));
      }
    }
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  Future<void> restoreBackup(Uint8List bytes) async {
    final decoded = ZipDecoder().decodeBytes(bytes);
    final manifestFile = decoded.findFile('manifest.json');
    if (manifestFile == null) throw const FormatException('فایل پشتیبان گلیا معتبر نیست.');
    final manifest = Map<String, dynamic>.from(jsonDecode(utf8.decode(manifestFile.readBytes()!)));
    if (manifest['format'] != 'GLIA_BACKUP') throw const FormatException('فرمت فایل پشتیبان ناشناخته است.');

    final decksFile = decoded.findFile('decks.json');
    final cardsFile = decoded.findFile('cards.json');
    if (decksFile == null || cardsFile == null) throw const FormatException('اطلاعات کارت‌ها در پشتیبان ناقص است.');

    final mediaMap = <String, String>{};
    for (final entry in decoded) {
      if (!entry.isFile || !entry.name.startsWith('media/')) continue;
      final name = entry.name.split('/').last;
      final file = File('${_root!.path}/${_id('restore')}_$name');
      await file.writeAsBytes(entry.readBytes()!, flush: true);
      mediaMap[name] = file.path;
    }

    final importedDecks = (jsonDecode(utf8.decode(decksFile.readBytes()!)) as List)
        .map((e) => UserDeck.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    final importedCards = (jsonDecode(utf8.decode(cardsFile.readBytes()!)) as List)
        .map((e) => UserCard.fromJson(Map<String, dynamic>.from(e as Map))).toList();

    final deckIds = <String>{};
    for (final d in importedDecks) {
      final i = decks.indexWhere((x) => x.id == d.id);
      if (i >= 0) decks[i] = d; else decks.add(d);
      deckIds.add(d.id);
    }
    for (final c0 in importedCards) {
      if (!deckIds.contains(c0.deckId)) continue;
      final front = c0.frontImage == null ? null : mediaMap[c0.frontImage!.split(RegExp(r'[/\\]')).last];
      final back = c0.backImage == null ? null : mediaMap[c0.backImage!.split(RegExp(r'[/\\]')).last];
      final c = c0.copyWith(frontImage: front ?? c0.frontImage, backImage: back ?? c0.backImage);
      final i = cards.indexWhere((x) => x.id == c.id);
      if (i >= 0) cards[i] = c; else cards.add(c);
    }
    await _save();
  }
}
