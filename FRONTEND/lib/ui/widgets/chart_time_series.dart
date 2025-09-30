import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models.dart';

class ChartTimeSeries extends ConsumerWidget {
  const ChartTimeSeries({super.key, required this.series});

  final List<Series> series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (series.isEmpty) {
      return const Center(child: Text('No data to display'));
    }

    // Prepare data for the chart
    final lineBarsData = series.map((s) {
      final spots = s.points.map((p) => FlSpot(p.t.millisecondsSinceEpoch.toDouble(), p.v)).toList();
      return LineChartBarData(
        spots: spots,
        isCurved: true,
        color: Color(s.color),
        barWidth: 2,
        belowBarData: BarAreaData(show: false),
        dotData: FlDotData(show: false),
      );
    }).toList();

    // Determine the min and max x for the chart
    final allPoints = series.expand((s) => s.points).toList();
    final minX = allPoints.map((p) => p.t.millisecondsSinceEpoch.toDouble()).reduce((a, b) => a < b ? a : b);
    final maxX = allPoints.map((p) => p.t.millisecondsSinceEpoch.toDouble()).reduce((a, b) => a > b ? a : b);
    final minY = 0.0;
    final maxY = 100.0; // Assuming values are 0-100

    return Column(
      children: [
        Expanded(
          child: LineChart(
            LineChartData(
              lineBarsData: lineBarsData,
              minX: minX,
              maxX: maxX,
              minY: minY,
              maxY: maxY,
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          DateFormat('MMM dd').format(date),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                    interval: (maxX - minX) / 5, // Show 5 labels
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                    interval: 20,
                  ),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(show: true),
              borderData: FlBorderData(show: true),
            ),
          ),
        ),
        // Legend
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Wrap(
            spacing: 16,
            children: series.map((s) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  color: Color(s.color),
                ),
                const SizedBox(width: 4),
                Text(s.label, style: const TextStyle(fontSize: 12)),
              ],
            )).toList(),
          ),
        ),
      ],
    );
  }
}
