import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_v2ray_client/flutter_v2ray.dart';
import 'package:startapp_sdk/startapp.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final startAppSdk = StartAppSdk();
    if (kDebugMode) startAppSdk.setTestAdsEnabled(true);
  } catch (e) {
    debugPrint("Ad Error: $e");
  }
  runApp(const CXVpnApp());
}

class V2rayManager {
  V2rayManager._();
  static final V2rayManager _instance = V2rayManager._();
  factory V2rayManager() => _instance;
  
  late final V2ray v2ray;
  bool _initialized = false;
  bool _isV2rayCreated = false;

  void initialize({required Function(dynamic) onStatusChanged}) {
    if (_isV2rayCreated) return;
    v2ray = V2ray(onStatusChanged: onStatusChanged);
    _isV2rayCreated = true;
  }

  Future<bool> ensureInitialized() async {
    if (_initialized) return true;
    if (!_isV2rayCreated) return false;
    try {
      await v2ray.initialize(
          notificationIconResourceType: "mipmap",
          notificationIconResourceName: "ic_launcher");
      _initialized = true;
      return true;
    } catch (e) {
      return false;
    }
  }
}

class ServerModel {
  final String id, name, country, flag, vlessLink;
  int ping;
  ServerModel({
    required this.id,
    required this.name,
    required this.country,
    required this.flag,
    required this.vlessLink,
    this.ping = 9999,
  });
}

class FlagHelper {
  static final RegExp _emojiRegex =
      RegExp(r'[\u{1F1E6}-\u{1F1FF}]{2}', unicode: true);
  static String extractFlag(String remark) =>
      _emojiRegex.firstMatch(remark)?.group(0) ?? "🌐";
  static String cleanName(String remark) => remark
      .replaceAll(_emojiRegex, '')
      .replaceAll(RegExp(r'[|\-_]+'), ' ')
      .trim();
}

class CXVpnApp extends StatefulWidget {
  const CXVpnApp({super.key});
  @override
  State<CXVpnApp> createState() => _CXVpnAppState();
}

class _CXVpnAppState extends State<CXVpnApp> {
  bool isDark = true;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFE8EDF7),
          primaryColor: const Color(0xFFFF8A32)),
      darkTheme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF070B16),
          primaryColor: const Color(0xFFFF8A32)),
      home: MainScreen(
          isDark: isDark, toggle: () => setState(() => isDark = !isDark)),
    );
  }
}

class MainScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback toggle;
  const MainScreen({super.key, required this.isDark, required this.toggle});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool isSplash = true;
  int pageIndex = 0;
  List<ServerModel> servers = [];
  ServerModel? selectedServer;
  bool isLoading = true;
  String? errorMsg;

  final List<String> subUrls = [
    "https://raw.githubusercontent.com/barry-far/V2ray-config/main/Sub1.txt",
    "https://raw.githubusercontent.com/barry-far/V2ray-config/main/Sub2.txt",
    "https://raw.githubusercontent.com/barry-far/V2ray-config/main/Sub3.txt",
  ];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final minSplash = Future.delayed(const Duration(milliseconds: 1500));
    await Future.wait([minSplash, fetchAndTest()]);
    if (mounted) setState(() => isSplash = false);
  }

  Future<void> fetchAndTest() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMsg = null;
      });
    }
    List<String> allLinks = [];

    for (String url in subUrls) {
      try {
        final res =
            await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
        if (res.statusCode == 200) {
          List<String> links = res.body
              .split('\n')
              .map((e) => e.trim())
              .where((e) =>
                  e.startsWith('vless://') ||
                  e.startsWith('vmess://') ||
                  e.startsWith('trojan://'))
              .toList();
          allLinks.addAll(links);
        }
      } catch (e) {
        debugPrint("Fetch err: $e");
      }
    }

    if (allLinks.isEmpty) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMsg = "No valid links found. Check internet.";
        });
      }
      return;
    }

    allLinks.shuffle();
    List<String> linksToTest = allLinks.take(3).toList();

    final mgr = V2rayManager();
    final ready = await mgr.ensureInitialized();

    if (!ready) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMsg = "VPN engine failed.";
        });
      }
      return;
    }

    List<ServerModel> testedServers = [];

    for (int i = 0; i < linksToTest.length; i++) {
      try {
        final parser = V2ray.parseFromURL(linksToTest[i]);
        final delay = await mgr.v2ray
            .getServerDelay(config: parser.getFullConfiguration())
            .timeout(const Duration(seconds: 3));
        final remark = parser.remark.isNotEmpty ? parser.remark : "Unknown";
        testedServers.add(ServerModel(
            id: i.toString(),
            name: FlagHelper.cleanName(remark),
            country: remark,
            flag: FlagHelper.extractFlag(remark),
            vlessLink: linksToTest[i],
            ping: delay));
      } catch (e) {
        debugPrint("Ping err: $e");
      }
    }

    if (testedServers.isNotEmpty) {
      testedServers.sort((a, b) => a.ping.compareTo(b.ping));
      if (mounted) {
        setState(() {
          servers = testedServers;
          selectedServer = testedServers.first;
          isLoading = false;
        });
      }
    } else {
      try {
        final parser = V2ray.parseFromURL(linksToTest[0]);
        final remark =
            parser.remark.isNotEmpty ? parser.remark : "Default Server";
        if (mounted) {
          setState(() {
            servers = [
              ServerModel(
                  id: "0",
                  name: FlagHelper.cleanName(remark),
                  country: remark,
                  flag: FlagHelper.extractFlag(remark),
                  vlessLink: linksToTest[0],
                  ping: 999)
            ];
            selectedServer = servers.first;
            isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            isLoading = false;
            errorMsg = "Failed to load servers.";
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool d = widget.isDark;
    if (isSplash || isLoading) {
      return Scaffold(
        backgroundColor: d ? const Color(0xFF050810) : const Color(0xFFE8EDF7),
        body: Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('CX VPN',
              style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: d ? Colors.white : Colors.black)),
          const SizedBox(height: 20),
          const CircularProgressIndicator(color: Color(0xFFFF8A32)),
          const SizedBox(height: 20),
          Text(
              isLoading && !isSplash
                  ? 'Finding Best Server...'
                  : 'POWERED BY CEREBRA X',
              style: TextStyle(
                  fontSize: 10, color: d ? Colors.grey : Colors.black54)),
        ])),
      );
    }

    if (selectedServer == null) {
      return Scaffold(
        backgroundColor: d ? const Color(0xFF050810) : const Color(0xFFE8EDF7),
        body: Center(
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off,
                          size: 56,
                          color: d ? Colors.white54 : Colors.black45),
                      const SizedBox(height: 16),
                      Text(errorMsg ?? "No servers available.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: d ? Colors.white : Colors.black)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                          onPressed: () {
                            setState(() => isSplash = true);
                            _bootstrap();
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF8A32)),
                          child: const Text("Retry")),
                    ]))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(children: [
        // SkyBackground ကို ဒီနေရာမှာ ခေါ်ထားပါတယ် (သင့်မှာ ဒီ class မရှိရင် ဖျက်ပါ သို့မဟုတ် ဖန်တီးပါ)
        Positioned.fill(child: Container(color: d ? const Color(0xFF070B16) : const Color(0xFFE8EDF7))), 
        SafeArea(
            child: IndexedStack(index: pageIndex, children: [
          HomePage(
              isDark: d,
              toggle: widget.toggle,
              selectedServer: selectedServer!,
              onNav: () => setState(() => pageIndex = 1)),
          ServersPage(
              isDark: d,
              servers: servers,
              selected: selectedServer!,
              onSelect: (s) => setState(() {
                    selectedServer = s;
                    pageIndex = 0;
                  })),
          SettingsPage(isDark: d, toggle: widget.toggle),
          PremiumPage(isDark: d), 
        ])),
        Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: _glass(
                d,
                const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _nav(0, Icons.home_outlined, "Home", d),
                    _nav(1, Icons.public, "Servers", d),
                    _nav(2, Icons.settings, "Settings", d),
                    _nav(3, Icons.workspace_premium, "Premium", d),
                  ],
                ))),
      ]),
    );
  }

  Widget _glass(bool d, EdgeInsets padding, Widget child) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: d ? const Color(0xFF131A2B).withOpacity(0.8) : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: d ? Colors.white12 : Colors.black12),
      ),
      child: child,
    );
  }

  Widget _nav(int i, IconData ic, String t, bool d) {
    return GestureDetector(
      onTap: () => setState(() => pageIndex = i),
      child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          decoration: BoxDecoration(
              color: pageIndex == i
                  ? const Color(0xFFFF8A32).withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(ic,
                size: 22,
                color: pageIndex == i
                    ? const Color(0xFFFFB66D)
                    : (d ? const Color(0xFF929DB5) : const Color(0xFF65718A))),
            const SizedBox(height: 4),
            Text(t,
                style: TextStyle(
                    fontSize: 10,
                    color: pageIndex == i
                        ? const Color(0xFFFFB66D)
                        : (d
                            ? const Color(0xFF929DB5)
                            : const Color(0xFF65718A)))),
          ])),
    );
  }
}

class HomePage extends StatefulWidget {
  final bool isDark;
  final VoidCallback toggle;
  final ServerModel selectedServer;
  final VoidCallback onNav;
  const HomePage(
      {super.key,
      required this.isDark,
      required this.toggle,
      required this.selectedServer,
      required this.onNav});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  bool isConnected = false, isConnecting = false;
  bool _wasConnected = false; 
  late AnimationController _spin, _glitch;
  final V2rayManager _mgr = V2rayManager();
  int downloadSpeed = 0, uploadSpeed = 0, totalDownload = 0, totalUpload = 0, ping = 0;

  final StartAppSdk startAppSdk = StartAppSdk();
  int adsWatched = 0;
  int freeTimeRemaining = 3600;

  Timer? _timer;
  bool _timeExpiredDialogShown = false;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
        vsync: this, duration: const Duration(seconds: 6))
      ..repeat();
    _glitch = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _mgr.initialize(onStatusChanged: _onVpnStatus);
  }

  void _onVpnStatus(dynamic status) {
    if (!mounted) return;
    try {
      final connected =
          status.state.toString().toUpperCase().contains('CONNECTED');
      setState(() {
        isConnected = connected;
        isConnecting = false;
        downloadSpeed = status.downloadSpeed ?? 0;
        uploadSpeed = status.uploadSpeed ?? 0;
        totalDownload = status.download ?? 0;
        totalUpload = status.upload ?? 0;
      });

      if (connected) {
        if (!_glitch.isAnimating) _glitch.repeat(reverse: true);
        if (!_wasConnected) {
          _fetchPing();
          _startTimer();
        }
      } else {
        _glitch.stop();
        if (_wasConnected) _stopTimer();
      }
      _wasConnected = connected;
    } catch (e) {
      debugPrint("Status Error: $e");
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timeExpiredDialogShown = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (freeTimeRemaining > 0) {
        setState(() => freeTimeRemaining--);
      } else {
        timer.cancel();
        _handleTimeExpired();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _handleTimeExpired() async {
    if (_timeExpiredDialogShown) return;
    _timeExpiredDialogShown = true;
    try {
      await _mgr.v2ray.stopV2Ray();
    } catch (e) {
      debugPrint("Stop err: $e");
    }
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showWatchAdDialog();
    });
  }

  String _formatTime(int seconds) {
    int h = seconds ~/ 3600, m = (seconds % 3600) ~/ 60, s = seconds % 60;
    if (h > 0) {
      return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
    }
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  void _showWatchAdDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          bool d = widget.isDark;
          Color txt = d ? const Color(0xFFF4F7FF) : const Color(0xFF182239);
          Color mut = d ? const Color(0xFF929DB5) : const Color(0xFF65718A);
          return AlertDialog(
            backgroundColor: d ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Column(children: [
              const Icon(Icons.play_circle_fill,
                  color: Color(0xFFFF8A32), size: 50),
              const SizedBox(height: 10),
              Text("Get Free Time",
                  style: TextStyle(
                      color: txt, fontWeight: FontWeight.bold))
            ]),
            content: Text(
                "Watch 2 short videos to unlock 1 Hour of free VPN time.\n\n⚠️ If you exit the video early, you won't get the time.",
                textAlign: TextAlign.center,
                style: TextStyle(color: mut, fontSize: 13)),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _startWatchingAds();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8A32)),
                  child: const Text("Watch Videos",
                      style: TextStyle(color: Colors.white)))
            ],
          );
        });
  }

  Future<bool> _showRewardedAd() async {
    final completer = Completer<bool>();
    try {
      await startAppSdk
          .loadRewardedVideoAd(
        onAdNotDisplayed: () {
          if (!completer.isCompleted) completer.complete(false);
        },
        onAdHidden: () {
          if (!completer.isCompleted) completer.complete(false);
        },
        onVideoCompleted: () {
          if (!completer.isCompleted) completer.complete(true);
        },
      )
          .then((ad) {
        if (ad != null) {
          ad.show().catchError((e) {
            if (!completer.isCompleted) completer.complete(false);
          });
        } else {
          if (!completer.isCompleted) completer.complete(false);
        }
      }).onError((error, stackTrace) {
        if (!completer.isCompleted) completer.complete(false);
      });
    } catch (e) {
      if (!completer.isCompleted) completer.complete(false);
    }
    return completer.future.timeout(const Duration(minutes: 2), onTimeout: () => false);
  }

  Future<void> _startWatchingAds() async {
    setState(() => isConnecting = true);
    adsWatched = 0;
    final firstOk = await _showRewardedAd();
    if (firstOk && mounted) setState(() => adsWatched = 1);
    if (adsWatched >= 1) {
      final secondOk = await _showRewardedAd();
      if (secondOk && mounted) setState(() => adsWatched = 2);
    }
    if (adsWatched >= 2) {
      if (mounted) {
        setState(() {
          isConnecting = false;
          freeTimeRemaining = 3600;
          adsWatched = 0;
        });
        _connectVpn();
        _showSnack('Success! You got 1 hour of free time.');
      }
    } else {
      if (mounted) {
        setState(() {
          isConnecting = false;
          isConnected = false;
        });
        _glitch.stop();
        _showSnack('You need to watch both videos completely.');
      }
    }
  }

  void _showSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _fetchPing() async {
    try {
      final delay = await _mgr.v2ray.getConnectedServerDelay();
      if (mounted) setState(() => ping = delay);
    } catch (_) {}
  }

  @override
  void dispose() {
    _spin.dispose();
    _glitch.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _connectVpn() async {
    if (isConnecting) return;
    setState(() => isConnecting = true);
    try {
      final ready = await _mgr.ensureInitialized();
      if (!ready) {
        if (mounted) {
          setState(() => isConnecting = false);
          _showSnack('VPN engine init failed.');
        }
        return;
      }
      bool? permissionGranted = await _mgr.v2ray.requestPermission();
      if (permissionGranted != true) {
        if (mounted) {
          setState(() => isConnecting = false);
          _showSnack('VPN permission denied.');
        }
        return;
      }
      final link = widget.selectedServer.vlessLink.trim();
      final parser = V2ray.parseFromURL(link);
      
      // ဒီနေရာမှာ ကုဒ်ဖြတ်နေတာကို ပြန်ပြီး အပြည့်အစုံရေးပေးထားပါတယ်
      await _mgr.v2ray.startV2Ray(
          remark: parser.remark.isNotEmpty ? parser.remark : "CX VPN",
          config: parser.getFullConfiguration(),
      );

      if (mounted) {
        setState(() {
          isConnecting = false;
          isConnected = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isConnecting = false;
          isConnected = false;
        });
        _showSnack('Connection failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool d = widget.isDark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isConnected ? 'Connected' : (isConnecting ? 'Connecting...' : 'Disconnected'),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: d ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (isConnected) {
                _mgr.v2ray.stopV2Ray();
                setState(() {
                  isConnected = false;
                  isConnecting = false;
                });
              } else {
                _connectVpn();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8A32),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            child: Text(
              isConnected ? 'Disconnect' : 'Connect',
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// --- ဒီအောက်က Class တွေက သင့် UI အတွက် လိုအပ်တဲ့ နေရာမှာ ထည့်သွင်းရပါမယ် ---
// သင့်မှာ ServersPage, SettingsPage, PremiumPage တို့ရဲ့ ကုဒ်တွေ မပါလာလို့ ရိုးရိုးလေး ဖန်တီးပေးထားပါတယ်။

class ServersPage extends StatelessWidget {
  final bool isDark;
  final List<ServerModel> servers;
  final ServerModel selected;
  final Function(ServerModel) onSelect;
  const ServersPage({super.key, required this.isDark, required this.servers, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: servers.length,
      itemBuilder: (context, index) {
        final s = servers[index];
        return ListTile(
          leading: Text(s.flag, style: const TextStyle(fontSize: 24)),
          title: Text(s.name, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          subtitle: Text('Ping: ${s.ping} ms', style: TextStyle(color: isDark ? Colors.grey : Colors.black54)),
          trailing: selected.id == s.id ? const Icon(Icons.check_circle, color: Color(0xFFFF8A32)) : null,
          onTap: () => onSelect(s),
        );
      },
    );
  }
}

class SettingsPage extends StatelessWidget {
  final bool isDark;
  final VoidCallback toggle;
  const SettingsPage({super.key, required this.isDark, required this.toggle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Settings', style: TextStyle(fontSize: 24, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 20),
          SwitchListTile(
            title: Text('Dark Mode', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
            value: isDark,
            onChanged: (val) => toggle(),
          ),
        ],
      ),
    );
  }
}

class PremiumPage extends StatelessWidget {
  final bool isDark;
  const PremiumPage({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Premium Page', style: TextStyle(fontSize: 24, color: isDark ? Colors.white : Colors.black)),
    );
  }
}
