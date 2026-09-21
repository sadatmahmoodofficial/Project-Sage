import 'package:flutter/material.dart';

class ScreenTimeScreen extends StatelessWidget {
  const ScreenTimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> screenTimeLogs = [
      {'alert': 'LOOK AWAY', 'quote': 'Lower shoulders', 'time': 'Video Timestamp: 0:00'},
      {'alert': 'LOOK AWAY', 'quote': 'Take a break', 'time': 'Video Timestamp: 0:03'},
      {'alert': 'LOOK AWAY', 'quote': 'Walk a little', 'time': 'Photo: 8:17:39 PM'},
      {'alert': 'LOOK AWAY', 'quote': 'Blink your eyes', 'time': 'Photo: 8:17:46 PM'},
      {'alert': 'LOOK AWAY', 'quote': 'Relax shoulders', 'time': 'Photo: 8:17:47 PM'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Look Away Tracker', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            child: const Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(Icons.remove_red_eye, size: 64, color: Color(0xFFFB8C00)),
                  SizedBox(height: 12),
                  Text(
                    '15 Seconds Cycle',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Yellow LED (GPIO 32) + 400ms Long Tone on D26',
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Look Away Alerts & Paired Quotes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 10),
          ...screenTimeLogs.map(
            (log) => Card(
              color: Colors.white,
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFF3E0),
                  child: Icon(Icons.remove_red_eye_outlined, color: Color(0xFFFB8C00)),
                ),
                title: Text(log['alert']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('LCD Line 3: "${log['quote']}"\n${log['time']}'),
                trailing: const Icon(Icons.alarm_on, color: Color(0xFFFB8C00)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}