import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/firestore_repository.dart';
import '../models/air_quality_log.dart';

class AirQualityScreen extends StatelessWidget {
  const AirQualityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<List<AirQualityLog>>(
      stream: FirestoreRepository.instance.getAirQualityLogsStream(userId, limit: 20),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final logs = snapshot.data!;
        if (logs.isEmpty) return const Center(child: Text("No air quality data yet."));

        // Reverse for chronological charting (oldest left, newest right)
        final chartLogs = logs.reversed.toList();
        final spots = chartLogs.asMap().entries.map((e) {
          return FlSpot(e.key.toDouble(), e.value.ppmValue.toDouble());
        }).toList();

        return Column(
          children: [
            Container(
              height: 250,
              padding: const EdgeInsets.all(16),
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Hide X axis for simplicity
                  ),
                  borderData: FlBorderData(show: true, border: Border.all(color: Colors.white24)),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.tealAccent,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: Colors.teal.withOpacity(0.2)),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return ListTile(
                    leading: Icon(
                      Icons.air,
                      color: log.thresholdStatus == 'good' ? Colors.green 
                           : log.thresholdStatus == 'bad' ? Colors.orange : Colors.red,
                    ),
                    title: Text('${log.ppmValue} PPM'),
                    subtitle: Text(log.timestamp.toLocal().toString().split('.')[0]),
                    trailing: Text(log.thresholdStatus.toUpperCase()),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}