import 'package:flutter/material.dart';
import 'dart:ui';

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
    Color bgColor = isDark ? const Color(0xFF070B16) : const Color(0xFFE8EDF7);
    
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
          _buildAmbientBackground(isDark),
          
          SafeArea(
            child: IndexedStack(
              index: currentPageIndex,
              children: [
                HomePage(isDark: isDark, toggleTheme: widget.toggleTheme),
                Center(child: Text("Servers Page", style: TextStyle(color: isDark ? Colors.white : Colors.black))),
                Center(child: Text("Settings Page", style: TextStyle(color: isDark ? Colors.white : Colors.black))),
                Center(child: Text("Premium Page", style: TextStyle(color: isDark ? Colors.white : Colors.black))),
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
                  _buildNavItem(1, Icons.language, "Servers", isDark),
                  _buildNavItem(2, Icons.settings_outlined, "Settings", isDark),
                  _buildNavItem(3, Icons.workspace_premium_outlined, "Premium", isDark),
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
            Icon(icon, color: isActive ? const Color(0xFFFFB66D) : (isDark ? const Color(0xFF929DB5) : const Color(0xFF65718A))),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, color: isActive ? const Color(0xFFFFB66D) : (isDark ? const Color(0xFF929DB5) : const Color(0xFF65718A)))),
          ],
        ),
      ),
    );
  }

  Widget _buildAmbientBackground(bool isDark) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [const Color(0xFF080D1B), const Color(0xFF060914)]
              : [const Color(0xFFEDF2FF), const Color(0xFFDCE5F5)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: MediaQuery.of(context).size.height * 0.16,
              left: -100,
              child: Container(
                width: 260, height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF377BFF).withOpacity(0.18),
                  boxShadow: [BoxShadow(color: const Color(0xFF377BFF).withOpacity(0.18), blurRadius: 85)],
                ),
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.12,
              right: -100,
              child: Container(
                width: 260, height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF812D).withOpacity(0.18),
                  boxShadow: [BoxShadow(color: const Color(0xFFFF812D).withOpacity(0.18), blurRadius: 85)],
                ),
              ),
            ),
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

class _HomePageState extends State<HomePage> {
  bool isConnected = false;

  @override
  Widget build(BuildContext context) {
    Color textColor = widget.isDark ? const Color(0xFFF4F7FF) : const Color(0xFF182239);
    Color mutedColor = widget.isDark ? const Color(0xFF929DB5) : const Color(0xFF65718A);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 100),
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

          // Welcome Text
          Text("WELCOME BACK", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, color: mutedColor)),
          const SizedBox(height: 9),
          RichText(
            text: TextSpan(
              text: 'Your digital\nworld, ',
              style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold, height: 1.2, color: textColor),
              children: const [TextSpan(text: 'protected.', style: TextStyle(color: Color(0xFFFFB66D)))],
            ),
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
                    width: 166, height: 166,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isConnected ? const Color(0xFF5DE2A0).withOpacity(0.1) : (widget.isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6)),
                      border: Border.all(
                        color: isConnected ? const Color(0xFF5DE2A0) : (widget.isDark ? Colors.white.withOpacity(0.3) : Colors.white),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isConnected ? const Color(0xFF5DE2A0).withOpacity(0.4) : (widget.isDark ? const Color(0xFFFF8A32).withOpacity(0.13) : Colors.black.withOpacity(0.05)),
                          blurRadius: 45, spreadRadius: 5,
                        )
                      ]
                    ),
                    child: Center(
                      child: Container(
                        width: 124, height: 124,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.8),
                          border: Border.all(color: widget.isDark ? Colors.white.withOpacity(0.2) : Colors.white),
                        ),
                        child: Icon(Icons.power_settings_new, size: 48, color: isConnected ? const Color(0xFF5DE2A0) : textColor),
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

          const SizedBox(height: 15),

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
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: isDark ? [const Color(0xFF080D1B), const Color(0xFF060914)] : [const Color(0xFFEDF2FF), const Color(0xFFDCE5F5)],
                ),
              ),
            ),
          ),
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
                        _buildLoginBtn("Continue with Reddit", Icons.forum, isDark, textColor, () {}), // Changed icon to forum to avoid errors
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
            // ERROR FIX: Removed 'color' here because we use 'gradient'
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
