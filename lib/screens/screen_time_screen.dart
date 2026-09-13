import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_repository.dart';
import '../models/screen_time_reminder.dart';

class ScreenTimeScreen extends StatelessWidget {
  const ScreenTimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<List<ScreenTimeReminder>>(
      stream: FirestoreRepository.instance.getScreenTimeRemindersStream(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final logs = snapshot.data!;
        if (logs.isEmpty) return const Center(child: Text("No screen time reminders yet."));

        return ListView.builder(
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.timer, color: Colors.orangeAccent),
                title: Text('Reminder #${log.reminderNumber} Triggered'),
                subtitle: Text(log.triggeredAt.toLocal().toString().split('.')[0]),
                trailing: log.userAcknowledged 
                  ? const Icon(Icons.visibility_off, color: Colors.green)
                  : const Icon(Icons.warning_amber, color: Colors.orange),
              ),
            );
          },
        );
      },
    );
  }
}