import 'dart:math' as math;

import 'native_store.dart';
import 'user_content_store.dart';

class StudyStats {
  const StudyStats({
    required this.totalReviews,
    required this.correctAnswers,
    required this.accuracy,
    required this.streak,
    required this.dueBuiltIn,
    required this.dueUser,
    required this.masteredBuiltIn,
    required this.masteredUser,
    required this.totalUserCards,
    required this.reviewedUserCards,
    required this.weakBuiltIn,
    required this.weakUser,
    required this.todayReviews,
    required this.todayCorrect,
  });

  final int totalReviews;
  final int correctAnswers;
  final double accuracy;
  final int streak;
  final int dueBuiltIn;
  final int dueUser;
  final int masteredBuiltIn;
  final int masteredUser;
  final int totalUserCards;
  final int reviewedUserCards;
  final List<String> weakBuiltIn;
  final List<String> weakUser;
  final int todayReviews;
  final int todayCorrect;

  int get dueTotal => dueBuiltIn + dueUser;
  int get masteredTotal => masteredBuiltIn + masteredUser;
  double get todayAccuracy => todayReviews == 0 ? 0 : todayCorrect / todayReviews;
}

class StatsEngine {
  static StudyStats calculate(GliaStore glia, UserContentStore user) {
    final cards = glia.data.allCards;
    final dueBuiltIn = cards.where((c) => glia.isDue(c.id)).length;
    final masteredBuiltIn = cards.where((c) => glia.isKnown(c.id)).length;
    final dueUser = user.cards.where((c) => c.isDue).length;
    final masteredUser = user.cards.where((c) => c.box >= 5 && !c.isDue).length;

    final weakBuiltIn = <MapEntry<String, int>>[];
    for (final c in cards) {
      final history = glia.answerHistory[c.id] ?? const <Map<String, dynamic>>[];
      final wrong = history.where((e) => e['result'] == 'review' || e['result'] == 'wrong').length;
      if (wrong > 0) weakBuiltIn.add(MapEntry(c.lesson, wrong));
    }
    weakBuiltIn.sort((a, b) => b.value.compareTo(a.value));

    final weakUser = <MapEntry<String, int>>[];
    for (final c in user.cards) {
      final wrong = math.max(0, c.reviewed - c.correct);
      if (wrong > 0) weakUser.add(MapEntry(c.lesson.isEmpty ? 'بدون درس' : c.lesson, wrong));
    }
    weakUser.sort((a, b) => b.value.compareTo(a.value));

    final todayStart = DateTime.now();
    final start = DateTime(todayStart.year, todayStart.month, todayStart.day).millisecondsSinceEpoch;
    var todayReviews = 0;
    var todayCorrect = 0;
    for (final history in glia.answerHistory.values) {
      for (final event in history) {
        final time = (event['time'] as num?)?.toInt() ?? 0;
        if (time >= start) {
          todayReviews++;
          if (event['result'] == 'known' || event['status'] == 'correct') todayCorrect++;
        }
      }
    }
    for (final c in user.cards) {
      // UserCard stores cumulative counts; today's exact history is intentionally not inferred.
      // This keeps the statistic honest instead of inventing a daily value.
      if (c.reviewed == 0) continue;
    }

    return StudyStats(
      totalReviews: glia.reviewed + user.cards.fold(0, (sum, c) => sum + c.reviewed),
      correctAnswers: glia.correct + user.cards.fold(0, (sum, c) => sum + c.correct),
      accuracy: (glia.reviewed + user.cards.fold(0, (sum, c) => sum + c.reviewed)) == 0
          ? 0
          : (glia.correct + user.cards.fold(0, (sum, c) => sum + c.correct)) /
              (glia.reviewed + user.cards.fold(0, (sum, c) => sum + c.reviewed)),
      streak: glia.streak,
      dueBuiltIn: dueBuiltIn,
      dueUser: dueUser,
      masteredBuiltIn: masteredBuiltIn,
      masteredUser: masteredUser,
      totalUserCards: user.cards.length,
      reviewedUserCards: user.cards.where((c) => c.reviewed > 0).length,
      weakBuiltIn: weakBuiltIn.take(5).map((e) => '${e.key} · ${e.value} اشتباه').toList(),
      weakUser: weakUser.take(5).map((e) => '${e.key} · ${e.value} اشتباه').toList(),
      todayReviews: todayReviews,
      todayCorrect: todayCorrect,
    );
  }
}
