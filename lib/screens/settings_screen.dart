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
  final _userId = FirebaseAuth.instance.currentUser?.uid ?? 'X4uGv2M9CCRMvYQNlN4iLmSnH662';
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
    final normalLimit = int.tryParse(_normalController.text) ?? 450;
    final moderateLimit = int.tryParse(_moderateController.text) ?? 700;

    _repo.updateAirQualityThresholds(
      _userId,
      goodMax: normalLimit,
      badMax: moderateLimit,
      worstMax: 2000,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Threshold ranges synced successfully'),
        backgroundColor: Color(0xFF00897B),
      ),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: StreamBuilder<DeviceSettings?>(
        stream: _repo.getDeviceSettingsStream(_userId),
        builder: (context, snapshot) {
          final DeviceSettings settings = snapshot.data ??
              DeviceSettings(
                waterIntakeTimes: ['16:22'],
                screenTimeInterval: 120,
                airQualityThresholds: {
                  'good_max_ppm': 450,
                  'bad_max_ppm': 700,
                  'worst_max_ppm': 2000,
                },
                buzzerEnabled: true,
                lastSynced: DateTime.parse('2026-09-21 19:56:46'),
              );

          if (_normalController.text.isEmpty) {
            _normalController.text =
                settings.airQualityThresholds['good_max_ppm']?.toString() ?? '450';
            _moderateController.text =
                settings.airQualityThresholds['bad_max_ppm']?.toString() ?? '700';
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // 1. Device Connection Status Card
              Card(
                color: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE0F2F1),
                    child: Icon(Icons.wifi, color: Color(0xFF00897B)),
                  ),
                  title: const Text(
                    'Device Status: Connected',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  subtitle: Text(
                    'Last Synced: ${settings.lastSynced != null ? settings.lastSynced.toString().split('.')[0] : "2026-09-21 19:56:46"}',
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 2. Manual Hardware Control Navigation Card
              Card(
                color: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEDE7F6),
                    child: Icon(Icons.tune, color: Color(0xFF5E35B1)),
                  ),
                  title: const Text(
                    'Manual Hardware Control',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  subtitle: const Text(
                    'Toggle LEDs and screen tracking',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ControlScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // 3. Screen Time & Water Intake Configuration Card
              Card(
                color: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Screen Time Slider
                      const Text(
                        'Screen Time Interval',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFF00897B),
                          inactiveTrackColor: Colors.grey.shade300,
                          thumbColor: const Color(0xFF00897B),
                          overlayColor: const Color(0x2900897B),
                        ),
                        child: Slider(
                          value: (settings.screenTimeInterval / 60).clamp(2, 60).toDouble(),
                          min: 2,
                          max: 60,
                          divisions: 29,
                          label: '${(settings.screenTimeInterval / 60).round()} mins',
                          onChanged: (val) {
                            final int roundedMinutes = ((val / 2).round()) * 2;
                            final int totalSeconds = roundedMinutes * 60;

                            _repo.updateScreenTimeInterval(_userId, totalSeconds);
                            FirebaseFirestore.instance
                                .collection('control')
                                .doc('device')
                                .set({'screen_interval_sec': totalSeconds}, SetOptions(merge: true));
                          },
                        ),
                      ),
                      const Divider(height: 24),

                      // Water Intake Times
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Water Intake Times',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Color(0xFF00897B), size: 28),
                            onPressed: () => _addWaterTime(settings.waterIntakeTimes),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: settings.waterIntakeTimes
                            .map(
                              (time) => Chip(
                                backgroundColor: const Color(0xFFE0F2F1),
                                label: Text(
                                  time,
                                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF004D40)),
                                ),
                                deleteIcon: const Icon(Icons.cancel, size: 18, color: Color(0xFF004D40)),
                                onDeleted: () => _removeWaterTime(settings.waterIntakeTimes, time),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 4. Air Quality Threshold Ranges Card
              Card(
                color: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Air Quality Threshold Ranges (PPM)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _normalController,
                              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                labelText: 'Normal Max',
                                helperText: '1 - 600 PPM (Safe)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextField(
                              controller: _moderateController,
                              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                labelText: 'Moderate Max',
                                helperText: '601 - 1000 PPM (Warning)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Hazardous: Any level above ${_moderateController.text.isEmpty ? "700" : _moderateController.text} PPM',
                        style: const TextStyle(
                          color: Color(0xFFE53935),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: _syncThresholds,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00897B),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text(
                          'Sync Threshold Ranges',
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 5. Data Retention Card
              Card(
                color: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: const ListTile(
                  leading: Icon(Icons.info_outline, color: Colors.black54),
                  title: Text(
                    'Data Retention',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  subtitle: Text(
                    'Cloud logs auto-delete after 30 days',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}