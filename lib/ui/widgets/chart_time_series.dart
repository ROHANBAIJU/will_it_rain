import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/models.dart';

class ChartTimeSeries extends StatefulWidget {
  final List<Series> series;
  final String title;

  const ChartTimeSeries({
    super.key,
    required this.series,
    this.title = 'Time Series',
  });

  @override
  State<ChartTimeSeries> createState() => _ChartTimeSeriesState();
}

class _ChartTimeSeriesState extends State<ChartTimeSeries> {
  List<LineChartBarData>? _lineBars;

  @override
  void initState() {
    super.initState();
    _updateLineBars();
  }

  @override
  void didUpdateWidget(ChartTimeSeries oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.series != widget.series) {
      _updateLineBars();
    }
  }

  void _updateLineBars() {
    _lineBars = widget.series.map((s) {
      return LineChartBarData(
        spots: s.points
            .map((p) => FlSpot(
                  p.t.millisecondsSinceEpoch.toDouble(),
                  p.v,
                ))
            .toList(),
        isCurved: true,
        color: Color(s.color),
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        // fl_chart 0.69.x: BarAreaData is not const
        belowBarData: BarAreaData(show: false),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.series.isEmpty || _lineBars == null) {
      return const SizedBox(
        height: 300,
        child: Center(child: Text('No data available')),
      );
    }

    // FIX: dividerColor is non-nullable on your SDK, so no "??" fallback.
    final Color divider = Theme.of(context).dividerColor;

    final first = widget.series.first;
    final minX = first.points.first.t.millisecondsSinceEpoch.toDouble();
    final maxX = first.points.last.t.millisecondsSinceEpoch.toDouble();

    return Column(
      children: [
        if (widget.series.isNotEmpty)
          SizedBox(
            height: 36,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: widget.series.map((s) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Color(s.color),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          s.label,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

        Expanded(
          child: RepaintBoundary(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 20,
                    verticalInterval: 24 * 60 * 60 * 1000, // daily
                    getDrawingHorizontalLine: (value) =>
                        FlLine(color: divider, strokeWidth: 1),
                    getDrawingVerticalLine: (value) =>
                        FlLine(color: divider, strokeWidth: 1),
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
                        reservedSize: 24,
                        interval: 24 * 60 * 60 * 1000,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              DateFormat('MMM d').format(date),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        reservedSize: 34,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              value.toInt().toString(),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: divider),
                  ),
                  minX: minX,
                  maxX: maxX,
                  minY: 0,
                  maxY: 100,
                  lineBarsData: _lineBars!,
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.all(8),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map<LineTooltipItem?>((ts) {
                          final s = widget.series[ts.barIndex];
                          final p = s.points[ts.spotIndex];
                          return LineTooltipItem(
                            '${s.label}\n'
                            '${DateFormat('MMM d, HH:mm').format(p.t)}\n'
                            '${p.v.toStringAsFixed(1)}',
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
      ],
    );
  }
}
