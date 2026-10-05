import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

const _bg = Color(0xFF0B0F1A);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GliaLeitnerApp());
}

class GliaLeitnerApp extends StatelessWidget {
  const GliaLeitnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'لایتنر هوشمند | گلیا کنکور',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _bg,
        useMaterial3: true,
      ),
      home: const LeitnerPage(),
    );
  }
}

class LeitnerPage extends StatefulWidget {
  const LeitnerPage({super.key});

  @override
  State<LeitnerPage> createState() => _LeitnerPageState();
}

class _LeitnerPageState extends State<LeitnerPage> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(_bg)
      ..addJavaScriptChannel(
        'GliaBridge',
        onMessageReceived: (_) {},
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) async {
            await _applyBrandingOverlay();
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadFlutterAsset('assets/leitner.html');
  }

  Future<void> _applyBrandingOverlay() async {
    final bytes = await rootBundle.load('assets/glia_app_icon.png');
    final image64 = base64Encode(bytes.buffer.asUint8List());
    final js = '''
(() => {
  const data = 'data:image/png;base64,$image64';
  const splash = document.querySelector('#splashLogo');
  if (splash) {
    const oldSvg = splash.querySelector('svg');
    if (oldSvg) oldSvg.remove();
    let img = splash.querySelector('img.glia-app-logo');
    if (!img) {
      img = document.createElement('img');
      img.className = 'glia-app-logo';
      img.alt = 'گلیا کنکور';
      img.style.cssText = 'width:100%;height:100%;display:block;object-fit:cover;border-radius:22px;';
      splash.insertBefore(img, splash.firstChild);
    }
    img.src = data;
  }

  const mark = document.querySelector('.brand-mark');
  if (mark) {
    const svg = mark.querySelector('svg');
    if (svg) svg.remove();
    let img = mark.querySelector('img.glia-brand-mark');
    if (!img) {
      img = document.createElement('img');
      img.className = 'glia-brand-mark';
      img.alt = '';
      img.style.cssText = 'width:100%;height:100%;display:block;object-fit:cover;border-radius:8px;';
      mark.appendChild(img);
    }
    img.src = data;
  }
})();
''';
    try {
      await _controller.runJavaScript(js);
    } catch (_) {
      // Cosmetic only; the original HTML application still runs.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        bottom: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            WebViewWidget(controller: _controller),
            if (_loading)
              const ColoredBox(
                color: _bg,
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      color: Color(0xFFE8A94C),
                      strokeWidth: 2.6,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
