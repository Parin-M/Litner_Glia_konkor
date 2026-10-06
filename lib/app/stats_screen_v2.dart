import 'package:flutter/material.dart';

import '../services/native_store.dart';
import '../services/stats_engine.dart';
import '../services/user_content_store.dart';

class StatsScreenV2 extends StatelessWidget {
  const StatsScreenV2({super.key, required this.glia, required this.user});

  final GliaStore glia;
  final UserContentStore user;

  @override
  Widget build(BuildContext context) {
    final s = StatsEngine.calculate(glia, user);
    return Scaffold(
      appBar: AppBar(title: const Text('آمار و تحلیل عملکرد')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('وضعیت کلی', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _metric('دقت', '${(s.accuracy * 100).round()}٪', Icons.track_changes)),
            Expanded(child: _metric('مرور', '${s.totalReviews}', Icons.history)),
            Expanded(child: _metric('زنجیره', '${s.streak} روز', Icons.local_fire_department)),
          ]),
        ]))),
        const SizedBox(height: 12),
        Card(child: Column(children: [
          ListTile(leading: const Icon(Icons.today), title: const Text('امروز'), subtitle: Text('${s.todayReviews} پاسخ ثبت‌شده · دقت ${ (s.todayAccuracy * 100).round() }٪')),
          ListTile(leading: const Icon(Icons.schedule), title: const Text('کارت‌های آماده مرور'), subtitle: Text('${s.dueTotal} کارت · ${s.dueBuiltIn} آماده اصلی · ${s.dueUser} کارت شخصی')),
          ListTile(leading: const Icon(Icons.workspace_premium), title: const Text('تسلط'), subtitle: Text('${s.masteredTotal} کارت در خانه ۵ · ${s.masteredUser} کارت شخصی مسلط')),
        ])),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('نقاط ضعف', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          if (s.weakBuiltIn.isEmpty && s.weakUser.isEmpty) const Text('هنوز الگوی خطای کافی برای تحلیل نداریم.'),
          for (final item in [...s.weakBuiltIn, ...s.weakUser]) ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.warning_amber_rounded), title: Text(item)),
        ]))),
        const SizedBox(height: 12),
        Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('شاخص‌های کاربردی', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          _bar('تسلط بسته اصلی', glia.data.allCards.isEmpty ? 0 : s.masteredBuiltIn / glia.data.allCards.length),
          _bar('تسلط کارت‌های شخصی', s.totalUserCards == 0 ? 0 : s.masteredUser / s.totalUserCards),
          _bar('کارت‌های شخصی مرورشده', s.totalUserCards == 0 ? 0 : s.reviewedUserCards / s.totalUserCards),
        ]))),
      ]),
    );
  }

  Widget _metric(String title, String value, IconData icon) => Column(children: [Icon(icon, size: 28), const SizedBox(height: 5), Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)), Text(title, style: const TextStyle(fontSize: 12))]);

  Widget _bar(String title, double value) => Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$title · ${(value.clamp(0, 1) * 100).round()}٪'), const SizedBox(height: 5), LinearProgressIndicator(value: value.clamp(0, 1))]));
}
