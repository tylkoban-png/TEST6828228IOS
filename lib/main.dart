import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:audio_session/audio_session.dart';

// ── KOLORY (Video Lite style) ─────────────────────────────────────────────────
const _bg = Color(0xFF0F0F0F);
const _surface = Color(0xFF1A1A1A);
const _card = Color(0xFF242424);
const _accent = Color(0xFFFF0000); // czerwony YT
const _textPrim = Color(0xFFFFFFFF);
const _textSec = Color(0xFF9E9E9E);
const _divider = Color(0xFF2C2C2C);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: _bg,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final session = await AudioSession.instance;
  await session.configure(
    const AudioSessionConfiguration(
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
    ),
  );
  await session.setActive(true);

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
        colorScheme: const ColorScheme.dark(
          primary: _accent,
          surface: _surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _bg,
          foregroundColor: _textPrim,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: _textPrim,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          iconTheme: IconThemeData(color: _textPrim),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: _bg,
          selectedItemColor: _accent,
          unselectedItemColor: _textSec,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelStyle: TextStyle(fontSize: 11),
        ),
        dividerColor: _divider,
      ),
      home: const _Shell(),
    );
  }
}

// ── SHELL ─────────────────────────────────────────────────────────────────────
class _Shell extends StatefulWidget {
  const _Shell();
  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> with WidgetsBindingObserver {
  int _idx = 0;
  final _pageCtrl = PageController();
  static final youtubeKey = GlobalKey<_YouTubeState>();

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
      youtubeKey.currentState?.onBackground();
    } else if (state == AppLifecycleState.resumed) {
      final s = await AudioSession.instance;
      await s.setActive(true);
    }
  }

  void _onTap(int i) {
    setState(() => _idx = i);
    _pageCtrl.jumpToPage(i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: PageView(
        controller: _pageCtrl,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const _HomeScreen(),
          _YouTube(key: youtubeKey),
          const _GoogleScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: _divider, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _idx,
          onTap: _onTap,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Start',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.play_circle_outline),
              activeIcon: Icon(Icons.play_circle),
              label: 'YouTube',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search),
              label: 'Google',
            ),
          ],
        ),
      ),
    );
  }
}

// ── HOME ──────────────────────────────────────────────────────────────────────
class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            const Text('YT Lite'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Hero card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _divider, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Aktywny',
                    style: TextStyle(
                      color: _accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Muzyka w tle',
                  style: TextStyle(
                    color: _textPrim,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'YouTube gra nawet gdy zamkniesz aplikację lub zgasisz ekran.',
                  style: TextStyle(color: _textSec, fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Feature tiles
          Row(
            children: [
              _FeatureTile(
                icon: Icons.block,
                color: const Color(0xFF4CAF50),
                label: 'Bez reklam',
                sub: 'Auto-skip',
              ),
              const SizedBox(width: 12),
              _FeatureTile(
                icon: Icons.music_note,
                color: const Color(0xFF2196F3),
                label: 'Tło',
                sub: 'Audio działa',
              ),
              const SizedBox(width: 12),
              _FeatureTile(
                icon: Icons.speed,
                color: const Color(0xFFFF9800),
                label: 'Szybki',
                sub: '100ms skip',
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Quick access button
          GestureDetector(
            onTap: () {
              final shell = context.findAncestorStateOfType<_ShellState>();
              shell?._onTap(1);
            },
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow, color: Colors.white, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Otwórz YouTube',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String sub;
  const _FeatureTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _divider, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                color: _textPrim,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(sub, style: const TextStyle(color: _textSec, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ── YOUTUBE ───────────────────────────────────────────────────────────────────
class _YouTube extends StatefulWidget {
  const _YouTube({super.key});
  @override
  State<_YouTube> createState() => _YouTubeState();
}

class _YouTubeState extends State<_YouTube> with AutomaticKeepAliveClientMixin {
  InAppWebViewController? _ctrl;
  bool _canGoBack = false;

  @override
  bool get wantKeepAlive => true;

  Future<void> onBackground() async {
    await _ctrl?.evaluateJavascript(
      source: r"""
      (function() {
        const v = document.querySelector('video');
        if (v && v.paused && window.__ytUserPaused !== true) v.play().catch(()=>{});
      })();
    """,
    );
  }

  static const _js = r"""
  (function() {
    if (window.__adBlockInstalled) return;
    window.__adBlockInstalled = true;
    window.__ytUserPaused = false;

    Object.defineProperty(document, 'hidden', { get: () => false, configurable: true });
    Object.defineProperty(document, 'visibilityState', { get: () => 'visible', configurable: true });
    const stopEv = e => e.stopImmediatePropagation();
    for (const ev of ['visibilitychange','webkitvisibilitychange','blur','pagehide','freeze','mozvisibilitychange']) {
      document.addEventListener(ev, stopEv, true);
      window.addEventListener(ev, stopEv, true);
    }

    const style = document.createElement('style');
    style.id = 'yt-ab';
    style.textContent = `
      ytm-promoted-video-renderer, ytm-ad-slot, ytm-companion-slot,
      ytm-banner-promo-renderer, ytm-promoted-sparkles-web-renderer,
      .ad-container, .ytp-ad-overlay-container, .ytp-ad-text-overlay,
      .ytp-ad-player-overlay, .ytp-ad-image-overlay, .ytp-ad-module,
      [layout*="AD_"], [data-ad-slot-id] {
        display: none !important; visibility: hidden !important;
        height: 0 !important; opacity: 0 !important;
      }`;
    document.head.appendChild(style);

    document.addEventListener('click', e => {
      const b = e.target?.closest('.ytp-play-button,.ytm-play-pause-button,[aria-label*="Pause"],[aria-label*="Play"],[aria-label*="Wstrzymaj"],[aria-label*="Odtwarzaj"]');
      if (b) { const v = document.querySelector('video'); if (v) setTimeout(() => { window.__ytUserPaused = v.paused; }, 150); }
    }, true);

    setInterval(() => {
      const v = document.querySelector('video');
      const skip = document.querySelector('.ytp-ad-skip-button,.ytp-ad-skip-button-modern,.ytp-skip-ad-button,[class*="skip-button"]');
      if (skip && skip.offsetParent !== null) { skip.click(); return; }
      if (!v) return;
      const ad = !!(document.querySelector('.ad-showing,.ad-interrupting,[class*="ad-showing"]'));
      if (ad && isFinite(v.duration) && v.duration > 0) { v.currentTime = v.duration - 0.01; v.play().catch(()=>{}); return; }
      if (!ad && v.paused && !window.__ytUserPaused && v.readyState >= 3 && v.duration > 0) {
        if (!v.__bgR) { v.__bgR = true; v.play().catch(()=>{}); }
      } else if (!v.paused) { v.__bgR = false; }
    }, 100);

    new MutationObserver(() => {
      document.querySelectorAll('ytm-promoted-video-renderer,ytm-ad-slot,.ad-container,ytm-banner-promo-renderer')
        .forEach(n => n.style.setProperty('display','none','important'));
    }).observe(document.documentElement, { childList: true, subtree: true });

    const _p = history.pushState.bind(history), _r = history.replaceState.bind(history);
    function onNav() {
      if (!document.getElementById('yt-ab')) document.head.appendChild(style);
      window.__ytUserPaused = false;
      let t = 0;
      const q = setInterval(() => {
        if (t++ > 30) { clearInterval(q); return; }
        const sk = document.querySelector('.ytp-ad-skip-button,.ytp-ad-skip-button-modern,.ytp-skip-ad-button');
        if (sk && sk.offsetParent !== null) { sk.click(); clearInterval(q); return; }
        const v = document.querySelector('video');
        const ad = !!(document.querySelector('.ad-showing,.ad-interrupting'));
        if (ad && v && isFinite(v.duration) && v.duration > 0) { v.currentTime = v.duration - 0.01; v.play().catch(()=>{}); clearInterval(q); }
      }, 100);
    }
    history.pushState = function(...a) { _p(...a); setTimeout(onNav, 50); };
    history.replaceState = function(...a) { _r(...a); setTimeout(onNav, 50); };
    window.addEventListener('popstate', () => setTimeout(onNav, 50));
    document.addEventListener('yt-navigate-finish', () => { window.__ytUserPaused = false; onNav(); });
  })();
  """;

  Future<void> _inject() async => _ctrl?.evaluateJavascript(source: _js);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        title: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            const Text('YouTube'),
          ],
        ),
        actions: [
          // Przycisk wstecz
          if (_canGoBack)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: () => _ctrl?.goBack(),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => _ctrl?.reload(),
            tooltip: 'Odśwież',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri("https://m.youtube.com")),
        initialSettings: InAppWebViewSettings(
          allowsInlineMediaPlayback: true,
          mediaPlaybackRequiresUserGesture: false,
          domStorageEnabled: true,
          javaScriptEnabled: true,
          allowsPictureInPictureMediaPlayback: true,
          cacheEnabled: true,
          clearCache: false,
          userAgent:
              "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) "
              "AppleWebKit/605.1.15 (KHTML, like Gecko) "
              "Version/17.5 Mobile/15E148 Safari/604.1",
          dataDetectorTypes: [DataDetectorTypes.NONE],
        ),
        onWebViewCreated: (c) => _ctrl = c,
        onLoadStop: (c, url) async {
          await _inject();
          final canGoBack = await c.canGoBack();
          if (mounted) setState(() => _canGoBack = canGoBack);
        },
        onLoadError: (c, url, code, msg) => _inject(),
        onUpdateVisitedHistory: (c, url, isReload) async {
          final canGoBack = await c.canGoBack();
          if (mounted) setState(() => _canGoBack = canGoBack);
        },
      ),
    );
  }
}

// ── GOOGLE ────────────────────────────────────────────────────────────────────
class _GoogleScreen extends StatefulWidget {
  const _GoogleScreen();
  @override
  State<_GoogleScreen> createState() => _GoogleState();
}

class _GoogleState extends State<_GoogleScreen>
    with AutomaticKeepAliveClientMixin {
  InAppWebViewController? _ctrl;
  bool _canGoBack = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        title: const Text('Google'),
        actions: [
          if (_canGoBack)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: () => _ctrl?.goBack(),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => _ctrl?.reload(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri("https://www.google.com")),
        initialSettings: InAppWebViewSettings(
          domStorageEnabled: true,
          javaScriptEnabled: true,
          cacheEnabled: true,
        ),
        onWebViewCreated: (c) => _ctrl = c,
        onUpdateVisitedHistory: (c, url, isReload) async {
          final canGoBack = await c.canGoBack();
          if (mounted) setState(() => _canGoBack = canGoBack);
        },
      ),
    );
  }
}
