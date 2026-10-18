import 'package:flutter/material.dart';

void main() {
  runApp(const CXVpnApp());
}

class CXVpnApp extends StatelessWidget {
  const CXVpnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CX VPN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050810),
        primaryColor: const Color(0xFFFF8A32),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isConnected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'CX VPN',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.brightness_6, color: Colors.white), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.settings, color: Colors.white), onPressed: () {}),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 50),
            GestureDetector(
              onTap: () {
                setState(() {
                  isConnected = !isConnected;
                });
              },
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(36),
                  color: isConnected ? Colors.green.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                  border: Border.all(
                    color: isConnected ? Colors.green : Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.power_settings_new,
                    size: 50,
                    color: isConnected ? Colors.green : Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isConnected ? "CONNECTED" : "NOT CONNECTED",
              style: TextStyle(
                fontSize: 18, 
                letterSpacing: 2,
                color: isConnected ? Colors.green : Colors.white
              ),
            ),
          ],
        ),
      ),
    );
  }
}
