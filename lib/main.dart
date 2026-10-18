import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_v2ray_client/flutter_v2ray.dart'; 

void main() {
  runApp(const CXVpnApp());
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
        primaryColor: const Color(0xFFFF8A32),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF070B16),
        primaryColor: const Color(0xFFFF8A32),
      ),
      home: MainScreen(
        isDark: isDark,
        toggle: () => setState(() => isDark = !isDark),
      ),
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
  bool isSplash = true, isLoggedIn = false;
  int pageIndex = 0;
  List<ServerModel> servers = [];
  ServerModel? selectedServer;
  bool isLoading = true;
  String? errorMsg;

  final List<String> subUrls = [
    "https://raw.githubusercontent.com/barry-far/V2ray-config/main/Sub1.txt",
    "https://raw.githubusercontent.com/barry-far/V2ray-config/main/Sub2.txt",
    "https://raw.githubusercontent.com/barry-far/V2ray-config/main/Sub3.txt",
    "https://raw.githubusercontent.com/barry-far/V2ray-config/main/Sub4.txt",
    "https://raw.githubusercontent.com/barry-far/V2ray-config/main/Sub5.txt",
    "https://raw.githubusercontent.com/barry-far/V2ray-config/main/Sub6.txt",
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => isSplash = false);
    });
    fetchAndTest();
  }

  Future<void> fetchAndTest() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
    });

    List<String> allLinks = [];

    for (String url in subUrls) {
      try {
        final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
        if (res.statusCode == 200) {
          List<String> links = res.body
              .split('\n')
              .map((e) => e.trim())
              .where((e) => e.startsWith('vless://') || e.startsWith('vmess://') || e.startsWith('trojan://'))
              .toList();
          allLinks.addAll(links);
        }
      } catch (e) {}
    }

    if (allLinks.isEmpty) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMsg = "No valid links found from subscriptions.";
        });
      }
      return;
    }

    List<String> linksToTest = allLinks.take(15).toList();
    List<ServerModel> testedServers = [];

    V2ray v2ray = V2ray(onStatusChanged: (status) {});

    for (int i = 0; i < linksToTest.length; i++) {
      String link = linksToTest[i];
      try {
        final parser = V2ray.parseFromURL(link);
        final delay = await v2ray.getServerDelay(
          config: parser.getFullConfiguration(),
        );

        testedServers.add(ServerModel(
          id: i.toString(),
          name: "Server ${i + 1}",
          country: parser.remark.isNotEmpty ? parser.remark : "Unknown",
          flag: "🌐",
          vlessLink: link,
          ping: delay,
        ));
      } catch (e) {}
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
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMsg = "Failed to ping servers.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool d = widget.isDark;

    if (isSplash) {
      return Scaffold(
        backgroundColor: d ? const Color(0xFF050810) : const Color(0xFFE8EDF7),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('CX VPN', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: d ? Colors.white : Colors.black)),
              const SizedBox(height: 20),
              const CircularProgressIndicator(color: Color(0xFFFF8A32)),
              const SizedBox(height: 20),
              Text('POWERED BY CEREBRA X', style: TextStyle(fontSize: 10, color: d ? Colors.grey : Colors.black54)),
            ],
          ),
        ),
      );
    }

    if (isLoading) {
      return Scaffold(
        backgroundColor: d ? const Color(0xFF050810) : const Color(0xFFE8EDF7),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFFFF8A32)),
              const SizedBox(height: 20),
              Text('Testing Best Servers...', style: TextStyle(color: d ? Colors.white : Colors.black)),
            ],
          ),
        ),
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
                Icon(Icons.wifi_off, size: 56, color: d ? Colors.white54 : Colors.black45),
                const SizedBox(height: 16),
                Text(errorMsg ?? "No servers available.", textAlign: TextAlign.center, style: TextStyle(color: d ? Colors.white : Colors.black)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () { fetchAndTest(); },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8A32)),
                  child: const Text("Retry"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!isLoggedIn) {
      return LoginScreen(isDark: d, onLogin: () => setState(() => isLoggedIn = true));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(child: SkyBackground(isDark: d)),
          SafeArea(
            child: IndexedStack(
              index: pageIndex,
              children: [
                HomePage(
                  isDark: d,
                  toggle: widget.toggle,
                  selectedServer: selectedServer!,
                  onNav: () => setState(() => pageIndex = 1),
                ),
                ServersPage(
                  isDark: d,
                  servers: servers,
                  selected: selectedServer!,
                  onSelect: (s) => setState(() { selectedServer = s; pageIndex = 0; }),
                ),
                SettingsPage(isDark: d, toggle: widget.toggle),
                const PremiumPage(),
              ],
            ),
          ),
          Positioned(
            bottom: 20, left: 20, right: 20,
            child: _glass(d, const EdgeInsets.symmetric(vertical: 8, horizontal: 8), Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _nav(0, Icons.home_outlined, "Home", d),
                _nav(1, Icons.public, "Servers", d),
                _nav(2, Icons.settings, "Settings", d),
                _nav(3, Icons.workspace_premium, "Premium", d),
              ],
            )),
          ),
        ],
      ),
    );
  }

  Widget _nav(int i, IconData ic, String t, bool d) {
    return GestureDetector(
      onTap: () => setState(() => pageIndex = i),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: pageIndex == i ? const Color(0xFFFF8A32).withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ic, size: 22, color: pageIndex == i ? const Color(0xFFFFB66D) : (d ? const Color(0xFF929DB5) : const Color(0xFF65718A))),
            const SizedBox(height: 4),
            Text(t, style: TextStyle(fontSize: 10, color: pageIndex == i ? const Color(0xFFFFB66D) : (d ? const Color(0xFF929DB5) : const Color(0xFF65718A)))),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final bool isDark;
  final VoidCallback toggle;
  final ServerModel selectedServer;
  final VoidCallback onNav;

  const HomePage({super.key, required this.isDark, required this.toggle, required this.selectedServer, required this.onNav});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  bool isConnected = false;
  bool isConnecting = false;
  late AnimationController _spin;
  late AnimationController _glitch;
  
  late final V2ray v2ray;
  
  int downloadSpeed = 0;
  int uploadSpeed = 0;
  int totalDownload = 0;
  int totalUpload = 0;
  int ping = 0;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _glitch = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    v2ray = V2ray(
      onStatusChanged: (status) {
        if (!mounted) return;
        setState(() {
          isConnected = status.state == 'CONNECTED';
          isConnecting = false;
          downloadSpeed = status.downloadSpeed ?? 0;
          uploadSpeed = status.uploadSpeed ?? 0;
          totalDownload = status.download ?? 0;
          totalUpload = status.upload ?? 0;
        });
        if (isConnected) {
          if (!_glitch.isAnimating) _glitch.repeat(reverse: true);
          _fetchPing();
        } else {
          _glitch.stop();
        }
      },
    );
  }

  Future<void> _fetchPing() async {
    try {
      final delay = await v2ray.getConnectedServerDelay();
      if (mounted) setState(() => ping = delay);
    } catch (_) {}
  }

  @override
  void dispose() {
    _spin.dispose();
    _glitch.dispose();
    super.dispose();
  }

  Future<void> connect() async {
    if (isConnecting) return;

    if (isConnected) {
      await v2ray.stopV2Ray();
      return;
    }

    setState(() => isConnecting = true);

    try {
      await v2ray.initialize(
        notificationIconResourceType: "mipmap",
        notificationIconResourceName: "ic_launcher",
      );

      if (!await v2ray.requestPermission()) {
        if (mounted) {
          setState(() => isConnecting = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('VPN permission denied.')));
        }
        return;
      }

      final link = widget.selectedServer.vlessLink.trim();
      final parser = V2ray.parseFromURL(link);

      await v2ray.startV2Ray(
        remark: parser.remark.isNotEmpty ? parser.remark : "CX VPN",
        config: parser.getFullConfiguration(),
        proxyOnly: false,
      );
    } catch (e) {
      if (mounted) {
        setState(() { isConnecting = false; isConnected = false; });
        _glitch.stop();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Connection failed: $e')));
      }
    }
  }

  String _formatSpeed(int bytes) {
    if (bytes <= 0) return "0 B/s";
    if (bytes < 1024) return "$bytes B/s";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB/s";
    return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB/s";
  }

  String _formatTotal(int bytes) {
    if (bytes <= 0) return "0 B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(0)} KB";
    return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
  }

  @override
  Widget build(BuildContext context) {
    bool d = widget.isDark;
    Color txt = d ? const Color(0xFFF4F7FF) : const Color(0xFF182239);
    Color mut = d ? const Color(0xFF929DB5) : const Color(0xFF65718A);
    Color con = d ? const Color(0xFF5DE2A0) : const Color(0xFF16A34A);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  text: 'CX ',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: txt, letterSpacing: -1.2),
                  children: const [TextSpan(text: 'VPN', style: TextStyle(color: Color(0xFFFF8A32)))],
                ),
              ),
              Row(
                children: [
                  GestureDetector(onTap: widget.toggle, child: _icon(d ? Icons.wb_sunny_outlined : Icons.nightlight_round, d)),
                  const SizedBox(width: 8),
                  _icon(Icons.settings, d),
                ],
              ),
            ],
          ),
          const SizedBox(height: 34),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("WELCOME BACK", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, color: mut)),
                  const SizedBox(height: 9),
                  RichText(
                    text: TextSpan(
                      text: 'Your digital\nworld, ',
                      style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold, height: 1.2, color: txt),
                      children: const [TextSpan(text: 'protected.', style: TextStyle(color: Color(0xFFFFB66D)))],
                    ),
                  ),
                ],
              ),
              Container(
                width: 58, height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8A32).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFF8A32).withOpacity(0.3)),
                ),
                child: Center(child: RotationTransition(turns: _spin, child: const Icon(Icons.settings_input_component, color: Color(0xFFFFB66D), size: 30))),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  RepaintBoundary(
                    child: GestureDetector(
                      onTap: connect,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (isConnected) ...[
                            AnimatedBuilder(
                              animation: _glitch,
                              builder: (c, w) => Transform.translate(
                                offset: Offset(math.sin(_glitch.value * math.pi * 4) * 8, 0),
                                child: Container(width: 150, height: 150, decoration: BoxDecoration(borderRadius: BorderRadius.circular(36), border: Border.all(color: Colors.cyanAccent.withOpacity(0.8), width: 3))),
                              ),
                            ),
                            AnimatedBuilder(
                              animation: _glitch,
                              builder: (c, w) => Transform.translate(
                                offset: Offset(math.cos(_glitch.value * math.pi * 4) * -8, 0),
                                child: Container(width: 150, height: 150, decoration: BoxDecoration(borderRadius: BorderRadius.circular(36), border: Border.all(color: Colors.pinkAccent.withOpacity(0.8), width: 3))),
                              ),
                            ),
                          ],
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 150, height: 150,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(36),
                              color: isConnected ? con.withOpacity(0.15) : (d ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.7)),
                              border: Border.all(color: isConnected ? con : (d ? Colors.white.withOpacity(0.3) : Colors.white), width: 1.5),
                              boxShadow: [BoxShadow(color: isConnected ? con.withOpacity(0.4) : (d ? const Color(0xFFFF8A32).withOpacity(0.15) : Colors.black.withOpacity(0.05)), blurRadius: 45, spreadRadius: 5)],
                            ),
                            child: Center(
                              child: isConnecting
                                  ? const CircularProgressIndicator(color: Color(0xFFFF8A32))
                                  : Icon(Icons.power_settings_new, size: 42, color: isConnected ? con : txt),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(isConnecting ? "CONNECTING..." : (isConnected ? "CONNECTED" : "NOT CONNECTED"), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 2, color: isConnected ? con : txt)),
                  const SizedBox(height: 7),
                  Text(isConnected ? "Your connection is secured" : "Tap to connect securely", style: TextStyle(fontSize: 12, color: mut)),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                    decoration: BoxDecoration(
                      color: d ? Colors.white.withOpacity(0.065) : Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: d ? Colors.white.withOpacity(0.14) : Colors.black12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: isConnected ? con : const Color(0xFF9099AC), boxShadow: isConnected ? [BoxShadow(color: con.withOpacity(0.8), blurRadius: 12)] : [])),
                        const SizedBox(width: 8),
                        Text(isConnected ? "Protected" : "Ready to connect", style: TextStyle(fontSize: 11, color: isConnected ? con : mut)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: widget.onNav,
            child: _glass(d, const EdgeInsets.all(16), Row(
              children: [
                Container(
                  width: 45, height: 45,
                  decoration: BoxDecoration(color: d ? Colors.white.withOpacity(0.1) : Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: d ? Colors.white.withOpacity(0.1) : Colors.black12)),
                  child: Center(child: Text(widget.selectedServer.flag, style: const TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("YOUR LOCATION", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: mut)),
                      const SizedBox(height: 5),
                      Text(widget.selectedServer.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: txt)),
                      const SizedBox(height: 3),
                      Text(widget.selectedServer.country, style: TextStyle(fontSize: 11, color: mut)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: mut),
              ],
            )),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              _stat(_formatSpeed(downloadSpeed), "Download", Icons.arrow_downward, d, txt, mut, isConnected),
              const SizedBox(width: 10),
              _stat(_formatSpeed(uploadSpeed), "Upload", Icons.arrow_upward, d, txt, mut, isConnected),
              const SizedBox(width: 10),
              _stat(isConnected ? (ping > 0 ? "$ping ms" : "...") : "--", "Ping", Icons.access_time, d, txt, mut, isConnected),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Total: ${_formatTotal(totalDownload)} ↓ / ${_formatTotal(totalUpload)} ↑", style: TextStyle(fontSize: 10, color: mut)),
            ],
          ),
          const SizedBox(height: 15),
          _glass(d, const EdgeInsets.all(16), Row(
            children: [
              Container(width: 45, height: 45, decoration: BoxDecoration(color: const Color(0xFFFF8A32).withOpacity(0.15), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.workspace_premium, color: Color(0xFFFFB66D))),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("CX Premium", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: txt)),
                    const SizedBox(height: 5),
                    Text("Unlock your full potential", style: TextStyle(fontSize: 11, color: mut)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: mut),
            ],
          )),
        ],
      ),
    );
  }

  Widget _icon(IconData ic, bool d) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: d ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: d ? Colors.white.withOpacity(0.1) : Colors.white),
      ),
      child: Icon(ic, size: 22, color: d ? Colors.white : const Color(0xFF182239)),
    );
  }

  Widget _stat(String v, String l, IconData ic, bool d, Color t, Color m, bool isActive) {
    return Expanded(
      child: _glass(
        d,
        const EdgeInsets.all(12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(ic, color: isActive ? const Color(0xFFFFB66D) : m, size: 19),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(v, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isActive ? t : m)),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(l, style: TextStyle(fontSize: 10, color: m)),
            ),
          ],
        ),
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
    bool d = isDark;
    Color txt = d ? const Color(0xFFF4F7FF) : const Color(0xFF182239);
    Color mut = d ? const Color(0xFF929DB5) : const Color(0xFF65718A);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Choose Server", style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold, color: txt)),
          const SizedBox(height: 5),
          Text("Auto-selected best servers based on Ping.", style: TextStyle(fontSize: 12, color: mut)),
          const SizedBox(height: 25),
          ...servers.map((s) {
            bool isSel = s.id == selected.id;
            Color pingColor = s.ping < 100 ? Colors.green : (s.ping < 300 ? Colors.orange : Colors.red);
            
            return GestureDetector(
              onTap: () => onSelect(s),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSel ? const Color(0xFFFF8A32).withOpacity(0.15) : (d ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSel ? const Color(0xFFFF8A32) : (d ? Colors.white.withOpacity(0.1) : Colors.black12), width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 45, height: 45,
                      decoration: BoxDecoration(color: d ? Colors.white.withOpacity(0.1) : Colors.white, borderRadius: BorderRadius.circular(15)),
                      child: Center(child: Text(s.flag, style: const TextStyle(fontSize: 22))),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.country, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: txt)),
                          const SizedBox(height: 4),
                          Text(s.name, style: TextStyle(fontSize: 11, color: mut)),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.network_ping, size: 14, color: pingColor),
                        const SizedBox(width: 4),
                        Text("${s.ping} ms", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: pingColor)),
                        const SizedBox(width: 12),
                      ],
                    ),
                    if (isSel)
                      const Icon(Icons.check_circle, color: Color(0xFFFF8A32), size: 24)
                    else
                      Icon(Icons.radio_button_unchecked, color: mut, size: 24),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  final bool isDark;
  final VoidCallback toggle;

  const SettingsPage({super.key, required this.isDark, required this.toggle});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool hideAds = false;
  String routingMode = "Smart Routing";

  @override
  Widget build(BuildContext context) {
    bool d = widget.isDark;
    Color txt = d ? const Color(0xFFF4F7FF) : const Color(0xFF182239);
    Color mut = d ? const Color(0xFF929DB5) : const Color(0xFF65718A);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Settings", style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold, color: txt)),
          const SizedBox(height: 25),
          _glass(d, const EdgeInsets.all(16), Row(
            children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFFF8A32).withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: const Center(child: Text("⌁", style: TextStyle(fontSize: 20, color: Color(0xFFFFB66D))))),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Routing Mode", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: txt)),
                    const SizedBox(height: 3),
                    Text(routingMode, style: TextStyle(fontSize: 11, color: mut)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: mut),
            ],
          )),
          const SizedBox(height: 12),
          _glass(d, const EdgeInsets.all(16), Row(
            children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFFF8A32).withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: const Center(child: Text("◐", style: TextStyle(fontSize: 20, color: Color(0xFFFFB66D))))),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Dark Appearance", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: txt)),
                    const SizedBox(height: 3),
                    Text("Liquid Glass theme", style: TextStyle(fontSize: 11, color: mut)),
                  ],
                ),
              ),
              Switch(value: d, onChanged: (val) => widget.toggle(), activeColor: const Color(0xFFFF8A32)),
            ],
          )),
          const SizedBox(height: 12),
          _glass(d, const EdgeInsets.all(16), Row(
            children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFFF8A32).withOpacity(0.15), borderRadius: BorderRadius.circular(12)), child: const Center(child: Text("◈", style: TextStyle(fontSize: 20, color: Color(0xFFFFB66D))))),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Hide Home Screen Ads", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: txt)),
                    const SizedBox(height: 3),
                    Text("Visual preference", style: TextStyle(fontSize: 11, color: mut)),
                  ],
                ),
              ),
              Switch(value: hideAds, onChanged: (val) => setState(() => hideAds = val), activeColor: const Color(0xFFFF8A32)),
            ],
          )),
          const SizedBox(height: 12),
          _glass(d, const EdgeInsets.all(24), Column(
            children: [
              RichText(
                text: TextSpan(
                  text: 'CX ',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: txt, letterSpacing: -1),
                  children: const [TextSpan(text: 'VPN', style: TextStyle(color: Color(0xFFFF8A32)))],
                ),
              ),
              const SizedBox(height: 8),
              Text("Version 1.0.0", style: TextStyle(fontSize: 12, color: mut)),
              const SizedBox(height: 5),
              Text("Powered by Cerebra X", style: TextStyle(fontSize: 10, color: mut)),
            ],
          )),
        ],
      ),
    );
  }
}

class PremiumPage extends StatelessWidget {
  const PremiumPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Premium Features (Coming Soon)", style: TextStyle(color: Colors.white)));
  }
}

class LoginScreen extends StatelessWidget {
  final bool isDark;
  final VoidCallback onLogin;

  const LoginScreen({super.key, required this.isDark, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    bool d = isDark;
    Color txt = d ? const Color(0xFFF4F7FF) : const Color(0xFF182239);
    Color mut = d ? const Color(0xFF929DB5) : const Color(0xFF65718A);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: SkyBackground(isDark: d)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          text: 'CX ',
                          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: txt),
                          children: const [TextSpan(text: 'VPN', style: TextStyle(color: Color(0xFFFF8A32)))],
                        ),
                      ),
                      _glass(d, const EdgeInsets.symmetric(horizontal: 12, vertical: 6), Text("EN", style: TextStyle(fontSize: 12, color: txt))),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: 76, height: 76,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), gradient: const LinearGradient(colors: [Color(0xFFFFBD76), Color(0xFFFF7929)])),
                    child: const Center(child: Text("ϟ", style: TextStyle(fontSize: 43, color: Colors.white))),
                  ),
                  const SizedBox(height: 25),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: 'Your internet.\n',
                      style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, height: 1.15, color: txt),
                      children: const [TextSpan(text: 'Your freedom.', style: TextStyle(color: Color(0xFFFFB66D)))],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text("Secure, private and connected.", style: TextStyle(color: mut)),
                  const Spacer(),
                  _glass(d, const EdgeInsets.all(21), Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("GET STARTED", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, color: mut)),
                      const SizedBox(height: 15),
                      _btn("Continue as Guest", Icons.person_outline, d, txt, onLogin),
                      const SizedBox(height: 12),
                      _btn("Continue with Google", Icons.g_mobiledata, d, txt, () {}),
                      const SizedBox(height: 12),
                      _btn("Continue with Reddit", Icons.forum, d, txt, () {}),
                    ],
                  )),
                  const Spacer(),
                  Text("POWERED BY CEREBRA X", style: TextStyle(fontSize: 10, letterSpacing: 2, color: mut)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _btn(String t, IconData ic, bool d, Color tc, VoidCallback tap) {
    return GestureDetector(
      onTap: tap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: d ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6),
          border: Border.all(color: d ? Colors.white.withOpacity(0.14) : Colors.white),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: d ? Colors.white.withOpacity(0.1) : Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Icon(ic, size: 20, color: tc),
            ),
            const SizedBox(width: 13),
            Text(t, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: tc)),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: tc.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}

class SkyBackground extends StatefulWidget {
  final bool isDark;
  const SkyBackground({super.key, required this.isDark});

  @override
  State<SkyBackground> createState() => _SkyBackgroundState();
}

class _SkyBackgroundState extends State<SkyBackground> with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool d = widget.isDark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: d ? [const Color(0xFF020513), const Color(0xFF0A1128), const Color(0xFF192542)] : [const Color(0xFF4FACFE), const Color(0xFF00F2FE), const Color(0xFFE0F6FF)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: MediaQuery.of(context).size.height * 0.08,
            right: MediaQuery.of(context).size.width * 0.12,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: d ? Colors.white : const Color(0xFFFFDB58),
                boxShadow: [BoxShadow(color: d ? Colors.white.withOpacity(0.3) : const Color(0xFFFFDB58).withOpacity(0.6), blurRadius: 40, spreadRadius: 10)],
              ),
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _c,
              builder: (c, w) => CustomPaint(painter: LeafP(progress: _c.value, isDark: d)),
            ),
          ),
          Positioned(
            bottom: -10, left: 0, right: 0,
            child: CustomPaint(size: Size(MediaQuery.of(context).size.width, 300), painter: TreeP(isDark: d)),
          ),
        ],
      ),
    );
  }
}

class LeafP extends CustomPainter {
  final double progress;
  final bool isDark;

  LeafP({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = isDark ? const Color(0xFFFF8A32) : const Color(0xFF16A34A)
      ..style = PaintingStyle.fill;

    final r = math.Random(123);

    for (int i = 0; i < 20; i++) {
      double sx = r.nextDouble() * size.width;
      double dl = r.nextDouble();
      double sp = 0.5 + r.nextDouble();
      double cp = (progress * sp + dl) % 1.0;
      double y = size.height * cp;
      double x = sx + (math.sin(cp * math.pi * 4) * 40);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(cp * math.pi * 2);

      Path pth = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(7, -7, 14, 0)
        ..quadraticBezierTo(7, 7, 0, 0);

      canvas.drawPath(pth, p);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant LeafP old) => old.progress != progress;
}

class TreeP extends CustomPainter {
  final bool isDark;

  TreeP({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = isDark ? Colors.black.withOpacity(0.85) : const Color(0xFF0F172A).withOpacity(0.6)
      ..style = PaintingStyle.fill;

    double w = size.width;
    double h = size.height;

    final pth = Path()
      ..moveTo(w * 0.35, h)
      ..cubicTo(w * 0.37, h * 0.8, w * 0.4, h * 0.63, w * 0.25, h * 0.46)
      ..cubicTo(w * 0.2, h * 0.4, w * 0.1, h * 0.33, w * 0.05, h * 0.26)
      ..cubicTo(w * 0.15, h * 0.3, w * 0.25, h * 0.36, w * 0.35, h * 0.43)
      ..cubicTo(w * 0.37, h * 0.33, w * 0.32, h * 0.2, w * 0.4, h * 0.06)
      ..cubicTo(w * 0.42, h * 0.2, w * 0.45, h * 0.33, w * 0.47, h * 0.46)
      ..cubicTo(w * 0.57, h * 0.33, w * 0.7, h * 0.23, w * 0.85, h * 0.16)
      ..cubicTo(w * 0.72, h * 0.26, w * 0.62, h * 0.4, w * 0.57, h * 0.53)
      ..cubicTo(w * 0.65, h * 0.6, w * 0.75, h * 0.66, w * 0.9, h * 0.73)
      ..cubicTo(w * 0.7, h * 0.7, w * 0.6, h * 0.63, w * 0.52, h * 0.56)
      ..cubicTo(w * 0.5, h * 0.66, w * 0.52, h * 0.8, w * 0.55, h)
      ..close();

    canvas.drawPath(pth, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

Widget _glass(bool d, EdgeInsets p, Widget c) {
  return Container(
    padding: p,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: d ? Colors.white.withOpacity(0.15) : Colors.white, width: 1.5),
      color: d ? const Color(0xFF1E293B).withOpacity(0.6) : Colors.white.withOpacity(0.7),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 1)],
    ),
    child: c,
  );
}
