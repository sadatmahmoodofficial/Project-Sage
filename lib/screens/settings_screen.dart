import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_repository.dart';
import '../models/device_settings.dart';

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
      const SnackBar(content: Text('Threshold ranges synced to device')),
    );
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
        _repo.updateWaterIntakeTimes(_userId, newTimes);
      }
    }
  }

  void _removeWaterTime(List<String> currentTimes, String timeToRemove) {
    final newTimes = List<String>.from(currentTimes)..remove(timeToRemove);
    _repo.updateWaterIntakeTimes(_userId, newTimes);
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
              screenTimeInterval: 1200,
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
            const SizedBox(height: 16),

            const Text(
              'Screen Time Interval',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Slider(
              value: (settings.screenTimeInterval / 60).clamp(10, 120).toDouble(),
              min: 10,
              max: 120,
              divisions: 11,
              label: '${(settings.screenTimeInterval / 60).round()} mins',
              activeColor: Colors.tealAccent,
              onChanged: (val) =>
                  _repo.updateScreenTimeInterval(_userId, (val * 60).toInt()),
            ),
            const Divider(),

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
              style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500),
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