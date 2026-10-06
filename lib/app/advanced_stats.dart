import 'package:flutter/material.dart';
import '../models/native_models.dart';
import '../services/native_store.dart';
import '../services/smart_engine.dart';

const _statsBg = Color(0xFF0B0F1A);
const _statsSurface = Color(0xFF171E2E);
const _statsSurface2 = Color(0xFF1D2740);
const _statsGold = Color(0xFFF4C777);
const _statsTeal = Color(0xFF78D9D6);
const _statsRose = Color(0xFFE8674F);
const _statsDim = Color(0xFF9AA3B8);

/// داشبورد آماری کامل و کاملاً آفلاین گلیا.
/// داده‌ها مستقیماً از وضعیت لایتنر و تاریخچه پاسخ‌های محلی خوانده می‌شوند.
class AdvancedStats extends StatefulWidget {
  const AdvancedStats({super.key, required this.data, required this.store});
  final NativeData data;
  final GliaStore store;

  @override
  State<AdvancedStats> createState() => _AdvancedStatsState();
}

class _AdvancedStatsState extends State<AdvancedStats> {
  int rangeDays = 7;

  @override
  Widget build(BuildContext context) {
    final cards = widget.data.allCards;
    final reviewed = widget.store.reviewed;
    final correct = widget.store.correct;
    final accuracy = reviewed == 0 ? 0.0 : correct / reviewed;
    final known = cards.where((c) => widget.store.isKnown(c.id)).length;
    final due = cards.where((c) => widget.store.isDue(c.id)).length;
    final weak = cards.where((c) => widget.store.boxFor(c.id) <= 2).length;
    final mastery = cards.isEmpty ? 0.0 : known / cards.length;
    final readiness = SmartEngine.readiness(widget.store, cards);
    final critical = SmartEngine.criticalCards(widget.store, cards);
    final falseMastery = cards.where((c) => SmartEngine.falseMastery(widget.store, c) >= .35).length;
    final forgettingRisk = cards.isEmpty
        ? 0.0
        : cards.map((c) => SmartEngine.forgettingRisk(widget.store, c)).fold<double>(0, (a, b) => a + b) / cards.length;
    final lessons = _lessonStats(cards);
    final topLessons = lessons.entries.toList()..sort((a, b) => b.value.accuracy.compareTo(a.value.accuracy));
    final weakLessons = lessons.entries.toList()..sort((a, b) => a.value.accuracy.compareTo(b.value.accuracy));
    final recent = _recentHistory(cards, rangeDays);

    return Scaffold(
      backgroundColor: _statsBg,
      appBar: AppBar(
        title: const Text('آمار حرفه‌ای'),
        backgroundColor: _statsBg,
        actions: [
          PopupMenuButton<int>(
            initialValue: rangeDays,
            onSelected: (v) => setState(() => rangeDays = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 7, child: Text('۷ روز اخیر')),
              PopupMenuItem(value: 30, child: Text('۳۰ روز اخیر')),
              PopupMenuItem(value: 90, child: Text('۹۰ روز اخیر')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _hero(readiness, mastery, accuracy, widget.store.streak),
          const SizedBox(height: 12),
          _sectionTitle('نمای کلی'),
          _grid([
            _metric('کل مرورها', '$reviewed', Icons.repeat, _statsTeal),
            _metric('پاسخ درست', '$correct', Icons.check_circle, _statsTeal),
            _metric('کارت‌های مسلط', '$known', Icons.workspace_premium, _statsGold),
            _metric('آماده مرور', '$due', Icons.schedule, _statsRose),
            _metric('کارت‌های ضعیف', '$weak', Icons.warning_amber, _statsRose),
            _metric('استریک', '${widget.store.streak} روز', Icons.local_fire_department, _statsGold),
          ]),
          const SizedBox(height: 14),
          _sectionTitle('روند عملکرد'),
          _trendCard(recent, rangeDays),
          const SizedBox(height: 14),
          _sectionTitle('نقاط قوت و ضعف درس‌ها'),
          _lessonRanking(topLessons.take(5).toList(), true),
          const SizedBox(height: 8),
          _lessonRanking(weakLessons.take(5).toList(), false),
          const SizedBox(height: 14),
          _sectionTitle('نقشه حافظه'),
          _memoryCard(mastery, forgettingRisk, critical.length, falseMastery),
          const SizedBox(height: 14),
          _sectionTitle('تحلیل هوشمند'),
          _coachCard(readiness, accuracy, due, weak, critical.length, falseMastery),
          const SizedBox(height: 14),
          _sectionTitle('رکوردها'),
          _recordsCard(widget.store, recent),
          const SizedBox(height: 14),
          _sectionTitle('گزارش هفتگی'),
          _weeklyReport(reviewed, correct, mastery, readiness, weakLessons.take(3).toList()),
        ],
      ),
    );
  }

  Widget _hero(int readiness, double mastery, double accuracy, int streak) => Card(
        color: _statsSurface,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.insights, color: _statsTeal, size: 30),
              const SizedBox(width: 10),
              const Expanded(child: Text('وضعیت فعلی یادگیری', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900))),
              Text('$readiness٪', style: const TextStyle(color: _statsGold, fontSize: 28, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 14),
            ClipRRect(borderRadius: BorderRadius.circular(20), child: LinearProgressIndicator(value: readiness / 100, minHeight: 11, color: _statsTeal, backgroundColor: _statsSurface2)),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _mini('${(mastery * 100).round()}٪', 'تسلط'),
              _mini('${(accuracy * 100).round()}٪', 'دقت'),
              _mini('$streak', 'استریک'),
            ]),
          ]),
        ),
      );

  Widget _grid(List<Widget> children) => GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 9, mainAxisSpacing: 9, childAspectRatio: 1.75, children: children);

  Widget _metric(String title, String value, IconData icon, Color color) => Card(
        color: _statsSurface,
        child: Padding(padding: const EdgeInsets.all(13), child: Row(children: [Icon(icon, color: color, size: 25), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), Text(title, style: const TextStyle(color: _statsDim, fontSize: 12))]))])),
      );

  Widget _mini(String value, String label) => Column(children: [Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: _statsTeal)), const SizedBox(height: 3), Text(label, style: const TextStyle(color: _statsDim, fontSize: 12))]);

  Widget _sectionTitle(String text) => Padding(padding: const EdgeInsets.only(bottom: 7), child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)));

  Widget _trendCard(Map<DateTime, _DayStat> points, int days) {
    final values = List.generate(days, (i) {
      final d = DateTime.now().subtract(Duration(days: days - i - 1));
      return points[_day(d)] ?? const _DayStat();
    });
    final maxValue = values.fold<int>(1, (m, x) => x.reviewed > m ? x.reviewed : m);
    return Card(color: _statsSurface, child: Padding(padding: const EdgeInsets.fromLTRB(14, 16, 14, 12), child: Column(children: [
      Row(children: [const Icon(Icons.show_chart, color: _statsTeal), const SizedBox(width: 8), Text('$days روز اخیر', style: const TextStyle(fontWeight: FontWeight.w800)), const Spacer(), Text('${values.fold<int>(0, (a, b) => a + b.reviewed)} مرور', style: const TextStyle(color: _statsDim))]),
      const SizedBox(height: 16),
      SizedBox(height: 120, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [for (final x in values) Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [Text('${x.reviewed}', style: const TextStyle(fontSize: 9, color: _statsDim)), const SizedBox(height: 4), AnimatedContainer(duration: const Duration(milliseconds: 350), height: 8 + 78 * x.reviewed / maxValue, decoration: BoxDecoration(color: _statsTeal.withValues(alpha: .72), borderRadius: BorderRadius.circular(7))), const SizedBox(height: 4), Text('${x.date.day}', style: const TextStyle(fontSize: 9, color: _statsDim))])))])),
    ])));
  }

  Widget _lessonRanking(List<MapEntry<String, _LessonStat>> items, bool strengths) => Card(color: _statsSurface, child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
        Row(children: [Icon(strengths ? Icons.emoji_events : Icons.warning_amber, color: strengths ? _statsGold : _statsRose), const SizedBox(width: 8), Text(strengths ? 'بهترین درس‌ها' : 'نیازمند توجه', style: const TextStyle(fontWeight: FontWeight.w800))]),
        const SizedBox(height: 8),
        if (items.isEmpty) const Text('هنوز داده کافی نداریم.', style: TextStyle(color: _statsDim)) else for (final e in items) Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Column(children: [Row(children: [Expanded(child: Text(e.key, maxLines: 1, overflow: TextOverflow.ellipsis)), Text('${(e.value.accuracy * 100).round()}٪', style: TextStyle(color: strengths ? _statsTeal : _statsRose, fontWeight: FontWeight.w900))]), const SizedBox(height: 5), ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: e.value.accuracy.clamp(0, 1), minHeight: 7, color: strengths ? _statsTeal : _statsRose, backgroundColor: _statsSurface2))]))
      ]));

  Widget _memoryCard(double mastery, double risk, int critical, int falseMastery) => Card(color: _statsSurface, child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        _bar('تسلط کلی', mastery, _statsTeal),
        _bar('ریسک فراموشی', risk, _statsRose),
        const SizedBox(height: 8),
        Row(children: [Expanded(child: _miniBox('$critical', 'کارت بحرانی', _statsRose)), const SizedBox(width: 8), Expanded(child: _miniBox('$falseMastery', 'یادگیری کاذب', _statsGold))]),
      ]));

  Widget _bar(String label, double value, Color color) => Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Column(children: [Row(children: [Expanded(child: Text(label)), Text('${(value * 100).round()}٪', style: TextStyle(color: color, fontWeight: FontWeight.w900))]), const SizedBox(height: 6), ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: value.clamp(0, 1), minHeight: 8, color: color, backgroundColor: _statsSurface2))]));

  Widget _miniBox(String value, String label, Color color) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _statsSurface2, borderRadius: BorderRadius.circular(14)), child: Row(children: [Icon(Icons.circle, size: 9, color: color), const SizedBox(width: 7), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), Text(label, style: const TextStyle(color: _statsDim, fontSize: 11))]))]));

  Widget _coachCard(int readiness, double accuracy, int due, int weak, int critical, int falseMastery) {
    final tips = <String>[];
    if (due > 0) tips.add('$due کارت موعد مرور دارند؛ اول آن‌ها را انجام بده.');
    if (accuracy < .7) tips.add('دقت فعلی پایین است؛ تعداد کارت‌های جدید را موقتاً کمتر کن.');
    if (weak > 0) tips.add('$weak کارت در خانه‌های ضعیف قرار دارند و ارزش مرور بیشتری دارند.');
    if (critical > 0) tips.add('$critical کارت ریسک بالایی دارند؛ مرور هوشمند را اجرا کن.');
    if (falseMastery > 0) tips.add('$falseMastery کارت مشکوک به یادگیری کاذب‌اند؛ چند مرور فاصله‌دار برایشان مفید است.');
    if (tips.isEmpty) tips.add('روند یادگیری خوب است؛ همین ریتم را حفظ کن.');
    return Card(color: _statsSurface, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.psychology, color: _statsTeal), const SizedBox(width: 8), const Text('پیشنهاد مربی هوشمند', style: TextStyle(fontWeight: FontWeight.w900))]), const SizedBox(height: 8), Text('شاخص آمادگی: $readiness٪', style: const TextStyle(color: _statsGold, fontWeight: FontWeight.w900)), const SizedBox(height: 8), for (final tip in tips) Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('• $tip', style: const TextStyle(color: _statsDim, height: 1.45)))])));
  }

  Widget _recordsCard(GliaStore store, Map<DateTime, _DayStat> recent) => Card(color: _statsSurface, child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        _record('🔥', 'بهترین استریک فعلی', '${store.streak} روز'),
        _record('🎯', 'بیشترین مرور در بازه', '${recent.values.fold<int>(0, (m, x) => x.reviewed > m ? x.reviewed : m)} کارت'),
        _record('✅', 'مجموع پاسخ درست', '${store.correct}'),
        _record('📚', 'کل کارت‌ها', '${widget.data.allCards.length}'),
      ]));

  Widget _record(String emoji, String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [Text(emoji, style: const TextStyle(fontSize: 18)), const SizedBox(width: 10), Expanded(child: Text(label)), Text(value, style: const TextStyle(fontWeight: FontWeight.w900, color: _statsTeal))]));

  Widget _weeklyReport(int reviewed, int correct, double mastery, int readiness, List<MapEntry<String, _LessonStat>> weakLessons) => Card(color: _statsSurface, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('گزارش قابل‌فهم هفته', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        const SizedBox(height: 10),
        Text('این هفته $reviewed مرور ثبت شده و ${correct == 0 ? 'هنوز پاسخ درست ثبت نشده' : '$correct پاسخ درست'} داری. میزان تسلط فعلی ${(mastery * 100).round()}٪ و شاخص آمادگی $readiness٪ است.', style: const TextStyle(height: 1.7)),
        if (weakLessons.isNotEmpty) ...[const SizedBox(height: 8), Text('درس‌هایی که بهتر است بیشتر روی آن‌ها کار کنی: ${weakLessons.map((e) => e.key).join('، ')}.', style: const TextStyle(color: _statsRose, height: 1.6))],
      ]));

  Map<String, _LessonStat> _lessonStats(List<LeitnerCard> cards) {
    final result = <String, _LessonStat>{};
    for (final card in cards) {
      final key = card.lesson.trim().isEmpty ? 'بدون درس' : card.lesson.trim();
      final h = widget.store.answerHistory[card.id] ?? const <Map<String, dynamic>>[];
      final right = h.where((x) => x['result'] == 'known' || x['status'] == 'correct' || x['result'] == 'correct').length;
      final wrong = h.where((x) => x['result'] == 'review' || x['result'] == 'wrong' || x['status'] == 'wrong').length;
      final old = result[key] ?? const _LessonStat();
      result[key] = _LessonStat(cards: old.cards + 1, right: old.right + right, wrong: old.wrong + wrong);
    }
    return result;
  }

  Map<DateTime, _DayStat> _recentHistory(List<LeitnerCard> cards, int days) {
    final map = <DateTime, _DayStat>{};
    final start = DateTime.now().subtract(Duration(days: days - 1));
    for (final card in cards) {
      for (final event in widget.store.answerHistory[card.id] ?? const <Map<String, dynamic>>[]) {
        final raw = event['time'] ?? event['timestamp'] ?? event['date'];
        final date = raw is int ? DateTime.fromMillisecondsSinceEpoch(raw) : DateTime.tryParse('$raw');
        if (date == null || date.isBefore(DateTime(start.year, start.month, start.day))) continue;
        final key = _day(date);
        final old = map[key] ?? _DayStat(date: key);
        final good = event['result'] == 'known' || event['result'] == 'correct' || event['status'] == 'correct';
        map[key] = old.copyWith(reviewed: old.reviewed + 1, correct: old.correct + (good ? 1 : 0));
      }
    }
    return map;
  }

  DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
}

class _LessonStat {
  const _LessonStat({this.cards = 0, this.right = 0, this.wrong = 0});
  final int cards;
  final int right;
  final int wrong;
  int get attempts => right + wrong;
  double get accuracy => attempts == 0 ? 0 : right / attempts;
}

class _DayStat {
  const _DayStat({this.date = const DateTime(2000), this.reviewed = 0, this.correct = 0});
  final DateTime date;
  final int reviewed;
  final int correct;
  _DayStat copyWith({DateTime? date, int? reviewed, int? correct}) => _DayStat(date: date ?? this.date, reviewed: reviewed ?? this.reviewed, correct: correct ?? this.correct);
}

