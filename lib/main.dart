import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
      title: 'گلیا کنکور',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0B0F1A),
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
      ..setBackgroundColor(const Color(0xFF0B0F1A))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadFlutterAsset('assets/leitner.html');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F1A),
      body: SafeArea(
        bottom: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            WebViewWidget(controller: _controller),
            if (_loading)
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
    );
  }
}
