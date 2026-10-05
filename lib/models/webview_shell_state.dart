enum WebViewShellStatus {
  loading,
  ready,
  error,
}

class WebViewShellState {
  const WebViewShellState({
    required this.status,
    this.progress = 0,
    this.errorMessage,
  });

  final WebViewShellStatus status;
  final int progress;
  final String? errorMessage;

  WebViewShellState copyWith({
    WebViewShellStatus? status,
    int? progress,
    String? errorMessage,
    bool clearError = false,
  }) {
    return WebViewShellState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
