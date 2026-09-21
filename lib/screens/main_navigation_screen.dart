import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_repository.dart';
import '../services/notification_service.dart';
import 'dashboard_screen.dart';
import 'air_quality_screen.dart';
import 'water_log_screen.dart';
import 'screen_time_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final User user;
  const MainNavigationScreen({super.key, required this.user});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // Real screens with hardcoded telemetry and layout
  final List<Widget> _screens = const [
    DashboardScreen(),
    AirQualityScreen(),
    WaterScreen(),
    ScreenTimeScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    final userId = widget.user.uid;

    FirestoreRepository.instance.initializeDefaultSettings(userId);

    FirestoreRepository.instance.getAirQualityLogsStream(userId, limit: 1).listen((logs) {
      if (logs.isNotEmpty) {
        final latest = logs.first;
        if (latest.timestamp.isAfter(DateTime.now().subtract(const Duration(minutes: 1)))) {
          if (latest.thresholdStatus.toLowerCase() == 'bad' || latest.thresholdStatus.toLowerCase() == 'worst') {
            NotificationService.instance.showNotification(
              id: 1,
              title: 'Air Quality Alert!',
              body: 'Air quality is ${latest.thresholdStatus} (${latest.ppmValue} PPM). Device buzzing now.',
            );
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
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