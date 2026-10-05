import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/app_constants.dart';
import '../models/webview_shell_state.dart';
import 'html_asset_validator.dart';

class LeitnerWebViewService {
  LeitnerWebViewService({
    HtmlAssetValidator validator = const HtmlAssetValidator(),
  }) : _validator = validator;

  final HtmlAssetValidator _validator;
  final ValueNotifier<WebViewShellState> state = ValueNotifier(
    const WebViewShellState(status: WebViewShellStatus.loading),
  );

  late final WebViewController controller;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;

    state.value = const WebViewShellState(
      status: WebViewShellStatus.loading,
      progress: 0,
    );

    final html = await rootBundle.loadString(AppConstants.htmlAsset);
    _validator.validate(html);

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0B0F1A))
      ..setVerticalScrollBarEnabled(false)
      ..setHorizontalScrollBarEnabled(false)
      ..addJavaScriptChannel(
        'GliaBridge',
        onMessageReceived: _onBridgeMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            state.value = state.value.copyWith(
              progress: progress.clamp(0, 100),
            );
          },
          onPageStarted: (_) {
            state.value = state.value.copyWith(
              status: WebViewShellStatus.loading,
              progress: 0,
              clearError: true,
            );
          },
          onPageFinished: (_) async {
            await _applyBranding();
            state.value = state.value.copyWith(
              status: WebViewShellStatus.ready,
              progress: 100,
              clearError: true,
            );
          },
          onNavigationRequest: _onNavigationRequest,
          onWebResourceError: (error) {
            if (error.isForMainFrame == true) {
              state.value = state.value.copyWith(
                status: WebViewShellStatus.error,
                errorMessage:
                    '${error.description} (code ${error.errorCode})',
              );
            }
          },
        ),
      );

    _initialized = true;
    state.value = const WebViewShellState(
      status: WebViewShellStatus.loading,
      progress: 0,
    );

    await controller.loadFlutterAsset(AppConstants.htmlAsset);
  }

  Future<void> reload() async {
    if (!_initialized) {
      await initialize();
      return;
    }

    state.value = const WebViewShellState(
      status: WebViewShellStatus.loading,
      progress: 0,
    );
    await controller.reload();
  }

  Future<bool> goBackIfPossible() async {
    if (!_initialized) return false;

    final canGoBack = await controller.canGoBack();
    if (!canGoBack) return false;

    await controller.goBack();
    return true;
  }

  void dispose() {
    state.dispose();
  }

  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.prevent;

    if (uri.scheme == 'file' || uri.scheme == 'about') {
      return NavigationDecision.navigate;
    }

    if (uri.scheme == 'https' && uri.host.isNotEmpty) {
      _openExternal(uri);
      return NavigationDecision.prevent;
    }

    return NavigationDecision.prevent;
  }

  Future<void> _openExternal(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (error) {
      debugPrint('External launch failed: $error');
    }
  }

  void _onBridgeMessage(JavaScriptMessage message) {
    debugPrint('GliaBridge: ${message.message}');
  }

  Future<void> _applyBranding() async {
    final bytes = await rootBundle.load(AppConstants.logoAsset);
    final image64 = base64Encode(bytes.buffer.asUint8List());

    final script = '''
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
      img.style.cssText =
        'width:100%;height:100%;display:block;object-fit:cover;border-radius:22px;';
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
      img.style.cssText =
        'width:100%;height:100%;display:block;object-fit:cover;border-radius:8px;';
      mark.appendChild(img);
    }
    img.src = data;
  }

  document.documentElement.setAttribute('data-glia-native-shell', '1');
})();
''';

    try {
      await controller.runJavaScript(script);
    } catch (error) {
      debugPrint('Branding overlay failed: $error');
    }
  }
}
