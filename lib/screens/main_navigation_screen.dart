import 'settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_repository.dart';
import '../services/notification_service.dart';
import '../models/air_quality_log.dart';

class MainNavigationScreen extends StatefulWidget {
  final User user;
  const MainNavigationScreen({super.key, required this.user});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    final userId = widget.user.uid;
    // Ensure default settings exist in Firestore when a new user logs in
    FirestoreRepository.instance.initializeDefaultSettings(widget.user.uid);

    FirestoreRepository.instance.getAirQualityLogsStream(userId, limit: 1).listen((logs) {
    if (logs.isNotEmpty) {
      final latest = logs.first;
      // Only alert if it's recent (within the last minute) to avoid spamming old logs on startup
      if (latest.timestamp.isAfter(DateTime.now().subtract(const Duration(minutes: 1)))) {
        if (latest.thresholdStatus == 'bad' || latest.thresholdStatus == 'worst') {
          NotificationService.instance.showAlert(
            id: 1,
            title: 'Air Quality Alert!',
            body: 'Air quality is ${latest.thresholdStatus} (${latest.ppmValue} PPM). Device buzzing now.',
          );
        }
      }
    }
  });
  }

  // Placeholder screens for Phase 4, 5, and 6
    final List<Widget> _screens = [
        const DashboardScreen(),
        const AirQualityScreen(),
        const WaterLogScreen(),
        const ScreenTimeScreen(),
        const SettingsScreen(),
    ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sage Workspace"),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.tealAccent,
        unselectedItemColor: Colors.grey,
        backgroundColor: const Color(0xFF1E1E1E),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dash"),
          BottomNavigationBarItem(icon: Icon(Icons.air), label: "Air"),
          BottomNavigationBarItem(icon: Icon(Icons.water_drop), label: "Water"),
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: "Screen"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}