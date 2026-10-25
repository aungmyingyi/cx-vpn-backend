import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_v2ray_client/flutter_v2ray.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CXVpnApp());
}

// ==========================================
// 1. Data Models & Helpers
// ==========================================

class ServerModel {
  final String id, name, country, flag, vlessLink;
  ServerModel({
    required this.id,
    required this.name,
    required this.country,
    required this.flag,
    required this.vlessLink,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'country': country, 'flag': flag, 'vlessLink': vlessLink,
  };

  factory ServerModel.fromJson(Map<String, dynamic> json) => ServerModel(
    id: json['id'], name: json['name'], country: json['country'], flag: json['flag'], vlessLink: json['vlessLink'],
  );
}

class FlagHelper {
  static final RegExp _emojiRegex = RegExp(r'[\u{1F1E6}-\u{1F1FF}]{2}', unicode: true);
  static String extractFlag(String remark) => _emojiRegex.firstMatch(remark)?.group(0) ?? "🌐";
  static String cleanName(String remark) => remark.replaceAll(_emojiRegex, '').replaceAll(RegExp(r'[|\-_]+'), ' ').trim();
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
      await v2ray.initialize(notificationIconResourceType: "mipmap", notificationIconResourceName: "ic_launcher");
      _initialized = true;
      return true;
    } catch (e) {
      debugPrint("VPN Initialization Error: $e"); 
      return false;
    }
  }
}

class UserManager {
  static const String _keyIsPremium = 'is_premium';
  static const String _keyServers = 'custom_servers';

  static Future<bool> getIsPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsPremium) ?? false;
  }

  static Future<void> setPremium(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsPremium, value);
  }

  static Future<List<ServerModel>> getServers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString(_keyServers);
    if (jsonStr == null) {
      // ပထမဆုံးအကြိမ် ဖွင့်ရင် Default Server ထည့်ပေးမယ်
      return [
        ServerModel(id: "1", name: "Singapore", country: "SG", flag: "🇸🇬", vlessLink: "vless://YOUR_LINK_HERE"),
      ];
    }
    final List<dynamic> decoded = jsonDecode(jsonStr);
    return decoded.map((e) => ServerModel.fromJson(e)).toList();
  }

  static Future<void> saveServers(List<ServerModel> servers) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonStr = jsonEncode(servers.map((e) => e.toJson()).toList());
    await prefs.setString(_keyServers, jsonStr);
  }
}

// ==========================================
// 2. Main App Setup
// ==========================================

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
      theme: ThemeData(brightness: Brightness.light, primaryColor: const Color(0xFFFF8A32)),
      darkTheme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: const Color(0xFF070B16), primaryColor: const Color(0xFFFF8A32)),
      home: MainScreen(isDark: isDark, toggle: () => setState(() => isDark = !isDark)),
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
  List<ServerModel> servers = [];
  ServerModel? selectedServer;
  bool isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final loadedServers = await UserManager.getServers();
    final prem = await UserManager.getIsPremium();
    setState(() {
      servers = loadedServers;
      isPremium = prem;
      if (servers.isNotEmpty) selectedServer = servers.first;
    });
  }

  Future<void> _addServer(ServerModel newServer) async {
    setState(() => servers.add(newServer));
    await UserManager.saveServers(servers);
  }

  Future<void> _deleteServer(String id) async {
    setState(() => servers.removeWhere((s) => s.id == id));
    await UserManager.saveServers(servers);
  }

  Future<void> _upgradePremium() async {
    // ဒီနေရာမှာ တကယ့် Payment Gateway (KBZPay, WaveMoney, Google Play Billing) နဲ့ ချိတ်ရပါမယ်။
    // လောလောဆယ် Mock အနေနဲ့ ၃ စက္ကန့်စောင့်ပြီး Premium ဖြစ်သွားအောင် လုပ်ထားပါတယ်။
    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));
    await Future.delayed(const Duration(seconds: 3));
    Navigator.pop(context); // close loading
    await UserManager.setPremium(true);
    setState(() => isPremium = true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Upgraded to Premium!")));
  }

  @override
  Widget build(BuildContext context) {
    bool d = widget.isDark;
    
    if (selectedServer == null && servers.isNotEmpty) selectedServer = servers.first;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(children: [
        Positioned.fill(child: Container(color: d ? const Color(0xFF070B16) : const Color(0xFFE8EDF7))), 
        SafeArea(
          child: IndexedStack(index: pageIndex, children: [
            // Home (ဆာဗာ မရှိရင် ရွေးခိုင်းမယ်)
            selectedServer != null 
              ? HomePage(isDark: d, selectedServer: selectedServer!, isPremium: isPremium, onUpgrade: _upgradePremium)
              : Center(child: Text("Please add a server", style: TextStyle(color: d ? Colors.white : Colors.black))),
            
            // Servers (Add & Delete လုပ်လို့ရမယ်)
            ServersPage(
              isDark: d, 
              servers: servers, 
              selected: selectedServer,
              onSelect: (s) => setState(() { selectedServer = s; pageIndex = 0; }),
              onDelete: _deleteServer,
              onAdd: () => _showAddServerDialog(),
            ),

            // User Profile & Info
            ProfilePage(isDark: d, isPremium: isPremium, onUpgrade: _upgradePremium),
            
            SettingsPage(isDark: d, toggle: widget.toggle),
          ]),
        ),
        // Bottom Navigation Bar
        Positioned(
          bottom: 20, left: 20, right: 20,
          child: _glass(d, const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _nav(0, Icons.home_outlined, "Home", d),
                _nav(1, Icons.public, "Servers", d),
                _nav(2, Icons.person_outline, "Profile", d),
                _nav(3, Icons.settings, "Settings", d),
              ],
            )),
        ),
      ]),
    );
  }

  void _showAddServerDialog() {
    final nameCtrl = TextEditingController();
    final linkCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Add New Server"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Server Name (e.g. US Server)")),
          TextField(controller: linkCtrl, decoration: const InputDecoration(labelText: "VLESS Link (vless://...)")),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (linkCtrl.text.isNotEmpty && nameCtrl.text.isNotEmpty) {
                _addServer(ServerModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameCtrl.text,
                  country: "Custom",
                  flag: "🌐",
                  vlessLink: linkCtrl.text.trim(),
                ));
                Navigator.pop(c);
              }
            }, 
            child: const Text("Add")
          )
        ],
      )
    );
  }

  Widget _glass(bool d, EdgeInsets padding, Widget child) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: d ? const Color(0xFF131A2B).withOpacity(0.9) : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
  }

  Widget _nav(int i, IconData ic, String t, bool d) {
    return GestureDetector(
      onTap: () => setState(() => pageIndex = i),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(ic, size: 24, color: pageIndex == i ? const Color(0xFFFF8A32) : Colors.grey),
        Text(t, style: TextStyle(fontSize: 10, color: pageIndex == i ? const Color(0xFFFF8A32) : Colors.grey)),
      ]),
    );
  }
}

// ==========================================
// 3. Pages
// ==========================================

class HomePage extends StatefulWidget {
  final bool isDark;
  final ServerModel selectedServer;
  final bool isPremium;
  final VoidCallback onUpgrade;
  const HomePage({super.key, required this.isDark, required this.selectedServer, required this.isPremium, required this.onUpgrade});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isConnected = false, isConnecting = false;
  final V2rayManager _mgr = V2rayManager();
  int downloadSpeed = 0, uploadSpeed = 0;

  @override
  void initState() {
    super.initState();
    _mgr.initialize(onStatusChanged: _onVpnStatus);
  }

  void _onVpnStatus(dynamic status) {
    if (!mounted) return;
    setState(() {
      isConnected = status.state.toString().toUpperCase().contains('CONNECTED');
      isConnecting = false;
      downloadSpeed = status.downloadSpeed ?? 0;
      uploadSpeed = status.uploadSpeed ?? 0;
    });
  }

  Future<void> _connectVpn() async {
    // Free User တွေကို ကန့်သတ်ချင်ရင် ဒီနေရာမှာ Code ထည့်နိုင်ပါတယ်
    // if (!widget.isPremium) { widget.onUpgrade(); return; }

    if (isConnecting) return;
    setState(() => isConnecting = true);
    
    final ready = await _mgr.ensureInitialized();
    if (!ready) { setState(() => isConnecting = false); return; }

    bool? permission = await _mgr.v2ray.requestPermission();
    if (permission != true) { setState(() => isConnecting = false); return; }

    final parser = V2ray.parseFromURL(widget.selectedServer.vlessLink);
    _mgr.v2ray.startV2Ray(
      remark: parser.remark.isNotEmpty ? parser.remark : "CX VPN",
      config: parser.getFullConfiguration(),
    );
    setState(() => isConnecting = false);
  }

  @override
  Widget build(BuildContext context) {
    bool d = widget.isDark;
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('${widget.selectedServer.flag} ${widget.selectedServer.name}', style: TextStyle(fontSize: 20, color: Colors.grey)),
        const SizedBox(height: 30),
        Text(
          isConnected ? 'Connected' : (isConnecting ? 'Connecting...' : 'Disconnected'),
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isConnected ? Colors.green : (d ? Colors.white : Colors.black)),
        ),
        if (isConnected) Text('↓ $downloadSpeed KB/s   ↑ $uploadSpeed KB/s', style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () {
            if (isConnected) {
              _mgr.v2ray.stopV2Ray();
              setState(() => isConnected = false);
            } else {
              _connectVpn();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isConnected ? Colors.redAccent : const Color(0xFFFF8A32),
            padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: Text(isConnected ? 'Disconnect' : 'Connect', style: const TextStyle(fontSize: 20, color: Colors.white)),
        ),
      ]),
    );
  }
}

class ServersPage extends StatelessWidget {
  final bool isDark;
  final List<ServerModel> servers;
  final ServerModel? selected;
  final Function(ServerModel) onSelect;
  final Function(String) onDelete;
  final VoidCallback onAdd;

  const ServersPage({super.key, required this.isDark, required this.servers, this.selected, required this.onSelect, required this.onDelete, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: onAdd,
        backgroundColor: const Color(0xFFFF8A32),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListView.builder(
        itemCount: servers.length,
        padding: const EdgeInsets.only(top: 20, bottom: 100),
        itemBuilder: (context, index) {
          final s = servers[index];
          return ListTile(
            leading: Text(s.flag, style: const TextStyle(fontSize: 24)),
            title: Text(s.name, style: TextStyle(color: isDark ? Colors.white : Colors.black)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              if (selected?.id == s.id) const Icon(Icons.check_circle, color: Color(0xFFFF8A32)),
              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => onDelete(s.id)),
            ]),
            onTap: () => onSelect(s),
          );
        },
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  final bool isDark;
  final bool isPremium;
  final VoidCallback onUpgrade;

  const ProfilePage({super.key, required this.isDark, required this.isPremium, required this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(radius: 50, backgroundColor: Color(0xFFFF8A32), child: Icon(Icons.person, size: 50, color: Colors.white)),
          const SizedBox(height: 20),
          Text("User Name", style: TextStyle(fontSize: 22, color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
          Text(isPremium ? "Premium Member ⭐" : "Free User", style: TextStyle(color: isPremium ? Colors.yellow : Colors.grey)),
          const SizedBox(height: 40),
          if (!isPremium)
            ElevatedButton(
              onPressed: onUpgrade,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.all(15)),
              child: const Text("Upgrade to Premium (Mock Payment)", style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
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
      child: SwitchListTile(
        title: Text('Dark Mode', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        value: isDark,
        onChanged: (v) => toggle(),
      ),
    );
  }
}
