import 'package:flutter/material.dart';
import '../services/leitner_box_config.dart';

class LeitnerBoxNamesScreen extends StatefulWidget {
  const LeitnerBoxNamesScreen({super.key, required this.config});
  final LeitnerBoxConfig config;
  @override State<LeitnerBoxNamesScreen> createState() => _LeitnerBoxNamesScreenState();
}

class _LeitnerBoxNamesScreenState extends State<LeitnerBoxNamesScreen> {
  late final List<TextEditingController> controllers;

  @override
  void initState() {
    super.initState();
    controllers = widget.config.names.map(TextEditingController.new).toList();
  }

  @override
  void dispose() {
    for (final c in controllers) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    for (var i = 0; i < controllers.length; i++) {
      await widget.config.rename(i + 1, controllers[i].text);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('نام‌گذاری خانه‌های لایتنر')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          const Text('نام خانه‌ها کاملاً دلخواه است؛ مثلاً «جدید»، «سخت»، «مرور روزانه»، «مسلط» و ...', style: TextStyle(height: 1.7)),
          const SizedBox(height: 14),
          for (var i = 0; i < controllers.length; i++) Card(child: Padding(padding: const EdgeInsets.all(12), child: TextField(controller: controllers[i], decoration: InputDecoration(labelText: 'خانه ${i + 1}', prefixIcon: const Icon(Icons.layers))))),
          const SizedBox(height: 8),
          FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('ذخیره نام‌ها')),
          TextButton(onPressed: () async { await widget.config.reset(); if (!mounted) return; setState(() { for (var i = 0; i < controllers.length; i++) controllers[i].text = widget.config.names[i]; }); }, child: const Text('بازگردانی نام‌های پیش‌فرض')),
        ],
      );
}
