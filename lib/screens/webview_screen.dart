import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  static const String _gameUrl = 'https://positivephill.github.io/YouImageFlip/';
  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorDescription;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              setState(() {
                _isLoading = true;
                _hasError = false;
                _errorDescription = null;
              });
            },
            onPageFinished: (String url) {
              setState(() => _isLoading = false);
            },
            onWebResourceError: (WebResourceError error) {
              setState(() {
                _isLoading = false;
                _hasError = true;
                _errorDescription = error.description;
              });
            },
          ),
        )
        ..loadRequest(Uri.parse(_gameUrl));
      _controller = controller;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('YouImageFlip', style: TextStyle(color: colorScheme.onSurface)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: kIsWeb
          ? _WebOpenExternal(url: _gameUrl)
          : Stack(
              children: [
                if (_controller != null && !_hasError)
                  WebViewWidget(controller: _controller!),
                if (_hasError)
                  _WebErrorFallback(url: _gameUrl, error: _errorDescription),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
    );
  }
}

class _WebOpenExternal extends StatelessWidget {
  final String url;
  const _WebOpenExternal({required this.url});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.public, size: 48, color: colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                'Open game in a new tab',
                style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'For security reasons, browsers often block embedding external sites. Click below to continue to the game.',
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(url);
                  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open link.')));
                  }
                },
                icon: Icon(Icons.open_in_new, color: colorScheme.onPrimary),
                label: Text('Open YouImageFlip', style: TextStyle(color: colorScheme.onPrimary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WebErrorFallback extends StatelessWidget {
  final String url;
  final String? error;
  const _WebErrorFallback({required this.url, this.error});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 12),
              Text('Could not load the game', style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (error != null)
                Text(error!, style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(url);
                  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open link.')));
                  }
                },
                icon: Icon(Icons.open_in_new, color: colorScheme.onPrimary),
                label: Text('Open in Browser', style: TextStyle(color: colorScheme.onPrimary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
