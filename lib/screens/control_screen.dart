import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  bool _isLoadingLed = false;
  bool _isLoadingScreen = false;

  Future<void> _updateControlField(String field, dynamic value) async {
    try {
      await FirebaseFirestore.instance
          .collection('control')
          .doc('device')
          .set({field: value}, SetOptions(merge: true));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating $field: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Hardware Control'),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('control')
            .doc('device')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent),
            );
          }

          final snapshotDoc = snapshot.data;
          final data = (snapshotDoc != null && snapshotDoc.exists)
              ? snapshotDoc.data()
              : null;

          final int ledStatus = (data != null && data.containsKey('led_status'))
              ? (data['led_status'] as num).toInt()
              : 0;
          final bool isLedOn = (ledStatus == 1);

          final bool isScreenTimeActive = (data != null && data.containsKey('screen_time_active'))
              ? (data['screen_time_active'] == true)
              : false;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Card 1: Remote LED Control
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb,
                        size: 48,
                        color: isLedOn ? Colors.tealAccent : Colors.grey,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Indicator LED',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              isLedOn ? 'Status: ON' : 'Status: OFF',
                              style: TextStyle(
                                color: isLedOn ? Colors.tealAccent : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _isLoadingLed
                          ? const CircularProgressIndicator(color: Colors.tealAccent)
                          : Switch.adaptive(
                              activeColor: Colors.tealAccent,
                              value: isLedOn,
                              onChanged: (val) async {
                                setState(() => _isLoadingLed = true);
                                await _updateControlField('led_status', val ? 1 : 0);
                                if (mounted) setState(() => _isLoadingLed = false);
                              },
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Card 2: Screen Time Tracker
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 48,
                        color: isScreenTimeActive ? Colors.tealAccent : Colors.grey,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Screen Time Tracker',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              isScreenTimeActive
                                  ? 'Active (Alerts via Buzzer)'
                                  : 'Inactive (Timer Paused)',
                              style: TextStyle(
                                color: isScreenTimeActive ? Colors.tealAccent : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _isLoadingScreen
                          ? const CircularProgressIndicator(color: Colors.tealAccent)
                          : Switch.adaptive(
                              activeColor: Colors.tealAccent,
                              value: isScreenTimeActive,
                              onChanged: (val) async {
                                setState(() => _isLoadingScreen = true);
                                await _updateControlField('screen_time_active', val);
                                if (mounted) setState(() => _isLoadingScreen = false);
                              },
                            ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}