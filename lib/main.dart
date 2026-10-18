import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;

void main() {
  runApp(const CXVpnApp());
}

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
  int currentPageIndex = 0; // 0: Home, 1: Servers, 2: Settings, 3: Premium

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => isSplash = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = widget.isDarkMode;
    Color bgColor = isDark ? const Color(0xFF050810) : const Color(0xFFE8EDF7);
    
    if (isSplash) {
      return Scaffold(
        body: Container(
          color: bgColor,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('CX VPN', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.white)),
                SizedBox(height: 20),
                CircularProgressIndicator(color: Color(0xFFFF8A32)),
                SizedBox(height: 20),
                Text('POWERED BY CEREBRA X', style: TextStyle(fontSize: 10, letterSpacing: 2, color: Colors.grey)),
              ],
            ),
          ),
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
      body: Stack(
        children: [
          // Sky Background
          SkyBackground(isDark: isDark),
          
          // Main Content
          SafeArea(
            child: IndexedStack(
              index: currentPageIndex,
              children: [
                HomePage(isDark: isDark, toggleTheme: widget.toggleTheme),
                const Center(child: Text("Servers Page (Coming Soon)")),
                const Center(child: Text("Settings Page (Coming Soon)")),
                const Center(child: Text("Premium Page (Coming Soon)")),
              ],
            ),
          ),

          // Bottom Navigation
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
          color: isActive ? const Color(0xFFFF8A32).withOpacity(0.1) : Colors.transparent,
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
  const HomePage({super.key, required this.isDark, required this.toggleTheme});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  bool isConnected = false;
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color textColor = widget.isDark ? const Color(0xFFF4F7FF) : const Color(0xFF182239);
    Color mutedColor = widget.isDark ? const Color(0xFF929DB5) : const Color(0xFF65718A);

    return SingleChildScrollView(
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
              // Honeycomb Icon
              Container(
                width: 58, height: 58,
                decoration: BoxDecoration(
                  color: widget.isDark ? const Color(0xFFFF8A32).withOpacity(0.09) : Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFF8A32).withOpacity(0.25)),
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
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => setState(() => isConnected = !isConnected),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 150, height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(36), // Squircle
                      color: isConnected 
                          ? const Color(0xFF5DE2A0).withOpacity(0.1) 
                          : (widget.isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6)),
                      border: Border.all(
                        color: isConnected 
                            ? const Color(0xFF5DE2A0) 
                            : (widget.isDark ? Colors.white.withOpacity(0.3) : Colors.white),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isConnected 
                              ? const Color(0xFF5DE2A0).withOpacity(0.4) 
                              : (widget.isDark ? const Color(0xFFFF8A32).withOpacity(0.13) : Colors.black.withOpacity(0.05)),
                          blurRadius: 45, spreadRadius: 5,
                        )
                      ]
                    ),
                    child: Center(
                      child: Container(
                        width: 110, height: 110,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          color: isConnected 
                              ? const Color(0xFF5DE2A0).withOpacity(0.1) 
                              : (widget.isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.8)),
                          border: Border.all(
                            color: isConnected ? const Color(0xFF5DE2A0).withOpacity(0.4) : (widget.isDark ? Colors.white.withOpacity(0.2) : Colors.white)
                          ),
                        ),
                        child: Icon(Icons.power_settings_new, size: 42, color: isConnected ? const Color(0xFF5DE2A0) : textColor),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Text(
                  isConnected ? "CONNECTED" : "NOT CONNECTED",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 2, color: isConnected ? const Color(0xFF5DE2A0) : textColor),
                ),
                const SizedBox(height: 7),
                Text(isConnected ? "Your connection is secured" : "Tap to connect securely", style: TextStyle(fontSize: 12, color: mutedColor)),
                
                const SizedBox(height: 15),
                // Status Pill
                Container(
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
                          color: isConnected ? const Color(0xFF5DE2A0) : const Color(0xFF9099AC),
                          boxShadow: isConnected ? [BoxShadow(color: const Color(0xFF5DE2A0).withOpacity(0.8), blurRadius: 12)] : [],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(isConnected ? "Protected" : "Ready to connect", style: TextStyle(fontSize: 11, color: mutedColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Server Card
          GlassContainer(
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
                  child: const Icon(Icons.public, color: Color(0xFFFFB66D)),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("YOUR LOCATION", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: mutedColor)),
                      const SizedBox(height: 5),
                      Text("Auto Location", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
                      const SizedBox(height: 3),
                      Text("Select a server location", style: TextStyle(fontSize: 11, color: mutedColor)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: mutedColor),
              ],
            ),
          ),

          const SizedBox(height: 13),

          // Stats Grid
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

          // Premium Banner
          GlassContainer(
            isDark: widget.isDark,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 45, height: 45,
                  decoration: BoxDecoration(color: const Color(0xFFFF8A32).withOpacity(0.13), borderRadius: BorderRadius.circular(15)),
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

          const SizedBox(height: 30),
          
          // Explore
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Explore", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textColor)),
              Text("YOUR VPN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, color: mutedColor)),
            ],
          ),
          const SizedBox(height: 14),

          // Feature Grid
          Row(
            children: [
              _buildFeatureCard("Routing Mode", "Customize traffic", Icons.alt_route, widget.isDark, textColor, mutedColor),
              const SizedBox(width: 12),
              _buildFeatureCard("Settings", "Personalize app", Icons.settings, widget.isDark, textColor, mutedColor),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildFeatureCard("Help Center", "Get assistance", Icons.help_outline, widget.isDark, textColor, mutedColor),
              const SizedBox(width: 12),
              _buildFeatureCard("Privacy", "Your protection", Icons.security, widget.isDark, textColor, mutedColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, bool isDark, Color text, Color muted) {
    return Expanded(
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
    );
  }

  Widget _buildFeatureCard(String title, String subtitle, IconData icon, bool isDark, Color text, Color muted) {
    return Expanded(
      child: GlassContainer(
        isDark: isDark,
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.07) : Colors.white,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.13) : Colors.transparent),
              ),
              child: Icon(icon, color: const Color(0xFFFFB66D), size: 20),
            ),
            const SizedBox(height: 15),
            Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: text)),
            const SizedBox(height: 5),
            Text(subtitle, style: TextStyle(fontSize: 10, color: muted)),
          ],
        ),
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
          SkyBackground(isDark: isDark),
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
// SKY BACKGROUND (Sun, Moon, Tree, Leaves)
// ==========================================
class SkyBackground extends StatefulWidget {
  final bool isDark;
  const SkyBackground({super.key, required this.isDark});

  @override
  State<SkyBackground> createState() => _SkyBackgroundState();
}

class _SkyBackgroundState extends State<SkyBackground> with TickerProviderStateMixin {
  late AnimationController _leafController;
  final List<Leaf> leaves = List.generate(15, (index) => Leaf());

  @override
  void initState() {
    super.initState();
    _leafController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }

  @override
  void dispose() {
    _leafController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedContainer(
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
            // Sun & Moon
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

            // Falling Leaves
            ...leaves.map((leaf) => AnimatedBuilder(
              animation: _leafController,
              builder: (context, child) {
                double progress = (_leafController.value + leaf.delay) % 1.0;
                double top = MediaQuery.of(context).size.height * progress;
                double left = (leaf.startX * MediaQuery.of(context).size.width) + (math.sin(progress * math.pi * 4) * 30);
                
                return Positioned(
                  top: top,
                  left: left,
                  child: Transform.rotate(
                    angle: progress * math.pi * 2,
                    child: Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        color: widget.isDark ? const Color(0xFFFF8A32) : const Color(0xFF16A34A),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
                        boxShadow: [BoxShadow(color: (widget.isDark ? const Color(0xFFFF8A32) : const Color(0xFF16A34A)).withOpacity(0.4), blurRadius: 4)],
                      ),
                    ),
                  ),
                );
              },
            )),

            // Tree Silhouette
            Positioned(
              bottom: -10, left: 0, right: 0,
              child: CustomPaint(
                size: Size(MediaQuery.of(context).size.width, 300),
                painter: TreePainter(isDark: widget.isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Leaf {
  final double startX = math.Random().nextDouble();
  final double delay = math.Random().nextDouble();
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

    // Translating the SVG Path to Flutter Path
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

// ==========================================
// REUSABLE GLASS COMPONENTS
// ==========================================
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.14) : const Color(0xFF2B3954).withOpacity(0.13),
              width: 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark 
                ? [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.02)] 
                : [Colors.white.withOpacity(0.8), Colors.white.withOpacity(0.4)],
            ),
          ),
          child: child,
        ),
      ),
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
