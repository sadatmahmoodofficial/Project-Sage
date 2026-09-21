import 'package:flutter/material.dart';

class AirQualityScreen extends StatelessWidget {
  const AirQualityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Hardcoded logs from the device photos and video testing
    final List<Map<String, dynamic>> historicalLogs = [
      {'ppm': 259, 'status': 'GOOD', 'time': 'Live Monitor', 'led': 'Green'},
      {'ppm': 290, 'status': 'GOOD', 'time': 'Photo: 8:17:38 PM', 'led': 'Green'},
      {'ppm': 293, 'status': 'GOOD', 'time': 'Photo: 8:17:39 PM', 'led': 'Green'},
      {'ppm': 291, 'status': 'GOOD', 'time': 'Photo: 8:17:46 PM', 'led': 'Green'},
      {'ppm': 293, 'status': 'GOOD', 'time': 'Photo: 8:17:47 PM', 'led': 'Green'},
      {'ppm': 290, 'status': 'GOOD', 'time': 'Photo: 8:17:48 PM', 'led': 'Green'},
      {'ppm': 1000, 'status': 'WORST', 'time': 'Photo: 7:08:23 PM (Lighter/Gas test)', 'led': 'Red'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Air Quality Readings', style: TextStyle(color: Colors.black87)),
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
                  Icon(Icons.air, size: 64, color: Colors.green),
                  SizedBox(height: 12),
                  Text(
                    '259 PPM',
                    style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Current Status: GOOD',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Green LED (GPIO 33) ON | Range: 1 - 1400',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Saved Telemetry History',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 10),
          ...historicalLogs.map((log) {
            final bool isGood = log['status'] == 'GOOD';
            return Card(
              color: Colors.white,
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isGood ? Colors.green.shade100 : Colors.red.shade100,
                  child: Icon(
                    isGood ? Icons.check_circle : Icons.warning,
                    color: isGood ? Colors.green : Colors.red,
                  ),
                ),
                title: Text(
                  '${log['ppm']} PPM (${log['status']})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${log['time']} | LED: ${log['led']}'),
                trailing: Text(
                  isGood ? 'Healthy' : 'Danger',
                  style: TextStyle(
                    color: isGood ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}