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

// ── AUDIO SESSION — musi być skonfigurowany PRZED WebView ────────────────────
// Na iPhone przełącznik boczny (Ring/Silent) blokuje audio z WebView
// jeśli kategoria to .ambient lub .soloAmbient.
// Kategoria .playback ignoruje przełącznik — to samo co Spotify/YouTube.
Future<void> _setupAudio() async {
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration(
    // .playback = gra nawet gdy telefon wyciszony (jak Spotify)
    avAudioSessionCategory: AVAudioSessionCategory.playback,
    // Bez mixWithOthers — wyłącza inne audio gdy gramy (jak YouTube)
    avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.none,
    avAudioSessionMode: AVAudioSessionMode.defaultMode,
    // longFormAudio = przeznaczony dla muzyki/wideo — priorytet w centrum sterowania
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
  // setActive(true) — mówi iOS że teraz MY gramy audio
  await session.setActive(true);
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

  // Audio PRZED runApp — WebView dziedziczy ustawienia sesji
  try {
    await _setupAudio();
  } catch (_) {}

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
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: _textPri,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
          iconTheme: IconThemeData(color: _textPri),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: _bg,
          selectedItemColor: _accent,
          unselectedItemColor: _textSec,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle:
              TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          unselectedLabelStyle: TextStyle(fontSize: 11),
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
      // Reaktywuj sesję audio gdy app wraca z tła
      try {
        await _setupAudio();
      } catch (_) {}
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
          _YouTube(key: _ytKey),
          const _GoogleScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: _divider, width: 0.5)),
        ),
        child: SafeArea(
          top: false,
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
        title: Row(children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
                color: _accent, borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          const Text('YT Lite'),
        ]),
      ),
      body: ListView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        children: [
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Aktywny',
                      style: TextStyle(
                          color: _accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 16),
                const Text('Muzyka w tle',
                    style: TextStyle(
                        color: _textPri,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text(
                  'YouTube gra nawet gdy zamkniesz aplikację lub zgasisz ekran.',
                  style: TextStyle(color: _textSec, fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            _Tile(
                icon: Icons.block,
                color: const Color(0xFF4CAF50),
                label: 'Bez reklam',
                sub: 'Auto-skip'),
            const SizedBox(width: 12),
            _Tile(
                icon: Icons.music_note,
                color: const Color(0xFF2196F3),
                label: 'Tło',
                sub: 'Audio działa'),
            const SizedBox(width: 12),
            _Tile(
                icon: Icons.speed,
                color: const Color(0xFFFF9800),
                label: 'Szybki',
                sub: 'Auto-skip'),
          ]),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () =>
                context.findAncestorStateOfType<_ShellState>()?._onTap(1),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: _accent, borderRadius: BorderRadius.circular(14)),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow, color: Colors.white, size: 22),
                  SizedBox(width: 8),
                  Text('Otwórz YouTube',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, sub;
  const _Tile(
      {required this.icon,
      required this.color,
      required this.label,
      required this.sub});
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
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: const TextStyle(
                    color: _textPri,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
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
    try {
      await _ctrl?.evaluateJavascript(source: '''
        (function() {
          var v = document.querySelector('video');
          if (v && v.paused && !window.__userPaused) {
            v.play().catch(function(){});
          }
        })();
      ''');
    } catch (_) {}
  }

  // ── JS: visibility hack ───────────────────────────────────────────────────
  static const _jsVisibility = r"""
    (function() {
      if (window.__visHack) return;
      window.__visHack = true;
      try {
        Object.defineProperty(document, 'hidden',
          { get: function(){ return false; }, configurable: true });
        Object.defineProperty(document, 'visibilityState',
          { get: function(){ return 'visible'; }, configurable: true });
      } catch(e) {}
      var fn = function(e){ e.stopImmediatePropagation(); };
      ['visibilitychange','webkitvisibilitychange','blur',
       'pagehide','freeze'].forEach(function(ev) {
        document.addEventListener(ev, fn, true);
        window.addEventListener(ev, fn, true);
      });
    })();
  """;

  // ── JS: ad block CSS ──────────────────────────────────────────────────────
  static const _jsCss = r"""
    (function() {
      if (document.getElementById('__ytab')) return;
      var s = document.createElement('style');
      s.id = '__ytab';
      s.textContent =
        'ytm-promoted-video-renderer,ytm-ad-slot,ytm-companion-slot,' +
        'ytm-banner-promo-renderer,ytm-promoted-sparkles-web-renderer,' +
        '.ad-container,.ytp-ad-overlay-container,.ytp-ad-text-overlay,' +
        '.ytp-ad-player-overlay,.ytp-ad-image-overlay,.ytp-ad-module,' +
        '[data-ad-slot-id],[layout*="AD_"]' +
        '{display:none!important;height:0!important;opacity:0!important;}';
      document.head.appendChild(s);
    })();
  """;

  // ── JS: główna logika — pauza + skip reklam + background ─────────────────
  // Przepisane od zera z prostszą logiką:
  // - __userPaused = true  gdy user kliknie pauzę
  // - __userPaused = false gdy user kliknie play LUB wejdzie w nowy film
  // - skip reklam działa niezależnie od __userPaused
  // - background fix tylko sprawdza __userPaused raz na 2s
  static const _jsLogic = r"""
    (function() {
      if (window.__ytLogic) return;
      window.__ytLogic = true;
      window.__userPaused = false;

      // Podepnij zdarzenia na element video
      function attach(v) {
        if (!v || v.__att) return;
        v.__att = true;
        v.addEventListener('pause', function() {
          var isAd = document.querySelector('.ad-showing,.ad-interrupting');
          if (!isAd) window.__userPaused = true;
        });
        v.addEventListener('play', function() {
          window.__userPaused = false;
        });
        v.addEventListener('ended', function() {
          window.__userPaused = false;
        });
        v.addEventListener('loadstart', function() {
          // Nowy film — zresetuj
          window.__userPaused = false;
          v.__att = false;
        });
      }

      function getVideo() { return document.querySelector('video'); }
      function isAdPlaying() {
        return !!(document.querySelector('.ad-showing') ||
                  document.querySelector('.ad-interrupting'));
      }

      // ── SKIP REKLAM: co 150ms ───────────────────────────────────────────
      // Agresywny skip — nie czeka, nie patrzy na __userPaused
      setInterval(function() {
        try {
          var v = getVideo();
          if (v) attach(v);

          // 1. Kliknij przycisk "Pomiń"
          var btn = document.querySelector(
            '.ytp-ad-skip-button,.ytp-ad-skip-button-modern,.ytp-skip-ad-button,.ytp-ad-skip-button-slot'
          );
          if (btn && btn.offsetParent !== null) {
            btn.click();
            return;
          }

          // 2. Przewiń reklamę do końca
          if (!v) return;
          if (isAdPlaying() && isFinite(v.duration) && v.duration > 0) {
            v.currentTime = v.duration - 0.05;
            return;
          }
        } catch(e) {}
      }, 150);

      // ── BACKGROUND FIX: co 2s ───────────────────────────────────────────
      // Wznów audio w tle TYLKO gdy user nie spauzował
      setInterval(function() {
        try {
          var v = getVideo();
          if (!v) return;
          if (v.paused && !window.__userPaused && !isAdPlaying() &&
              v.readyState >= 3 && v.duration > 0) {
            v.play().catch(function(){});
          }
        } catch(e) {}
      }, 2000);

      // ── MUTATION OBSERVER: blokuj reklamy w DOM ─────────────────────────
      try {
        new MutationObserver(function() {
          try {
            document.querySelectorAll(
              'ytm-promoted-video-renderer,ytm-ad-slot,' +
              '.ad-container,ytm-banner-promo-renderer'
            ).forEach(function(n) {
              n.style.display = 'none';
            });
            var v = getVideo();
            if (v) attach(v);
          } catch(e) {}
        }).observe(document.documentElement, {childList:true, subtree:true});
      } catch(e) {}

      // ── SPA NAVIGATION ──────────────────────────────────────────────────
      function onNav() {
        window.__userPaused = false;
        // Re-dodaj CSS jeśli zniknął
        if (!document.getElementById('__ytab')) {
          var s = document.createElement('style');
          s.id = '__ytab';
          s.textContent =
            'ytm-promoted-video-renderer,ytm-ad-slot,[data-ad-slot-id]' +
            '{display:none!important;}';
          if (document.head) document.head.appendChild(s);
        }
      }

      try {
        var _pp = history.pushState.bind(history);
        var _rr = history.replaceState.bind(history);
        history.pushState = function() {
          _pp.apply(history, arguments);
          setTimeout(onNav, 80);
        };
        history.replaceState = function() {
          _rr.apply(history, arguments);
          setTimeout(onNav, 80);
        };
        window.addEventListener('popstate', function() { setTimeout(onNav, 80); });
        document.addEventListener('yt-navigate-finish', function() {
          window.__userPaused = false;
        });
      } catch(e) {}

    })();
  """;

  Future<void> _inject() async {
    try {
      await _ctrl?.evaluateJavascript(source: _jsVisibility);
      await _ctrl?.evaluateJavascript(source: _jsCss);
      await _ctrl?.evaluateJavascript(source: _jsLogic);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        title: Row(children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
                color: _accent, borderRadius: BorderRadius.circular(6)),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          const Text('YouTube'),
        ]),
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
        initialUrlRequest: URLRequest(url: WebUri('https://m.youtube.com')),
        initialSettings: InAppWebViewSettings(
          // ── iOS audio — te 3 ustawienia są OBOWIĄZKOWE ──────────────────
          // allowsInlineMediaPlayback: pozwala grać audio bez fullscreen
          allowsInlineMediaPlayback: true,
          // mediaPlaybackRequiresUserGesture: false = gra automatycznie
          mediaPlaybackRequiresUserGesture: false,
          // allowsPictureInPictureMediaPlayback: audio gdy ekran zgaszony
          allowsPictureInPictureMediaPlayback: true,
          // ────────────────────────────────────────────────────────────────
          domStorageEnabled: true,
          javaScriptEnabled: true,
          cacheEnabled: true,
          clearCache: false,
          disallowOverScroll: true,
          transparentBackground: false,
          isFraudulentWebsiteWarningEnabled: false,
          userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) '
              'AppleWebKit/605.1.15 (KHTML, like Gecko) '
              'Version/17.5 Mobile/15E148 Safari/604.1',
          dataDetectorTypes: [DataDetectorTypes.NONE],
        ),
        onWebViewCreated: (c) => _ctrl = c,
        onLoadStop: (c, url) async {
          await _inject();
          try {
            final can = await c.canGoBack();
            if (mounted) setState(() => _canGoBack = can);
          } catch (_) {}
        },
        onReceivedError: (c, req, err) async {
          if (err.type == WebResourceErrorType.CANCELLED) return;
          await _inject();
        },
        onUpdateVisitedHistory: (c, url, isReload) async {
          try {
            final can = await c.canGoBack();
            if (mounted) setState(() => _canGoBack = can);
          } catch (_) {}
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
        initialUrlRequest: URLRequest(url: WebUri('https://www.google.com')),
        initialSettings: InAppWebViewSettings(
          domStorageEnabled: true,
          javaScriptEnabled: true,
          cacheEnabled: true,
          disallowOverScroll: true,
          transparentBackground: false,
        ),
        onWebViewCreated: (c) => _ctrl = c,
        onUpdateVisitedHistory: (c, url, isReload) async {
          try {
            final can = await c.canGoBack();
            if (mounted) setState(() => _canGoBack = can);
          } catch (_) {}
        },
      ),
    );
  }
}
