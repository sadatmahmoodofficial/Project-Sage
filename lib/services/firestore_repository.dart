import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/device_settings.dart';
import '../models/air_quality_log.dart';
import '../models/water_intake_log.dart';
import '../models/screen_time_reminder.dart';

class FirestoreRepository {
  FirestoreRepository._privateConstructor();
  static final FirestoreRepository instance = FirestoreRepository._privateConstructor();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _settingsDoc(String userId) {
    return _db.collection('users').doc(userId).collection('device_settings').doc('config');
  }

  CollectionReference<Map<String, dynamic>> _airQualityCol(String userId) {
    return _db.collection('users').doc(userId).collection('air_quality_logs');
  }

  CollectionReference<Map<String, dynamic>> _waterIntakeCol(String userId) {
    return _db.collection('users').doc(userId).collection('water_intake_logs');
  }

  CollectionReference<Map<String, dynamic>> _screenTimeCol(String userId) {
    return _db.collection('users').doc(userId).collection('screen_time_reminders');
  }

  // Real-time Settings Stream
  Stream<DeviceSettings?> getDeviceSettingsStream(String userId) {
    return _settingsDoc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return DeviceSettings.fromJson(snapshot.data()!);
    });
  }

  // Real-time Air Quality Logs (sorted newest first)
  Stream<List<AirQualityLog>> getAirQualityLogsStream(String userId, {int limit = 50}) {
    return _airQualityCol(userId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => AirQualityLog.fromFirestore(doc)).toList());
  }

  // Real-time Water Intake Logs
  Stream<List<WaterIntakeLog>> getWaterIntakeLogsStream(String userId, {int limit = 50}) {
    return _waterIntakeCol(userId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => WaterIntakeLog.fromFirestore(doc)).toList());
  }

  // Real-time Screen Time Reminders
  Stream<List<ScreenTimeReminder>> getScreenTimeRemindersStream(String userId, {int limit = 50}) {
    return _screenTimeCol(userId)
        .orderBy('triggered_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ScreenTimeReminder.fromFirestore(doc)).toList());
  }

  // Write Defaults if document does not exist
  Future<void> initializeDefaultSettings(String userId) async {
    final doc = await _settingsDoc(userId).get();
    if (!doc.exists) {
      final defaultSettings = DeviceSettings(
        waterIntakeTimes: ['08:00', '12:00', '17:00'],
        screenTimeInterval: 2400,
        airQualityThresholds: {
          'good_max_ppm': 400,
          'bad_max_ppm': 1000,
          'worst_max_ppm': 2000,
        },
        buzzerEnabled: true,
      );
      await _settingsDoc(userId).set(defaultSettings.toJson());
    }
  }

  // Settings Updates
  Future<void> updateWaterIntakeTimes(String userId, List<String> times) async {
    await _settingsDoc(userId).set({
      'water_intake_times': times,
      'last_synced': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateScreenTimeInterval(String userId, int intervalSeconds) async {
    await _settingsDoc(userId).set({
      'screen_time_interval': intervalSeconds,
      'last_synced': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateAirQualityThresholds(
    String userId, {
    required int goodMax,
    required int badMax,
    required int worstMax,
  }) async {
    await _settingsDoc(userId).set({
      'air_quality_thresholds': {
        'good_max_ppm': goodMax,
        'bad_max_ppm': badMax,
        'worst_max_ppm': worstMax,
      },
      'last_synced': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> toggleBuzzer(String userId, bool enabled) async {
    await _settingsDoc(userId).set({
      'buzzer_enabled': enabled,
      'last_synced': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}