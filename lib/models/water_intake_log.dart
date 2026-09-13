import 'package:cloud_firestore/cloud_firestore.dart';

class WaterIntakeLog {
  final String? id;
  final DateTime timestamp;
  final bool confirmed;

  const WaterIntakeLog({
    this.id,
    required this.timestamp,
    required this.confirmed,
  });

  factory WaterIntakeLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return WaterIntakeLog(
      id: doc.id,
      timestamp: parseDate(data['timestamp']),
      confirmed: data['confirmed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': Timestamp.fromDate(timestamp),
      'confirmed': confirmed,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}