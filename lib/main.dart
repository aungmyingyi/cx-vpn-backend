import 'package:flutter/material.dart';
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
        scaffoldBackgroundColor: const Color(0xFFE0F6FF), // Light sky
        primaryColor: const Color(0xFFFF8A32),
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF020513), // Dark sky
        primaryColor: const Color(0xFFFF8A32),
        fontFamily: 'Roboto',
      ),
      home: HomeScreen(isDarkMode: isDarkMode, toggleTheme: toggleTheme),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback toggleTheme;

  const HomeScreen({super.key, required this.isDarkMode, required this.toggleTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool isConnected = false;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(); // ပျားအုံအတွင်းလိုင်း အမြဲလည်နေစေရန်
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = widget.isDarkMode;
    Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    Color subTextColor = isDark ? Colors.grey : const Color(0xFF475569);
    Color bgGradientTop = isDark ? const Color(0xFF020513) : const Color(0xFF4FACFE);
    Color bgGradientBottom = isDark ? const Color(0xFF192542) : const Color(0xFFE0F6FF);

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgGradientTop, bgGradientBottom],
          ),
        ),
        child: Stack(
          children: [
            // --- Background Elements (Sun/Moon & Tree) ---
            Positioned(
              top: MediaQuery.of(context).size.height * 0.1,
              right: MediaQuery.of(context).size.width * 0.15,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.white : const Color(0xFFFFDB58),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.white.withOpacity(0.2) : const Color(0xFFFFDB58).withOpacity(0.6),
                      blurRadius: 40,
                      spreadRadius: 10,
                    )
                  ],
                ),
              ),
            ),
            
            // Tree Silhouette (Custom Painter)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: CustomPaint(
                size: Size(MediaQuery.of(context).size.width, 250),
                painter: TreePainter(isDark: isDark),
              ),
            ),

            // --- Main UI ---
            SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RichText(
                          text: TextSpan(
                            text: 'CX ',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                            children: const [
                              TextSpan(text: 'VPN', style: TextStyle(color: Color(0xFFFF8A32))),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            _buildIconBtn(
                              icon: isDark ? Icons.brightness_6 : Icons.wb_sunny,
                              onTap: widget.toggleTheme,
                              isDark: isDark,
                            ),
                            const SizedBox(width: 10),
                            _buildIconBtn(
                              icon: Icons.settings,
                              onTap: () {},
                              isDark: isDark,
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),

                  // Welcome Text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("WELCOME BACK", style: TextStyle(fontSize: 10, letterSpacing: 2, color: subTextColor)),
                          const SizedBox(height: 5),
                          Text(
                            "Your digital\nworld, protected.",
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.2, color: textColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Honeycomb Icon (ညာဘက်အပေါ်ထောင့်နားက)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 25, top: 10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.white),
                        ),
                        child: RotationTransition(
                          turns: _rotationController,
                          child: const Icon(Icons.settings_input_component, color: Color(0xFFFF8A32), size: 30),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Squircle Connect Button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isConnected = !isConnected;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40), // Squircle
                        color: isConnected 
                            ? Colors.green.withOpacity(0.1) 
                            : (isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7)),
                        border: Border.all(
                          color: isConnected 
                              ? Colors.greenAccent 
                              : (isDark ? Colors.white.withOpacity(0.3) : Colors.white),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isConnected 
                                ? Colors.greenAccent.withOpacity(0.4) 
                                : (isDark ? Colors.transparent : Colors.black.withOpacity(0.05)),
                            blurRadius: 40,
                            spreadRadius: 5,
                          )
                        ]
                      ),
                      child: Center(
                        child: Icon(
                          Icons.power_settings_new,
                          size: 60,
                          color: isConnected ? Colors.greenAccent : textColor,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Status Text
                  Text(
                    isConnected ? "CONNECTED" : "NOT CONNECTED",
                    style: TextStyle(
                      fontSize: 18, 
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                      color: isConnected ? Colors.greenAccent : textColor
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isConnected ? "Your connection is secured" : "Tap to connect securely",
                    style: TextStyle(fontSize: 12, color: subTextColor),
                  ),

                  const Spacer(),

                  // Glass Server Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6),
                          border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.white),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.public, color: Color(0xFFFF8A32)),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("YOUR LOCATION", style: TextStyle(fontSize: 10, letterSpacing: 1, color: subTextColor)),
                                  const SizedBox(height: 4),
                                  Text("Auto Location", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 16, color: subTextColor),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBtn({required IconData icon, required VoidCallback onTap, required bool isDark}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.white),
        ),
        child: Icon(icon, size: 20, color: isDark ? Colors.white : const Color(0xFF0F172A)),
      ),
    );
  }
}

// သစ်ပင် (Tree Trunk) ဆွဲတဲ့ Class
class TreePainter extends CustomPainter {
  final bool isDark;
  TreePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.black.withOpacity(0.8) : const Color(0xFF0F172A).withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final path = Path();
    double w = size.width;
    double h = size.height;

    // သစ်ပင် ပင်စည်နဲ့ အကိုင်းအခက် ပုံသဏ္ဍာန်
    path.moveTo(w * 0.4, h);
    path.quadraticBezierTo(w * 0.45, h * 0.6, w * 0.3, h * 0.4);
    path.quadraticBezierTo(w * 0.2, h * 0.2, w * 0.1, h * 0.1);
    path.quadraticBezierTo(w * 0.3, h * 0.3, w * 0.4, h * 0.5);
    path.quadraticBezierTo(w * 0.45, h * 0.2, w * 0.6, h * 0.05);
    path.quadraticBezierTo(w * 0.55, h * 0.3, w * 0.5, h * 0.6);
    path.quadraticBezierTo(w * 0.7, h * 0.3, w * 0.9, h * 0.2);
    path.quadraticBezierTo(w * 0.75, h * 0.5, w * 0.6, h * 0.8);
    path.lineTo(w * 0.6, h);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
