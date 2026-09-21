import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_repository.dart';
import '../models/device_settings.dart';
import 'control_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _userId = FirebaseAuth.instance.currentUser!.uid;
  final _repo = FirestoreRepository.instance;

  final _normalController = TextEditingController();
  final _moderateController = TextEditingController();

  @override
  void dispose() {
    _normalController.dispose();
    _moderateController.dispose();
    super.dispose();
  }

  void _syncThresholds() {
    final normalLimit = int.tryParse(_normalController.text) ?? 600;
    final moderateLimit = int.tryParse(_moderateController.text) ?? 1000;

    _repo.updateAirQualityThresholds(
      _userId,
      goodMax: normalLimit,
      badMax: moderateLimit,
      worstMax: 2000,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Threshold ranges synced successfully')),
    );
  }

  Future<void> _syncWaterTimesToControl(List<String> times) async {
    await FirebaseFirestore.instance
        .collection('control')
        .doc('device')
        .set({'water_intake_times': times}, SetOptions(merge: true));
  }

  Future<void> _addWaterTime(List<String> currentTimes) async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (time != null) {
      final formattedTime =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      if (!currentTimes.contains(formattedTime)) {
        final newTimes = List<String>.from(currentTimes)
          ..add(formattedTime)
          ..sort();
        await _repo.updateWaterIntakeTimes(_userId, newTimes);
        await _syncWaterTimesToControl(newTimes);
      }
    }
  }

  void _removeWaterTime(List<String> currentTimes, String timeToRemove) async {
    final newTimes = List<String>.from(currentTimes)..remove(timeToRemove);
    await _repo.updateWaterIntakeTimes(_userId, newTimes);
    await _syncWaterTimesToControl(newTimes);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DeviceSettings?>(
      stream: _repo.getDeviceSettingsStream(_userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final DeviceSettings settings = snapshot.data ??
            DeviceSettings(
              waterIntakeTimes: ['08:00', '12:00', '17:00'],
              screenTimeInterval: 120, // 2 minutes default
              airQualityThresholds: {
                'good_max_ppm': 600,
                'bad_max_ppm': 1000,
                'worst_max_ppm': 2000,
              },
              buzzerEnabled: true,
              lastSynced: null,
            );

        if (_normalController.text.isEmpty) {
          _normalController.text =
              settings.airQualityThresholds['good_max_ppm']?.toString() ?? '600';
          _moderateController.text =
              settings.airQualityThresholds['bad_max_ppm']?.toString() ?? '1000';
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Device Status Card
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.wifi,
                  color: settings.lastSynced != null ? Colors.tealAccent : Colors.grey,
                ),
                title: Text(
                  settings.lastSynced != null
                      ? 'Device Status: Connected'
                      : 'Device Status: Waiting for Device',
                ),
                subtitle: Text(
                  'Last Synced: ${settings.lastSynced?.toLocal().toString().split('.')[0] ?? 'Never'}',
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Manual Hardware Control Navigation Card
            Card(
              child: ListTile(
                leading: const Icon(Icons.tune, color: Colors.tealAccent),
                title: const Text(
                  'Manual Hardware Control',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Toggle LEDs and screen tracking'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ControlScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Screen Time Interval Slider (2 min to 60 min, step: 2 min)
            const Text(
              'Screen Time Interval',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Slider(
              value: (settings.screenTimeInterval / 60).clamp(2, 60).toDouble(),
              min: 2,
              max: 60,
              divisions: 29, // 2-minute steps: (60 - 2) / 2
              label: '${(settings.screenTimeInterval / 60).round()} mins',
              activeColor: Colors.tealAccent,
              onChanged: (val) {
                final int roundedMinutes = ((val / 2).round()) * 2;
                final int totalSeconds = roundedMinutes * 60;

                _repo.updateScreenTimeInterval(_userId, totalSeconds);

                // Sync directly to control/device for immediate ESP32 pickup
                FirebaseFirestore.instance
                    .collection('control')
                    .doc('device')
                    .set({'screen_interval_sec': totalSeconds}, SetOptions(merge: true));
              },
            ),
            const Divider(),

            // Water Intake Times Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Water Intake Times',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.tealAccent),
                  onPressed: () => _addWaterTime(settings.waterIntakeTimes),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: settings.waterIntakeTimes
                  .map(
                    (time) => Chip(
                      label: Text(time),
                      onDeleted: () =>
                          _removeWaterTime(settings.waterIntakeTimes, time),
                    ),
                  )
                  .toList(),
            ),
            const Divider(),

            // Air Quality Threshold Ranges
            const Text(
              'Air Quality Threshold Ranges (PPM)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _normalController,
                    decoration: const InputDecoration(
                      labelText: 'Normal Max',
                      helperText: '1 - 600 PPM (Safe)',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _moderateController,
                    decoration: const InputDecoration(
                      labelText: 'Moderate Max',
                      helperText: '601 - 1000 PPM (Warning)',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Hazardous: Any level above ${_moderateController.text.isEmpty ? "1000" : _moderateController.text} PPM',
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _syncThresholds,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sync Threshold Ranges'),
            ),
            const Divider(),

            // Data Retention
            const ListTile(
              title: Text('Data Retention'),
              subtitle: Text('Cloud logs auto-delete after 30 days'),
              trailing: Icon(Icons.info_outline, color: Colors.grey),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        );
      },
    );
  }
}