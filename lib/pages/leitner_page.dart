import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/app_colors.dart';
import '../models/webview_shell_state.dart';
import '../services/leitner_webview_service.dart';

class LeitnerPage extends StatefulWidget {
  const LeitnerPage({super.key});

  @override
  State<LeitnerPage> createState() => _LeitnerPageState();
}

class _LeitnerPageState extends State<LeitnerPage> {
  late final LeitnerWebViewService _service;

  @override
  void initState() {
    super.initState();
    _service = LeitnerWebViewService();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _service.initialize();
    } catch (error) {
      _service.state.value = _service.state.value.copyWith(
        status: WebViewShellStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<bool> _handleBack() async {
    return !(await _service.goBackIfPossible());
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBack,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: ValueListenableBuilder<WebViewShellState>(
            valueListenable: _service.state,
            builder: (context, shellState, _) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  if (_service.isInitialized &&
                      shellState.status != WebViewShellStatus.error)
                    WebViewWidget(controller: _service.controller),
                  if (shellState.status == WebViewShellStatus.error)
                    _ErrorView(
                      message: shellState.errorMessage,
                      onRetry: () {
                        _initialize();
                      },
                    ),
                  if (shellState.status == WebViewShellStatus.loading)
                    IgnorePointer(
                      child: ColoredBox(
                        color: AppColors.background.withValues(alpha: 0.75),
                        child: Center(
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              value: shellState.progress > 0
                                  ? shellState.progress / 100
                                  : null,
                              strokeWidth: 2.5,
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 54,
              color: AppColors.danger,
            ),
            const SizedBox(height: 18),
            const Text(
              'بارگذاری برنامه انجام نشد',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message ?? 'خطای ناشناخته',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('تلاش دوباره'),
            ),
          ],
        ),
      ),
    );
  }
}
