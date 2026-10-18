import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_v2ray/flutter_v2ray.dart';

void main() {
  runApp(const CXVpnApp());
}

// ==========================================
// SERVER MODEL
// ==========================================
class ServerModel {
  final String id;
  final String name;
  final String country;
  final String flag;
  final String vlessLink;

  ServerModel({
    required this.id,
    required this.name,
    required this.country,
    required this.flag,
    required this.vlessLink,
  });

  factory ServerModel.fromJson(Map<String, dynamic> json) {
    return ServerModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      country: json['country'] ?? '',
      flag: json['flag'] ?? '🌐',
      vlessLink: json['vlessLink'] ?? '',
    );
  }
}

// ==========================================
// MAIN APP
// ==========================================
class CXVpnApp extends StatefulWidget {
  const CXVpnApp({super.key});

  @override
  State<CXVpnApp> createState() => _CXVpnAppState();
}

class _CXVpnAppState extends State<CXVpnApp> {
  bool isDarkMode = true;

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CX VPN',
      debugShowCheckedModeBanner: false,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFE8EDF7),
        primaryColor: const Color(0xFFFF8A32),
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF070B16),
        primaryColor: const Color(0xFFFF8A32),
        fontFamily: 'Roboto',
      ),
      home: MainScreen(isDarkMode: isDarkMode, toggleTheme: toggleTheme),
    );
  }
}

// ==========================================
// MAIN SCREEN
// ==========================================
class MainScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback toggleTheme;

  const MainScreen({super.key, required this.isDarkMode, required this.toggleTheme});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool isSplash = true;
  bool isLoggedIn = false;
  int currentPageIndex = 0; 

  List<ServerModel> servers = [];
  ServerModel? selectedServer;
  bool isLoadingServers = true;

  final String serverListUrl = "https://raw.githubusercontent.com/aungmyingyi/cx-vpn-backend/refs/heads/main/servers.json";

  @override
  void initState() {
    super.initState();
    fetchServers();
  }

  Future<void> fetchServers() async {
    try {
      final response = await http.get(Uri.parse(serverListUrl));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          servers = data.map((json) => ServerModel.fromJson(json)).toList();
          if (servers.isNotEmpty) selectedServer = servers[0];
          isLoadingServers = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingServers = false;
      });
    }

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => isSplash = false);
    });
  }

  void selectServer(ServerModel server) {
    setState(() {
      selectedServer = server;
      currentPageIndex = 0; 
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = widget.isDarkMode;
    
    if (isSplash || isLoadingServers) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF050810) : const Color(0xFFE8EDF7),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('CX VPN', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: isDark ? Colors.white : Colors.black)),
              const SizedBox(height: 20),
              const CircularProgressIndicator(color: Color(0xFFFF8A32)),
              const SizedBox(height: 20),
              Text(isLoadingServers ? 'Syncing Servers...' : 'POWERED BY CEREBRA X', style: TextStyle(fontSize: 10, letterSpacing: 2, color: isDark ? Colors.grey : Colors.black54)),
            ],
          ),
        ),
      );
    }

    if (selectedServer == null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF050810) : const Color(0xFFE8EDF7),
        body: Center(
          child: Text("No servers available.\nCheck your internet.", textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        ),
      );
    }

    if (!isLoggedIn) {
      return LoginScreen(
        isDark: isDark,
        onLogin: () => setState(() => isLoggedIn = true),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(child: SkyBackground(isDark: isDark)),
          
          SafeArea(
            child: IndexedStack(
              index: currentPageIndex,
              children: [
                HomePage(
                  isDark: isDark, 
                  toggleTheme: widget.toggleTheme,
                  selectedServer: selectedServer!,
                  onNavigateToServers: () => setState(() => currentPageIndex = 1),
                ),
                ServersPage(
                  isDark: isDark,
                  servers: servers,
                  selectedServer: selectedServer!,
                  onSelectServer: selectServer,
                ),
                const Center(child: Text("Settings Page (Coming Soon)")),
                const Center(child: Text("Premium Page (Coming Soon)")),
              ],
            ),
          ),

          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: GlassContainer(
              isDark: isDark,
              borderRadius: 24,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home_outlined, "Home", isDark),
                  _buildNavItem(1, Icons.public, "Servers", isDark),
                  _buildNavItem(2, Icons.settings, "Settings", isDark),
                  _buildNavItem(3, Icons.workspace_premium, "Premium", isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isDark) {
    bool isActive = currentPageIndex == index;
    return GestureDetector(
      onTap: () => setState(() => currentPageIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFF8A32).withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: isActive ? const Color(0xFFFFB66D) : (isDark ? const Color(0xFF929DB5) : const Color(0xFF65718A))),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, color: isActive ? const Color(0xFFFFB66D) : (isDark ? const Color(0xFF929DB5) : const Color(0xFF65718A)))),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// HOME PAGE
// ==========================================
class HomePage extends StatefulWidget {
  final bool isDark;
  final VoidCallback toggleTheme;
  final ServerModel selectedServer;
  final VoidCallback onNavigateToServers;

  const HomePage({
    super.key, 
    required this.isDark, 
    required this.toggleTheme,
    required this.selectedServer,
    required this.onNavigateToServers,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  bool isConnected = false;
  bool isConnecting = false;
  late AnimationController _spinController;
  late AnimationController _glitchController;
  FlutterV2ray? flutterV2ray;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _glitchController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _spinController.dispose();
    _glitchController.dispose();
    super.dispose();
  }

  Future<void> toggleVPN() async {
    if (isConnecting) return;

    if (!isConnected) {
      setState(() => isConnecting = true);
      
      final permission = await FlutterV2ray.requestPermission();
      if (!permission) {
        setState(() => isConnecting = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("VPN Permission Denied!")));
        return;
      }

      flutterV2ray = FlutterV2ray(
        onStatusChanged: (status) {
          if (mounted) {
            // String Comparison ကို အသုံးပြုပြီး Error မတက်အောင် ကာကွယ်ထားပါတယ်
            if (status.state == 'CONNECTED') {
              setState(() { isConnected = true; isConnecting = false; });
            } else if (status.state == 'DISCONNECTED') {
              setState(() { isConnected = false; isConnecting = false; });
            }
          }
        },
      );

      await flutterV2ray!.initializeV2Ray();
      
      // Error မတက်စေရန် V2RayURL မှ V2rayURL သို့ ပြောင်းထားပါတယ်
      V2rayURL parser = V2rayURL(link: widget.selectedServer.vlessLink);
      await flutterV2ray!.startV2Ray(
        remark: "CX VPN",
        config: parser.getFullConfiguration(),
        proxyOnly: false,
        bypassLAN: true,
      );

    } else {
      await flutterV2ray?.stopV2Ray();
      setState(() { isConnected = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    Color textColor = widget.isDark ? const Color(0xFFF4F7FF) : const Color(0xFF182239);
    Color mutedColor = widget.isDark ? const Color(0xFF929DB5) : const Color(0xFF65718A);
    Color connectedColor = widget.isDark ? const Color(0xFF5DE2A0) : const Color(0xFF16A34A);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  text: 'CX ',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -1.2),
                  children: const [TextSpan(text: 'VPN', style: TextStyle(color: Color(0xFFFF8A32)))],
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: widget.toggleTheme,
                    child: GlassIcon(icon: widget.isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round, isDark: widget.isDark),
                  ),
                  const SizedBox(width: 8),
                  GlassIcon(icon: Icons.settings, isDark: widget.isDark),
                ],
              )
            ],
          ),
          const SizedBox(height: 34),

          // Welcome Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("WELCOME BACK", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, color: mutedColor)),
                  const SizedBox(height: 9),
                  RichText(
                    text: TextSpan(
                      text: 'Your digital\nworld, ',
                      style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold, height: 1.2, color: textColor),
                      children: const [TextSpan(text: 'protected.', style: TextStyle(color: Color(0xFFFFB66D)))],
                    ),
                  ),
                ],
              ),
              Container(
                width: 58, height: 58,
                decoration: BoxDecoration(
                  color: widget.isDark ? const Color(0xFFFF8A32).withOpacity(0.15) : Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFF8A32).withOpacity(0.3)),
                ),
                child: Center(
                  child: RotationTransition(
                    turns: _spinController,
                    child: const Icon(Icons.settings_input_component, color: Color(0xFFFFB66D), size: 30),
                  ),
                ),
              )
            ],
          ),
          
          // Connection Area
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  RepaintBoundary(
                    child: GestureDetector(
                      onTap: toggleVPN,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (isConnected) ...[
                            AnimatedBuilder(
                              animation: _glitchController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(math.sin(_glitchController.value * math.pi * 4) * 8, 0),
                                  child: Container(
                                    width: 150, height: 150,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(36),
                                      border: Border.all(color: Colors.cyanAccent.withOpacity(0.8), width: 3),
                                    ),
                                  ),
                                );
                              },
                            ),
                            AnimatedBuilder(
                              animation: _glitchController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(math.cos(_glitchController.value * math.pi * 4) * -8, 0),
                                  child: Container(
                                    width: 150, height: 150,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(36),
                                      border: Border.all(color: Colors.pinkAccent.withOpacity(0.8), width: 3),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                          
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 150, height: 150,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(36),
                              color: isConnected 
                                  ? connectedColor.withOpacity(0.15) 
                                  : (widget.isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.7)),
                              border: Border.all(
                                color: isConnected 
                                    ? connectedColor 
                                    : (widget.isDark ? Colors.white.withOpacity(0.3) : Colors.white),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isConnected 
                                      ? connectedColor.withOpacity(0.4) 
                                      : (widget.isDark ? const Color(0xFFFF8A32).withOpacity(0.15) : Colors.black.withOpacity(0.05)),
                                  blurRadius: 45, spreadRadius: 5,
                                )
                              ]
                            ),
                            child: Center(
                              child: isConnecting 
                                ? const CircularProgressIndicator(color: Color(0xFFFF8A32))
                                : Icon(Icons.power_settings_new, size: 42, color: isConnected ? connectedColor : textColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    isConnecting ? "CONNECTING..." : (isConnected ? "CONNECTED" : "NOT CONNECTED"),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 2, color: isConnected ? connectedColor : textColor),
                  ),
                  const SizedBox(height: 7),
                  Text(isConnected ? "Your connection is secured" : "Tap to connect securely", style: TextStyle(fontSize: 12, color: mutedColor)),
                  
                  const SizedBox(height: 15),
                  RepaintBoundary(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                      decoration: BoxDecoration(
                        color: widget.isDark ? Colors.white.withOpacity(0.065) : Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: widget.isDark ? Colors.white.withOpacity(0.14) : Colors.black12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7, height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isConnected ? connectedColor : const Color(0xFF9099AC),
                              boxShadow: isConnected ? [BoxShadow(color: connectedColor.withOpacity(0.8), blurRadius: 12)] : [],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(isConnected ? "Protected" : "Ready to connect", style: TextStyle(fontSize: 11, color: isConnected ? connectedColor : mutedColor)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Server Card
          GestureDetector(
            onTap: widget.onNavigateToServers,
            child: RepaintBoundary(
              child: GlassContainer(
                isDark: widget.isDark,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 45, height: 45,
                      decoration: BoxDecoration(
                        color: widget.isDark ? Colors.white.withOpacity(0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: widget.isDark ? Colors.white.withOpacity(0.1) : Colors.black12),
                      ),
                      child: Center(child: Text(widget.selectedServer.flag, style: const TextStyle(fontSize: 22))),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("YOUR LOCATION", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: mutedColor)),
                          const SizedBox(height: 5),
                          Text(widget.selectedServer.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                          const SizedBox(height: 3),
                          Text(widget.selectedServer.country, style: TextStyle(fontSize: 11, color: mutedColor)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: mutedColor),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 13),

          Row(
            children: [
              _buildStatCard("0 B", "Downloaded", Icons.arrow_downward, widget.isDark, textColor, mutedColor),
              const SizedBox(width: 10),
              _buildStatCard("0 B", "Uploaded", Icons.arrow_upward, widget.isDark, textColor, mutedColor),
              const SizedBox(width: 10),
              _buildStatCard("--", "Ping", Icons.access_time, widget.isDark, textColor, mutedColor),
            ],
          ),

          const SizedBox(height: 15),

          RepaintBoundary(
            child: GlassContainer(
              isDark: widget.isDark,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 45, height: 45,
                    decoration: BoxDecoration(color: const Color(0xFFFF8A32).withOpacity(0.15), borderRadius: BorderRadius.circular(15)),
                    child: const Icon(Icons.workspace_premium, color: Color(0xFFFFB66D)),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("CX Premium", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                        const SizedBox(height: 5),
                        Text("Unlock your full potential", style: TextStyle(fontSize: 11, color: mutedColor)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16, color: mutedColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, bool isDark, Color text, Color muted) {
    return Expanded(
      child: RepaintBoundary(
        child: GlassContainer(
          isDark: isDark,
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: const Color(0xFFFFB66D), size: 19),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: text)),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 10, color: muted)),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// SERVERS PAGE
// ==========================================
class ServersPage extends StatelessWidget {
  final bool isDark;
  final List<ServerModel> servers;
  final ServerModel selectedServer;
  final Function(ServerModel) onSelectServer;

  const ServersPage({
    super.key, 
    required this.isDark, 
    required this.servers, 
    required this.selectedServer,
    required this.onSelectServer,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor = isDark ? const Color(0xFFF4F7FF) : const Color(0xFF182239);
    Color mutedColor = isDark ? const Color(0xFF929DB5) : const Color(0xFF65718A);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("Choose Server", style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold, color: textColor)),
            ],
          ),
          const SizedBox(height: 5),
          Text("Select a location for your connection.", style: TextStyle(fontSize: 12, color: mutedColor)),
          const SizedBox(height: 25),

          ...servers.map((server) {
            bool isSelected = server.id == selectedServer.id;
            return GestureDetector(
              onTap: () => onSelectServer(server),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? const Color(0xFFFF8A32).withOpacity(0.15)
                      : (isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected 
                        ? const Color(0xFFFF8A32) 
                        : (isDark ? Colors.white.withOpacity(0.1) : Colors.black12),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 45, height: 45,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(child: Text(server.flag, style: const TextStyle(fontSize: 22))),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(server.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
                          const SizedBox(height: 4),
                          Text(server.country, style: TextStyle(fontSize: 11, color: mutedColor)),
                        ],
                      ),
                    ),
                    if (isSelected) 
                      const Icon(Icons.check_circle, color: Color(0xFFFF8A32), size: 24)
                    else
                      Icon(Icons.radio_button_unchecked, color: mutedColor, size: 24),
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

// ==========================================
// LOGIN SCREEN
// ==========================================
class LoginScreen extends StatelessWidget {
  final bool isDark;
  final VoidCallback onLogin;
  const LoginScreen({super.key, required this.isDark, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    Color textColor = isDark ? const Color(0xFFF4F7FF) : const Color(0xFF182239);
    Color mutedColor = isDark ? const Color(0xFF929DB5) : const Color(0xFF65718A);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: SkyBackground(isDark: isDark)),
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
                          style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: textColor),
                          children: const [TextSpan(text: 'VPN', style: TextStyle(color: Color(0xFFFF8A32)))],
                        ),
                      ),
                      GlassContainer(
                        isDark: isDark,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Text("EN", style: TextStyle(fontSize: 12, color: textColor)),
                      )
                    ],
                  ),
                  const Spacer(),
                  
                  Container(
                    width: 76, height: 76,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: const LinearGradient(colors: [Color(0xFFFFBD76), Color(0xFFFF7929)]),
                    ),
                    child: const Center(child: Text("ϟ", style: TextStyle(fontSize: 43, color: Colors.white))),
                  ),
                  const SizedBox(height: 25),
                  
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: 'Your internet.\n',
                      style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, height: 1.15, color: textColor),
                      children: const [TextSpan(text: 'Your freedom.', style: TextStyle(color: Color(0xFFFFB66D)))],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text("Secure, private and connected.", style: TextStyle(color: mutedColor)),
                  const Spacer(),

                  GlassContainer(
                    isDark: isDark,
                    padding: const EdgeInsets.all(21),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("GET STARTED", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, color: mutedColor)),
                        const SizedBox(height: 15),
                        _buildLoginBtn("Continue as Guest", Icons.person_outline, isDark, textColor, onLogin),
                        const SizedBox(height: 12),
                        _buildLoginBtn("Continue with Google", Icons.g_mobiledata, isDark, textColor, () {}),
                        const SizedBox(height: 12),
                        _buildLoginBtn("Continue with Reddit", Icons.forum, isDark, textColor, () {}),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text("POWERED BY CEREBRA X", style: TextStyle(fontSize: 10, letterSpacing: 2, color: mutedColor)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLoginBtn(String text, IconData icon, bool isDark, Color textColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.14) : Colors.white),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.1) : Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 20, color: textColor),
            ),
            const SizedBox(width: 13),
            Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: textColor.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// SKY BACKGROUND & REUSABLE COMPONENTS
// ==========================================
class SkyBackground extends StatefulWidget {
  final bool isDark;
  const SkyBackground({super.key, required this.isDark});

  @override
  State<SkyBackground> createState() => _SkyBackgroundState();
}

class _SkyBackgroundState extends State<SkyBackground> with SingleTickerProviderStateMixin {
  late AnimationController _leafController;

  @override
  void initState() {
    super.initState();
    _leafController = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat();
  }

  @override
  void dispose() {
    _leafController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: widget.isDark 
            ? [const Color(0xFF020513), const Color(0xFF0A1128), const Color(0xFF192542)]
            : [const Color(0xFF4FACFE), const Color(0xFF00F2FE), const Color(0xFFE0F6FF)],
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
                color: widget.isDark ? Colors.white : const Color(0xFFFFDB58),
                boxShadow: [
                  BoxShadow(
                    color: widget.isDark ? Colors.white.withOpacity(0.3) : const Color(0xFFFFDB58).withOpacity(0.6),
                    blurRadius: 40, spreadRadius: 10,
                  )
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _leafController,
              builder: (context, child) {
                return CustomPaint(
                  painter: LeafPainter(progress: _leafController.value, isDark: widget.isDark),
                );
              },
            ),
          ),
          Positioned(
            bottom: -10, left: 0, right: 0,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 300),
              painter: TreePainter(isDark: widget.isDark),
            ),
          ),
        ],
      ),
    );
  }
}

class LeafPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  LeafPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? const Color(0xFFFF8A32) : const Color(0xFF16A34A)
      ..style = PaintingStyle.fill;

    final random = math.Random(123); 

    for (int i = 0; i < 20; i++) {
      double startX = random.nextDouble() * size.width;
      double delay = random.nextDouble();
      double speed = 0.5 + random.nextDouble();
      
      double currentProgress = (progress * speed + delay) % 1.0;
      double y = size.height * currentProgress;
      double x = startX + (math.sin(currentProgress * math.pi * 4) * 40);
      
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(currentProgress * math.pi * 2);
      
      Path path = Path();
      path.moveTo(0, 0);
      path.quadraticBezierTo(7, -7, 14, 0);
      path.quadraticBezierTo(7, 7, 0, 0);
      canvas.drawPath(path, paint);
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant LeafPainter oldDelegate) => oldDelegate.progress != progress;
}

class TreePainter extends CustomPainter {
  final bool isDark;
  TreePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.black.withOpacity(0.85) : const Color(0xFF0F172A).withOpacity(0.6)
      ..style = PaintingStyle.fill;

    double w = size.width;
    double h = size.height;

    final path = Path();
    path.moveTo(w * 0.35, h);
    path.cubicTo(w * 0.37, h * 0.8, w * 0.4, h * 0.63, w * 0.25, h * 0.46);
    path.cubicTo(w * 0.2, h * 0.4, w * 0.1, h * 0.33, w * 0.05, h * 0.26);
    path.cubicTo(w * 0.15, h * 0.3, w * 0.25, h * 0.36, w * 0.35, h * 0.43);
    path.cubicTo(w * 0.37, h * 0.33, w * 0.32, h * 0.2, w * 0.4, h * 0.06);
    path.cubicTo(w * 0.42, h * 0.2, w * 0.45, h * 0.33, w * 0.47, h * 0.46);
    path.cubicTo(w * 0.57, h * 0.33, w * 0.7, h * 0.23, w * 0.85, h * 0.16);
    path.cubicTo(w * 0.72, h * 0.26, w * 0.62, h * 0.4, w * 0.57, h * 0.53);
    path.cubicTo(w * 0.65, h * 0.6, w * 0.75, h * 0.66, w * 0.9, h * 0.73);
    path.cubicTo(w * 0.7, h * 0.7, w * 0.6, h * 0.63, w * 0.52, h * 0.56);
    path.cubicTo(w * 0.5, h * 0.66, w * 0.52, h * 0.8, w * 0.55, h);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const GlassContainer({
    super.key,
    required this.child,
    required this.isDark,
    this.padding = EdgeInsets.zero,
    this.borderRadius = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.15) : Colors.white,
          width: 1.5,
        ),
        color: isDark ? const Color(0xFF1E293B).withOpacity(0.6) : Colors.white.withOpacity(0.7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          )
        ]
      ),
      child: child,
    );
  }
}

class GlassIcon extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  const GlassIcon({super.key, required this.icon, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      isDark: isDark,
      borderRadius: 15,
      padding: const EdgeInsets.all(10),
      child: Icon(icon, size: 22, color: isDark ? Colors.white : const Color(0xFF182239)),
    );
  }
}
