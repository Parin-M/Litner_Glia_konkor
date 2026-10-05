import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GliaLeitnerApp());
}

class GliaLeitnerApp extends StatelessWidget {
  const GliaLeitnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'لایتنر هوشمند | گلیا کنکور',
      home: LeitnerWebViewPage(),
    );
  }
}

class LeitnerWebViewPage extends StatefulWidget {
  const LeitnerWebViewPage({super.key});

  @override
  State<LeitnerWebViewPage> createState() => _LeitnerWebViewPageState();
}

class _LeitnerWebViewPageState extends State<LeitnerWebViewPage> {
  late final WebViewController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0B0F1A))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _ready = true);
          },
          onWebResourceError: (_) {},
        ),
      )
      ..loadFlutterAsset('assets/leitner.html');
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0B0F1A),
        systemNavigationBarColor: Color(0xFF0B0F1A),
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0F1A),
        body: SafeArea(
          top: true,
          bottom: false,
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (!_ready)
                const ColoredBox(
                  color: Color(0xFF0B0F1A),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFFE8A94C),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
