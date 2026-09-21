import 'package:flutter/material.dart';

class WaterScreen extends StatelessWidget {
  const WaterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> waterAlertLogs = [
      {'alert': 'DRINK WATER', 'quote': 'Drink some water', 'time': 'Interval Cycle: 21s'},
      {'alert': 'DRINK WATER', 'quote': 'Stay hydrated', 'time': 'Saved Telemetry'},
      {'alert': 'DRINK WATER', 'quote': 'Refill bottle', 'time': 'Saved Telemetry'},
      {'alert': 'DRINK WATER', 'quote': 'Adjust chair', 'time': 'Photo: 8:17:46 PM'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Drink Water Telemetry', style: TextStyle(color: Colors.black87)),
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
                  Icon(Icons.water_drop, size: 64, color: Color(0xFF039BE5)),
                  SizedBox(height: 12),
                  Text(
                    '21 Seconds Cycle',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Blue LED (GPIO 27) + Triple Beep on D26',
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Alert Occurrences & Paired Quotes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 10),
          ...waterAlertLogs.map(
            (log) => Card(
              color: Colors.white,
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE1F5FE),
                  child: Icon(Icons.water, color: Color(0xFF039BE5)),
                ),
                title: Text(log['alert']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('LCD Line 3: "${log['quote']}"\n${log['time']}'),
                trailing: const Icon(Icons.volume_up, color: Color(0xFF039BE5)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}