import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_repository.dart';
import '../models/water_intake_log.dart';

class WaterLogScreen extends StatelessWidget {
  const WaterLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<List<WaterIntakeLog>>(
      stream: FirestoreRepository.instance.getWaterIntakeLogsStream(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final logs = snapshot.data!;
        if (logs.isEmpty) return const Center(child: Text("No water intake logs yet."));

        return ListView.builder(
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.water_drop, color: Colors.blueAccent),
                title: const Text('Intake Confirmed'),
                subtitle: Text(log.timestamp.toLocal().toString().split('.')[0]),
                trailing: const Icon(Icons.check_circle, color: Colors.green),
              ),
            );
          },
        );
      },
    );
  }
}