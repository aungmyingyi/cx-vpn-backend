import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() => runApp(const CXVpnApp());

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
      theme: ThemeData(brightness: Brightness.light, scaffoldBackgroundColor: const Color(0xFFE8EDF7), primaryColor: const Color(0xFFFF8A32)),
      darkTheme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: const Color(0xFF070B16), primaryColor: const Color(0xFFFF8A32)),
      home: MainScreen(isDark: isDark, toggle: () => setState(() => isDark = !isDark)),
    );
  }
}

class MainScreen extends StatefulWidget {
  final bool isDark; final VoidCallback toggle;
  const MainScreen({super.key, required this.isDark, required this.toggle});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool isSplash = true, isLoggedIn = false;
  int pageIndex = 0; 

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () { if (mounted) setState(() => isSplash = false); });
  }

  @override
  Widget build(BuildContext context) {
    bool d = widget.isDark;
    if (isSplash) {
      return Scaffold(backgroundColor: d ? const Color(0xFF050810) : const Color(0xFFE8EDF7),
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('CX VPN', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: d ? Colors.white : Colors.black)),
          const SizedBox(height: 20), const CircularProgressIndicator(color: Color(0xFFFF8A32)),
          const SizedBox(height: 20), Text('POWERED BY CEREBRA X', style: TextStyle(fontSize: 10, color: d ? Colors.grey : Colors.black54))
        ])));
    }
    if (!isLoggedIn) return LoginScreen(isDark: d, onLogin: () => setState(() => isLoggedIn = true));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(children: [
        Positioned.fill(child: SkyBackground(isDark: d)),
        SafeArea(child: IndexedStack(index: pageIndex, children: [
          HomePage(isDark: d, toggle: widget.toggle),
          const Center(child: Text("Servers Page (Coming Soon)")),
          const Center(child: Text("Settings Page (Coming Soon)")),
          const Center(child: Text("Premium Page (Coming Soon)")),
        ])),
        Positioned(bottom: 20, left: 20, right: 20, child: _glass(d, const EdgeInsets.symmetric(vertical: 8, horizontal: 8), Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _nav(0, Icons.home_outlined, "Home", d), _nav(1, Icons.public, "Servers", d), _nav(2, Icons.settings, "Settings", d), _nav(3, Icons.workspace_premium, "Premium", d),
        ]))),
      ]),
    );
  }

  Widget _nav(int i, IconData ic, String t, bool d) => GestureDetector(
    onTap: () => setState(() => pageIndex = i),
    child: Container(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20), decoration: BoxDecoration(color: pageIndex == i ? const Color(0xFFFF8A32).withOpacity(0.15) : Colors.transparent, borderRadius: BorderRadius.circular(16)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(ic, size: 22, color: pageIndex == i ? const Color(0xFFFFB66D) : (d ? const Color(0xFF929DB5) : const Color(0xFF65718A))),
        const SizedBox(height: 4), Text(t, style: TextStyle(fontSize: 10, color: pageIndex == i ? const Color(0xFFFFB66D) : (d ? const Color(0xFF929DB5) : const Color(0xFF65718A)))),
      ])),
  );
}

class HomePage extends StatefulWidget {
  final bool isDark; final VoidCallback toggle;
  const HomePage({super.key, required this.isDark, required this.toggle});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  bool isConnected = false;
  late AnimationController _spin, _glitch;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _glitch = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
  }

  @override
  void dispose() { _spin.dispose(); _glitch.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    bool d = widget.isDark;
    Color txt = d ? const Color(0xFFF4F7FF) : const Color(0xFF182239);
    Color mut = d ? const Color(0xFF929DB5) : const Color(0xFF65718A);
    Color con = d ? const Color(0xFF5DE2A0) : const Color(0xFF16A34A);

    return SingleChildScrollView(physics: const BouncingScrollPhysics(), padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 120), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        RichText(text: TextSpan(text: 'CX ', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: txt, letterSpacing: -1.2), children: const [TextSpan(text: 'VPN', style: TextStyle(color: Color(0xFFFF8A32)))])),
        Row(children: [
          GestureDetector(onTap: widget.toggle, child: _icon(d ? Icons.wb_sunny_outlined : Icons.nightlight_round, d)),
          const SizedBox(width: 8), _icon(Icons.settings, d),
        ]),
      ]),
      const SizedBox(height: 34),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("WELCOME BACK", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, color: mut)),
          const SizedBox(height: 9),
          RichText(text: TextSpan(text: 'Your digital\nworld, ', style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold, height: 1.2, color: txt), children: const [TextSpan(text: 'protected.', style: TextStyle(color: Color(0xFFFFB66D)))])),
        ]),
        Container(width: 58, height: 58, decoration: BoxDecoration(color: const Color(0xFFFF8A32).withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFFF8A32).withOpacity(0.3))),
          child: Center(child: RotationTransition(turns: _spin, child: const Icon(Icons.settings_input_component, color: Color(0xFFFFB66D), size: 30)))),
      ]),
      Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: Center(child: Column(children: [
        RepaintBoundary(child: GestureDetector(onTap: () => setState(() => isConnected = !isConnected), child: Stack(alignment: Alignment.center, children: [
          if (isConnected) ...[
            AnimatedBuilder(animation: _glitch, builder: (c, w) => Transform.translate(offset: Offset(math.sin(_glitch.value * math.pi * 4) * 8, 0), child: Container(width: 150, height: 150, decoration: BoxDecoration(borderRadius: BorderRadius.circular(36), border: Border.all(color: Colors.cyanAccent.withOpacity(0.8), width: 3))))),
            AnimatedBuilder(animation: _glitch, builder: (c, w) => Transform.translate(offset: Offset(math.cos(_glitch.value * math.pi * 4) * -8, 0), child: Container(width: 150, height: 150, decoration: BoxDecoration(borderRadius: BorderRadius.circular(36), border: Border.all(color: Colors.pinkAccent.withOpacity(0.8), width: 3))))),
          ],
          AnimatedContainer(duration: const Duration(milliseconds: 300), width: 150, height: 150, decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36), color: isConnected ? con.withOpacity(0.15) : (d ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.7)),
            border: Border.all(color: isConnected ? con : (d ? Colors.white.withOpacity(0.3) : Colors.white), width: 1.5),
            boxShadow: [BoxShadow(color: isConnected ? con.withOpacity(0.4) : (d ? const Color(0xFFFF8A32).withOpacity(0.15) : Colors.black.withOpacity(0.05)), blurRadius: 45, spreadRadius: 5)],
          ), child: Center(child: Icon(Icons.power_settings_new, size: 42, color: isConnected ? con : txt))),
        ]))),
        const SizedBox(height: 25),
        Text(isConnected ? "CONNECTED" : "NOT CONNECTED", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 2, color: isConnected ? con : txt)),
        const SizedBox(height: 7), Text(isConnected ? "Your connection is secured" : "Tap to connect securely", style: TextStyle(fontSize: 12, color: mut)),
        const SizedBox(height: 15),
        Container(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9), decoration: BoxDecoration(color: d ? Colors.white.withOpacity(0.065) : Colors.white.withOpacity(0.7), borderRadius: BorderRadius.circular(99), border: Border.all(color: d ? Colors.white.withOpacity(0.14) : Colors.black12)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: isConnected ? con : const Color(0xFF9099AC), boxShadow: isConnected ? [BoxShadow(color: con.withOpacity(0.8), blurRadius: 12)] : [])),
            const SizedBox(width: 8), Text(isConnected ? "Protected" : "Ready to connect", style: TextStyle(fontSize: 11, color: isConnected ? con : mut)),
          ])),
      ]))),
      _glass(d, const EdgeInsets.all(16), Row(children: [
        Container(width: 45, height: 45, decoration: BoxDecoration(color: d ? Colors.white.withOpacity(0.1) : Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: d ? Colors.white.withOpacity(0.1) : Colors.black12)), child: const Center(child: Text("🌐", style: TextStyle(fontSize: 22)))),
        const SizedBox(width: 15),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("YOUR LOCATION", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: mut)),
          const SizedBox(height: 5), Text("Auto Location", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: txt)),
          const SizedBox(height: 3), Text("Select a server location", style: TextStyle(fontSize: 11, color: mut)),
        ])),
        Icon(Icons.arrow_forward_ios, size: 16, color: mut),
      ])),
      const SizedBox(height: 13),
      Row(children: [
        _stat("0 B", "Downloaded", Icons.arrow_downward, d, txt, mut), const SizedBox(width: 10),
        _stat("0 B", "Uploaded", Icons.arrow_upward, d, txt, mut), const SizedBox(width: 10),
        _stat("--", "Ping", Icons.access_time, d, txt, mut),
      ]),
      const SizedBox(height: 15),
      _glass(d, const EdgeInsets.all(16), Row(children: [
        Container(width: 45, height: 45, decoration: BoxDecoration(color: const Color(0xFFFF8A32).withOpacity(0.15), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.workspace_premium, color: Color(0xFFFFB66D))),
        const SizedBox(width: 15),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("CX Premium", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: txt)),
          const SizedBox(height: 5), Text("Unlock your full potential", style: TextStyle(fontSize: 11, color: mut)),
        ])),
        Icon(Icons.arrow_forward_ios, size: 16, color: mut),
      ])),
    ]));
  }

  Widget _icon(IconData ic, bool d) => Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: d ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(12), border: Border.all(color: d ? Colors.white.withOpacity(0.1) : Colors.white)), child: Icon(ic, size: 22, color: d ? Colors.white : const Color(0xFF182239)));
  Widget _stat(String v, String l, IconData ic, bool d, Color t, Color m) => Expanded(child: _glass(d, const EdgeInsets.all(15), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(ic, color: const Color(0xFFFFB66D), size: 19), const SizedBox(height: 8), Text(v, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: t)), const SizedBox(height: 4), Text(l, style: TextStyle(fontSize: 10, color: m))
  ])));
}

class LoginScreen extends StatelessWidget {
  final bool isDark; final VoidCallback onLogin;
  const LoginScreen({super.key, required this.isDark, required this.onLogin});
  @override
  Widget build(BuildContext context) {
    bool d = isDark; Color txt = d ? const Color(0xFFF4F7FF) : const Color(0xFF182239); Color mut = d ? const Color(0xFF929DB5) : const Color(0xFF65718A);
    return Scaffold(body: Stack(children: [
      Positioned.fill(child: SkyBackground(isDark: d)),
      SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          RichText(text: TextSpan(text: 'CX ', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: txt), children: const [TextSpan(text: 'VPN', style: TextStyle(color: Color(0xFFFF8A32)))])),
          _glass(d, const EdgeInsets.symmetric(horizontal: 12, vertical: 6), Text("EN", style: TextStyle(fontSize: 12, color: txt))),
        ]),
        const Spacer(),
        Container(width: 76, height: 76, decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), gradient: const LinearGradient(colors: [Color(0xFFFFBD76), Color(0xFFFF7929)])), child: const Center(child: Text("ϟ", style: TextStyle(fontSize: 43, color: Colors.white)))),
        const SizedBox(height: 25),
        RichText(textAlign: TextAlign.center, text: TextSpan(text: 'Your internet.\n', style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, height: 1.15, color: txt), children: const [TextSpan(text: 'Your freedom.', style: TextStyle(color: Color(0xFFFFB66D)))])),
        const SizedBox(height: 10), Text("Secure, private and connected.", style: TextStyle(color: mut)),
        const Spacer(),
        _glass(d, const EdgeInsets.all(21), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("GET STARTED", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, color: mut)), const SizedBox(height: 15),
          _btn("Continue as Guest", Icons.person_outline, d, txt, onLogin), const SizedBox(height: 12),
          _btn("Continue with Google", Icons.g_mobiledata, d, txt, () {}), const SizedBox(height: 12),
          _btn("Continue with Reddit", Icons.forum, d, txt, () {}),
        ])),
        const Spacer(), Text("POWERED BY CEREBRA X", style: TextStyle(fontSize: 10, letterSpacing: 2, color: mut)),
      ])))
    ]));
  }
  Widget _btn(String t, IconData ic, bool d, Color tc, VoidCallback tap) => GestureDetector(onTap: tap, child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14), decoration: BoxDecoration(color: d ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6), border: Border.all(color: d ? Colors.white.withOpacity(0.14) : Colors.white), borderRadius: BorderRadius.circular(16)),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: d ? Colors.white.withOpacity(0.1) : Colors.white, borderRadius: BorderRadius.circular(12)), child: Icon(ic, size: 20, color: tc)),
      const SizedBox(width: 13), Text(t, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: tc)),
      const Spacer(), Icon(Icons.arrow_forward_ios, size: 16, color: tc.withOpacity(0.5)),
    ]),
  ));
}

class SkyBackground extends StatefulWidget {
  final bool isDark; const SkyBackground({super.key, required this.isDark});
  @override
  State<SkyBackground> createState() => _SkyBackgroundState();
}
class _SkyBackgroundState extends State<SkyBackground> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat(); }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    bool d = widget.isDark;
    return AnimatedContainer(duration: const Duration(milliseconds: 800), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: d ? [const Color(0xFF020513), const Color(0xFF0A1128), const Color(0xFF192542)] : [const Color(0xFF4FACFE), const Color(0xFF00F2FE), const Color(0xFFE0F6FF)])),
      child: Stack(children: [
        Positioned(top: MediaQuery.of(context).size.height * 0.08, right: MediaQuery.of(context).size.width * 0.12, child: AnimatedContainer(duration: const Duration(milliseconds: 800), width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle, color: d ? Colors.white : const Color(0xFFFFDB58), boxShadow: [BoxShadow(color: d ? Colors.white.withOpacity(0.3) : const Color(0xFFFFDB58).withOpacity(0.6), blurRadius: 40, spreadRadius: 10)]))),
        Positioned.fill(child: AnimatedBuilder(animation: _c, builder: (c, w) => CustomPaint(painter: LeafP(progress: _c.value, isDark: d)))),
        Positioned(bottom: -10, left: 0, right: 0, child: CustomPaint(size: Size(MediaQuery.of(context).size.width, 300), painter: TreeP(isDark: d))),
      ]),
    );
  }
}

class LeafP extends CustomPainter {
  final double progress; final bool isDark; LeafP({required this.progress, required this.isDark});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = isDark ? const Color(0xFFFF8A32) : const Color(0xFF16A34A)..style = PaintingStyle.fill;
    final r = math.Random(123);
    for (int i = 0; i < 20; i++) {
      double sx = r.nextDouble() * size.width, dl = r.nextDouble(), sp = 0.5 + r.nextDouble();
      double cp = (progress * sp + dl) % 1.0, y = size.height * cp, x = sx + (math.sin(cp * math.pi * 4) * 40);
      canvas.save(); canvas.translate(x, y); canvas.rotate(cp * math.pi * 2);
      Path pth = Path()..moveTo(0, 0)..quadraticBezierTo(7, -7, 14, 0)..quadraticBezierTo(7, 7, 0, 0);
      canvas.drawPath(pth, p); canvas.restore();
    }
  }
  @override
  bool shouldRepaint(covariant LeafP old) => old.progress != progress;
}

class TreeP extends CustomPainter {
  final bool isDark; TreeP({required this.isDark});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = isDark ? Colors.black.withOpacity(0.85) : const Color(0xFF0F172A).withOpacity(0.6)..style = PaintingStyle.fill;
    double w = size.width, h = size.height;
    final pth = Path()..moveTo(w * 0.35, h)..cubicTo(w * 0.37, h * 0.8, w * 0.4, h * 0.63, w * 0.25, h * 0.46)..cubicTo(w * 0.2, h * 0.4, w * 0.1, h * 0.33, w * 0.05, h * 0.26)
      ..cubicTo(w * 0.15, h * 0.3, w * 0.25, h * 0.36, w * 0.35, h * 0.43)..cubicTo(w * 0.37, h * 0.33, w * 0.32, h * 0.2, w * 0.4, h * 0.06)..cubicTo(w * 0.42, h * 0.2, w * 0.45, h * 0.33, w * 0.47, h * 0.46)
      ..cubicTo(w * 0.57, h * 0.33, w * 0.7, h * 0.23, w * 0.85, h * 0.16)..cubicTo(w * 0.72, h * 0.26, w * 0.62, h * 0.4, w * 0.57, h * 0.53)..cubicTo(w * 0.65, h * 0.6, w * 0.75, h * 0.66, w * 0.9, h * 0.73)
      ..cubicTo(w * 0.7, h * 0.7, w * 0.6, h * 0.63, w * 0.52, h * 0.56)..cubicTo(w * 0.5, h * 0.66, w * 0.52, h * 0.8, w * 0.55, h)..close();
    canvas.drawPath(pth, p);
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

Widget _glass(bool d, EdgeInsets p, Widget c) => Container(padding: p, decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), border: Border.all(color: d ? Colors.white.withOpacity(0.15) : Colors.white, width: 1.5), color: d ? const Color(0xFF1E293B).withOpacity(0.6) : Colors.white.withOpacity(0.7), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 1)]), child: c);
