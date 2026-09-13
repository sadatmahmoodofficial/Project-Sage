import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_repository.dart';
import '../models/device_settings.dart';
import '../models/air_quality_log.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _userId = FirebaseAuth.instance.currentUser!.uid;
  final _repo = FirestoreRepository.instance;

  // Helper to calculate time until next water intake
  String _getNextWaterTime(List<String> times) {
    if (times.isEmpty) return "No times set";
    
    final now = DateTime.now();
    for (String time in times) {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      
      final scheduleTime = DateTime(now.year, now.month, now.day, hour, minute);
      if (scheduleTime.isAfter(now)) {
        final diff = scheduleTime.difference(now);
        return "${diff.inHours}h ${diff.inMinutes % 60}m remaining";
      }
    }
    return "All done for today!";
  }

  // Color logic for PPM Badge
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'good': return Colors.greenAccent;
      case 'bad': return Colors.orangeAccent;
      case 'worst': return Colors.redAccent;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Air Quality Real-Time Card
        const Text('Current Workspace Environment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        StreamBuilder<List<AirQualityLog>>(
          stream: _repo.getAirQualityLogsStream(_userId, limit: 1),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(child: Text('Waiting for ESP32 sensor data...')),
                ),
              );
            }

            final latestLog = snapshot.data!.first;
            return Card(
              shape: RoundedRectangleBorder(
                side: BorderSide(color: _getStatusColor(latestLog.thresholdStatus), width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      '${latestLog.ppmValue} PPM',
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(latestLog.thresholdStatus.toUpperCase()),
                      backgroundColor: _getStatusColor(latestLog.thresholdStatus).withOpacity(0.2),
                      side: BorderSide(color: _getStatusColor(latestLog.thresholdStatus)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Last updated: ${latestLog.timestamp.toLocal().toString().split('.')[0]}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 24),
        
        // 2. Next Reminders Card
        const Text('Upcoming Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        StreamBuilder<DeviceSettings?>(
          stream: _repo.getDeviceSettingsStream(_userId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            
            final settings = snapshot.data!;
            return Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.water_drop, color: Colors.blueAccent),
                    title: const Text('Next Water Intake'),
                    subtitle: Text(_getNextWaterTime(settings.waterIntakeTimes)),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.timer, color: Colors.orangeAccent),
                    title: const Text('Screen Time Interval'),
                    subtitle: Text('Reminds every ${(settings.screenTimeInterval / 60).round()} minutes'),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}