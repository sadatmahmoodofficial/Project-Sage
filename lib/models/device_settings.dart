import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceSettings {
  final List<String> waterIntakeTimes;
  final int screenTimeInterval;
  final Map<String, int> airQualityThresholds;
  final bool buzzerEnabled;
  final DateTime? lastSynced;

  const DeviceSettings({
    required this.waterIntakeTimes,
    required this.screenTimeInterval,
    required this.airQualityThresholds,
    required this.buzzerEnabled,
    this.lastSynced,
  });

  factory DeviceSettings.fromJson(Map<String, dynamic> json) {
    DateTime? parseSynced(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final rawThresholds = json['air_quality_thresholds'] as Map<String, dynamic>? ?? {};

    return DeviceSettings(
      waterIntakeTimes: List<String>.from(json['water_intake_times'] ?? ['08:00', '12:00', '17:00']),
      screenTimeInterval: json['screen_time_interval'] as int? ?? 2400,
      airQualityThresholds: {
        'good_max_ppm': rawThresholds['good_max_ppm'] as int? ?? 400,
        'bad_max_ppm': rawThresholds['bad_max_ppm'] as int? ?? 1000,
        'worst_max_ppm': rawThresholds['worst_max_ppm'] as int? ?? 2000,
      },
      buzzerEnabled: json['buzzer_enabled'] as bool? ?? true,
      lastSynced: parseSynced(json['last_synced']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'water_intake_times': waterIntakeTimes,
      'screen_time_interval': screenTimeInterval,
      'air_quality_thresholds': airQualityThresholds,
      'buzzer_enabled': buzzerEnabled,
      'last_synced': FieldValue.serverTimestamp(),
    };
  }

  DeviceSettings copyWith({
    List<String>? waterIntakeTimes,
    int? screenTimeInterval,
    Map<String, int>? airQualityThresholds,
    bool? buzzerEnabled,
    DateTime? lastSynced,
  }) {
    return DeviceSettings(
      waterIntakeTimes: waterIntakeTimes ?? this.waterIntakeTimes,
      screenTimeInterval: screenTimeInterval ?? this.screenTimeInterval,
      airQualityThresholds: airQualityThresholds ?? this.airQualityThresholds,
      buzzerEnabled: buzzerEnabled ?? this.buzzerEnabled,
      lastSynced: lastSynced ?? this.lastSynced,
    );
  }
}