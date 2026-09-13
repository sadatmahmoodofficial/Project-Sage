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
  
  final _goodController = TextEditingController();
  final _badController = TextEditingController();
  final _worstController = TextEditingController();

  @override
  void dispose() {
    _goodController.dispose();
    _badController.dispose();
    _worstController.dispose();
    super.dispose();
  }

  void _syncThresholds() {
    _repo.updateAirQualityThresholds(
      _userId,
      goodMax: int.tryParse(_goodController.text) ?? 400,
      badMax: int.tryParse(_badController.text) ?? 1000,
      worstMax: int.tryParse(_worstController.text) ?? 2000,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thresholds Synced to Device')),
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
      final formattedTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      if (!currentTimes.contains(formattedTime)) {
        final newTimes = List<String>.from(currentTimes)..add(formattedTime)..sort();
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
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final settings = snapshot.data!;
        
        if (_goodController.text.isEmpty) {
          _goodController.text = settings.airQualityThresholds['good_max_ppm'].toString();
          _badController.text = settings.airQualityThresholds['bad_max_ppm'].toString();
          _worstController.text = settings.airQualityThresholds['worst_max_ppm'].toString();
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.wifi, color: Colors.tealAccent),
                title: const Text('Device Status: Connected'),
                subtitle: Text('Last Synced: ${settings.lastSynced?.toLocal().toString().split('.')[0] ?? 'Never'}'),
              ),
            ),
            const SizedBox(height: 16),
            
            const Text('Screen Time Interval', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Slider(
              value: (settings.screenTimeInterval / 60).clamp(10, 120).toDouble(),
              min: 10,
              max: 120,
              divisions: 11,
              label: '${(settings.screenTimeInterval / 60).round()} mins',
              activeColor: Colors.tealAccent,
              onChanged: (val) => _repo.updateScreenTimeInterval(_userId, (val * 60).toInt()),
            ),
            const Divider(),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Water Intake Times', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.tealAccent),
                  onPressed: () => _addWaterTime(settings.waterIntakeTimes),
                )
              ],
            ),
            Wrap(
              spacing: 8,
              children: settings.waterIntakeTimes.map((time) => Chip(
                label: Text(time),
                onDeleted: () => _removeWaterTime(settings.waterIntakeTimes, time),
              )).toList(),
            ),
            const Divider(),

            const Text('Air Quality Thresholds (PPM)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextField(controller: _goodController, decoration: const InputDecoration(labelText: 'Good Max'), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _badController, decoration: const InputDecoration(labelText: 'Bad Max'), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _worstController, decoration: const InputDecoration(labelText: 'Worst Max'), keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _syncThresholds,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              child: const Text('Sync Thresholds'),
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