import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_v2ray_client/flutter_v2ray.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      debugPrint("VPN Initialization Error: $e"); 
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
  int pageIndex = 0;
  
  // စမ်းသပ်ရန် နမူနာ ဆာဗာများ (သင့်ကိုယ်ပိုင် Link တွေ ဒီမှာ ထည့်နိုင်ပါတယ်)
  List<ServerModel> servers = [
    ServerModel(
        id: "1",
        name: "Singapore Server",
        country: "Singapore",
        flag: "🇸🇬",
        vlessLink: "vless://YOUR_VLESS_LINK_HERE", // သင့် Link ကို အစားထိုးပါ
        ping: 50),
    ServerModel(
        id: "2",
        name: "US Server",
        country: "United States",
        flag: "🇺🇸",
        vlessLink: "vless://YOUR_VLESS_LINK_HERE", // သင့် Link ကို အစားထိုးပါ
        ping: 120),
  ];
  
  ServerModel? selectedServer;

  @override
  void initState() {
    super.initState();
    if (servers.isNotEmpty) {
      selectedServer = servers.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool d = widget.isDark;
    
    if (selectedServer == null) {
      return Scaffold(
        backgroundColor: d ? const Color(0xFF050810) : const Color(0xFFE8EDF7),
        body: const Center(child: Text("No servers available.")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(children: [
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
          const PremiumPage(isDark: true), 
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
  late AnimationController _spin, _glitch;
  final V2rayManager _mgr = V2rayManager();
  int downloadSpeed = 0, uploadSpeed = 0, totalDownload = 0, totalUpload = 0, ping = 0;

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
        _fetchPing();
      } else {
        _glitch.stop();
      }
    } catch (e) {
      debugPrint("Status Error: $e");
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
      
      // Link မရှိရင် Error ပြမယ်
      if (link.contains("YOUR_VLESS_LINK_HERE") || link.isEmpty) {
         if (mounted) {
          setState(() => isConnecting = false);
          _showSnack('Please add a valid VLESS link in main.dart');
        }
        return;
      }

      final parser = V2ray.parseFromURL(link);
      
      _mgr.v2ray.startV2Ray(
          remark: parser.remark.isNotEmpty ? parser.remark : "CX VPN",
          config: parser.getFullConfiguration(),
      );

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          isConnecting = false;
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

  void _showSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool d = widget.isDark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // လက်ရှိ ရွေးချယ်ထားသော ဆာဗာ
          Text(
            '${widget.selectedServer.flag} ${widget.selectedServer.name}',
            style: TextStyle(fontSize: 18, color: d ? Colors.grey : Colors.black54),
          ),
          const SizedBox(height: 30),
          Text(
            isConnected ? 'Connected' : (isConnecting ? 'Connecting...' : 'Disconnected'),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isConnected ? Colors.green : (d ? Colors.white : Colors.black),
            ),
          ),
          const SizedBox(height: 10),
          if (isConnected) Text('Ping: $ping ms', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 40),
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
              backgroundColor: isConnected ? Colors.redAccent : const Color(0xFFFF8A32),
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
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
