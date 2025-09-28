import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/models.dart';

class ChartProbability extends StatelessWidget {
  final List<TimePoint> precipitationValues;
  final String title;

  const ChartProbability({
    super.key,
    required this.precipitationValues,
    this.title = 'Probability Distribution',
  });

  @override
  Widget build(BuildContext context) {
    if (precipitationValues.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Text(
            'No precipitation data available',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
          ),
        ),
      );
    }

    final stats = _calculateStats();
    final bellCurve = _generateBellCurve(stats['mean']!, stats['stddev']!);

    return Column(
      children: [
        // Stats info row
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard(context, 'Mean', '${stats['mean']!.toStringAsFixed(1)}%'),
              _buildStatCard(context, 'Std Dev', '${stats['stddev']!.toStringAsFixed(1)}%'),
              _buildStatCard(context, 'Data Points', '${precipitationValues.length}'),
            ],
          ),
        ),

        // Bell curve chart with zoom + scroll
        Expanded(
          child: InteractiveViewer(
            minScale: 0.8,
            maxScale: 3.0,
            constrained: false,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 1.5, // wider canvas
                height: 300,
                child: RepaintBoundary(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          horizontalInterval: 0.1,
                          verticalInterval: 20,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Theme.of(context).dividerColor,
                            strokeWidth: 1,
                          ),
                          getDrawingVerticalLine: (value) => FlLine(
                            color: Theme.of(context).dividerColor.withOpacity(0.5),
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: 20,
                              getTitlesWidget: (value, meta) {
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Text(
                                    '${value.toInt()}%',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 0.1,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return SideTitleWidget(
                                  axisSide: meta.axisSide,
                                  child: Text(
                                    value.toStringAsFixed(1),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        minX: 0,
                        maxX: 100,
                        minY: 0,
                        maxY: 1.0,
                        lineBarsData: [
                          LineChartBarData(
                            spots: bellCurve,
                            isCurved: true,
                            color: Theme.of(context).colorScheme.primary,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                ],
                              ),
                            ),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          enabled: true,
                          touchTooltipData: LineTouchTooltipData(
                            tooltipRoundedRadius: 8,
                            tooltipPadding: const EdgeInsets.all(8),
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                return LineTooltipItem(
                                  'Probability: ${(spot.y * 100).toStringAsFixed(1)}%\n'
                                  'Value: ${spot.x.toStringAsFixed(1)}%',
                                  TextStyle(
                                    color: Theme.of(context).colorScheme.onInverseSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Map<String, double> _calculateStats() {
    final values = precipitationValues.map((p) => p.v).toList();
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    return {'mean': mean, 'stddev': sqrt(variance)};
  }

  List<FlSpot> _generateBellCurve(double mean, double stddev) {
    final List<FlSpot> spots = [];
    const step = 0.5;
    for (double x = 0; x <= 100; x += step) {
      final y = _normalDistribution(x, mean, stddev);
      spots.add(FlSpot(x, y));
    }
    return spots;
  }

  double _normalDistribution(double x, double mean, double stddev) {
    if (stddev == 0) return 0;
    final coefficient = 1 / (stddev * sqrt(2 * pi));
    final exponent = -0.5 * pow((x - mean) / stddev, 2);
    return coefficient * exp(exponent);
  }
}
