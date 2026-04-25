import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:audio_session/audio_session.dart';

void main() async {
  // 1. Inicjalizacja wiązań Fluttera
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Start aplikacji (najpierw pokazujemy ekran, żeby uniknąć crasha)
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: YTLiteApp(),
  ));

  // 3. Konfiguracja audio w tle po starcie
  _initAudioSafe();
}

Future<void> _initAudioSafe() async {
  try {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    await session.setActive(true);
  } catch (e) {
    print("Audio error: $e");
  }
}

class YTLiteApp extends StatefulWidget {
  const YTLiteApp({super.key});
  @override
  State<YTLiteApp> createState() => _YTLiteAppState();
}

class _YTLiteAppState extends State<YTLiteApp> {
  InAppWebViewController? webViewController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri("https://m.youtube.com")),
          initialSettings: InAppWebViewSettings(
            allowsInlineMediaPlayback: true,
            mediaPlaybackRequiresUserGesture: false,
            allowsPictureInPictureMediaPlayback: true,
          ),
          onWebViewCreated: (controller) => webViewController = controller,
        ),
      ),
    );
  }
}
