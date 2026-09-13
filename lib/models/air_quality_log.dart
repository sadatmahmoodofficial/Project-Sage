import 'package:cloud_firestore/cloud_firestore.dart';

class AirQualityLog {
  final String? id;
  final DateTime timestamp;
  final int ppmValue;
  final String thresholdStatus;

  const AirQualityLog({
    this.id,
    required this.timestamp,
    required this.ppmValue,
    required this.thresholdStatus,
  });

  factory AirQualityLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return AirQualityLog(
      id: doc.id,
      timestamp: parseDate(data['timestamp']),
      ppmValue: data['ppm_value'] as int? ?? 0,
      thresholdStatus: data['threshold_status'] as String? ?? 'good',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': Timestamp.fromDate(timestamp),
      'ppm_value': ppmValue,
      'threshold_status': thresholdStatus,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}