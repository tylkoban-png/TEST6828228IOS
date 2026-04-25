import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:audio_session/audio_session.dart';

const _bg = Color(0xFF0F0F0F);
const _surface = Color(0xFF1A1A1A);
const _accent = Color(0xFFFF0000);
const _textPri = Color(0xFFFFFFFF);
const _textSec = Color(0xFF9E9E9E);
const _divider = Color(0xFF2C2C2C);

Future<void> _setupAudio() async {
  try {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.none,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.longFormAudio,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: false,
    ));
    await session.setActive(true);
  } catch (e) {
    debugPrint("Audio Session Error: $e");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: _bg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  if (defaultTargetPlatform == TargetPlatform.android) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(false);
  }

  await _setupAudio();
  runApp(const _App());
}

class _App extends StatelessWidget {
  const _App();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _bg,
        colorScheme:
            const ColorScheme.dark(primary: _accent, surface: _surface),
        appBarTheme: const AppBarTheme(
          backgroundColor: _bg,
          foregroundColor: _textPri,
          elevation: 0,
          titleTextStyle: TextStyle(
              color: _textPri, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      home: const _Shell(),
    );
  }
}

class _Shell extends StatefulWidget {
  const _Shell();
  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> with WidgetsBindingObserver {
  int _idx = 0;
  final _pageCtrl = PageController();
  static final _ytKey = GlobalKey<_YouTubeState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      _ytKey.currentState?.onBackground();
    } else if (state == AppLifecycleState.resumed) {
      await _setupAudio();
    }
  }

  void _onTap(int i) {
    setState(() => _idx = i);
    _pageCtrl.jumpToPage(i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageCtrl,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _Home(onOpenYT: () => _onTap(1)),
          _YouTube(key: _ytKey),
          const _Google(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: _onTap,
        selectedItemColor: _accent,
        unselectedItemColor: _textSec,
        backgroundColor: _bg,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Start'),
          BottomNavigationBarItem(
              icon: Icon(Icons.play_circle), label: 'YouTube'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Google'),
        ],
      ),
    );
  }
}

class _Home extends StatelessWidget {
  final VoidCallback onOpenYT;
  const _Home({required this.onOpenYT});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('YT Lite')),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _accent),
          onPressed: onOpenYT,
          child: const Text('Otwórz YouTube',
              style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}

class _YouTube extends StatefulWidget {
  const _YouTube({super.key});
  @override
  State<_YouTube> createState() => _YouTubeState();
}

class _YouTubeState extends State<_YouTube> with AutomaticKeepAliveClientMixin {
  InAppWebViewController? _ctrl;
  @override
  bool get wantKeepAlive => true;

  Future<void> onBackground() async {
    await _ctrl?.evaluateJavascript(
        source: "document.querySelector('video')?.play();");
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri('https://m.youtube.com')),
      initialSettings: InAppWebViewSettings(
        allowsInlineMediaPlayback: true,
        mediaPlaybackRequiresUserGesture: false,
        allowsPictureInPictureMediaPlayback: true,
        userAgent:
            'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1',
      ),
      onWebViewCreated: (c) => _ctrl = c,
    );
  }
}

class _Google extends StatelessWidget {
  const _Google();
  @override
  Widget build(BuildContext context) {
    return InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri('https://www.google.com')));
  }
}
