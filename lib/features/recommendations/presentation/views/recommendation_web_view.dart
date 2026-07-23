import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class RecommendationWebView extends StatefulWidget {
  final String url;
  final String title;

  const RecommendationWebView({
    Key? key,
    required this.url,
    required this.title,
  }) : super(key: key);

  @override
  State<RecommendationWebView> createState() => _RecommendationWebViewState();
}

class _RecommendationWebViewState extends State<RecommendationWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}