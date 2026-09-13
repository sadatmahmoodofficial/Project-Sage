import 'package:cloud_firestore/cloud_firestore.dart';

class ScreenTimeReminder {
  final String? id;
  final int reminderNumber;
  final DateTime triggeredAt;
  final bool userAcknowledged;

  const ScreenTimeReminder({
    this.id,
    required this.reminderNumber,
    required this.triggeredAt,
    required this.userAcknowledged,
  });

  factory ScreenTimeReminder.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return ScreenTimeReminder(
      id: doc.id,
      reminderNumber: data['reminder_number'] as int? ?? 1,
      triggeredAt: parseDate(data['triggered_at']),
      userAcknowledged: data['user_acknowledged'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reminder_number': reminderNumber,
      'triggered_at': Timestamp.fromDate(triggeredAt),
      'user_acknowledged': userAcknowledged,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}