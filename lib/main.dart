import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:audio_session/audio_session.dart';

void main() async {
  // Gwarantuje, że Flutter jest gotowy
  WidgetsFlutterBinding.ensureInitialized();

  // Próbujemy ustawić audio, ale jeśli to ma wywalić apkę, ignorujemy błąd
  try {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    await session.setActive(true);
  } catch (e) {
    debugPrint("Audio setup failed but continuing: $e");
  }

  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SimpleYTApp(),
  ));
}

class SimpleYTApp extends StatefulWidget {
  const SimpleYTApp({super.key});
  @override
  State<SimpleYTApp> createState() => _SimpleYTAppState();
}

class _SimpleYTAppState extends State<SimpleYTApp> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: InAppWebView(
          initialUrlRequest: URLRequest(url: WebUri("https://m.youtube.com")),
          initialSettings: InAppWebViewSettings(
            allowsInlineMediaPlayback: true, // Kluczowe dla iOS
            mediaPlaybackRequiresUserGesture: false,
            allowsPictureInPictureMediaPlayback: true,
            userAgent:
                "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
          ),
        ),
      ),
    );
  }
}
