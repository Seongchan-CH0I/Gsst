
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class KakaoLoginWebView extends StatefulWidget {
  final String kakaoLoginUrl;
  final String redirectUri;

  const KakaoLoginWebView({
    Key? key,
    required this.kakaoLoginUrl,
    required this.redirectUri,
  }) : super(key: key);

  @override
  _KakaoLoginWebViewState createState() => _KakaoLoginWebViewState();
}

class _KakaoLoginWebViewState extends State<KakaoLoginWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith(widget.redirectUri)) {
              // 리다이렉트 URI로 이동하면, code를 추출하여 이전 화면으로 전달
              final uri = Uri.parse(request.url);
              final authCode = uri.queryParameters['code'];
              Navigator.of(context).pop(authCode);
              return NavigationDecision.prevent; // 웹뷰 내에서 리다이렉트 방지
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.kakaoLoginUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('카카오 로그인'),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
