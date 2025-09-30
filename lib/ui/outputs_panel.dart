import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets/chart_time_series.dart' hide Series, TimePoint;
import 'widgets/chart_probability.dart';
import 'widgets/heatmap_placeholder.dart';
import 'widgets/export_bar.dart';
import '../core/state.dart';
import '../core/models.dart' as core_models;

class OutputsPanel extends ConsumerStatefulWidget {
  const OutputsPanel({super.key});

  @override
  ConsumerState<OutputsPanel> createState() => _OutputsPanelState();
}

class _OutputsPanelState extends ConsumerState<OutputsPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      );

      _fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ));

      _slideAnimation = Tween<Offset>(
        begin: const Offset(0.3, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ));

      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(summaryProvider);
    final locations = ref.watch(locationsNotifierProvider);
    final seriesMap = ref.watch(seriesNotifierProvider);
    final allSeries = seriesMap.values.toList();

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Always allow vertical scroll when needed.
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              // Ensure the scroll view at least fills the viewport.
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(summary, locations),
                  const SizedBox(height: 24),
                  _buildTabbedCharts(
                    allSeries,
                    viewportHeight: constraints.maxHeight,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
    core_models.ForecastSummary summary,
    List<core_models.LocationItem> locations,
  ) {
    final locationName =
        locations.isNotEmpty ? locations.first.name : 'No location';
    final date = DateTime.now().toString().split(' ').first;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Forecast Summary',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              summary.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _iconText(Icons.location_on, locationName),
                _iconText(Icons.calendar_today, date),
                if (summary.hasRainProb &&
                    (summary.rainProbText ?? '').isNotEmpty)
                  _iconText(Icons.water_drop, summary.rainProbText!),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconText(IconData icon, String text) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  /// Tab card. `viewportHeight` lets us choose a safe height for the view area.
Widget _buildTabbedCharts(List<core_models.Series> series,
    {required double viewportHeight}) {
  // Make the chart area height responsive but bounded so it never overflows.
  final contentHeight = viewportHeight.isFinite
      ? viewportHeight.clamp(360.0, 640.0)
      : 520.0; // fallback when unbounded

  final screenWidth = MediaQuery.of(context).size.width;
  final useShortLabels = screenWidth < 360; // shrink labels on tiny phones

  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        // Put TabBar in a horizontal scrollable container
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: TabBar(
            controller: _tabController,
            isScrollable: true, // <-- important
            labelPadding: const EdgeInsets.symmetric(horizontal: 16),
            labelColor: const Color(0xFF2563EB),
            unselectedLabelColor: const Color(0xFF6B7280),
            indicatorColor: const Color(0xFF2563EB),
            indicatorWeight: 3,
            tabs: [
              Tab(
                icon: const Icon(Icons.show_chart),
                text: useShortLabels ? 'Series' : 'Time Series',
              ),
              Tab(
                icon: const Icon(Icons.bar_chart),
                text: useShortLabels ? 'Prob' : 'Probability',
              ),
              const Tab(icon: Icon(Icons.grid_view), text: 'Heatmap'),
            ],
          ),
        ),
        // Fixed-height view area prevents vertical overflow in every device.
        SizedBox(
          height: contentHeight,
          child: TabBarView(
            controller: _tabController,
            children: [
              _timeSeriesTab(series),
              _probabilityTab(series),
              _heatmapTab(series),
            ],
          ),
        ),
      ],
    ),
  );
}


  // === Tabs: Expanded chart inside a bounded area + fixed ExportBar ===
  Widget _timeSeriesTab(List<core_models.Series> series) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ChartTimeSeries(series: series as dynamic),
          ),
        ),
        const ExportBar(),
      ],
    );
  }

  Widget _probabilityTab(List<core_models.Series> series) {
    final precipitationSeries = series
        .where((s) => s?.label.toLowerCase().contains('precipitation') ?? false)
        .toList();
    final precipitationPoints = precipitationSeries.isNotEmpty
        ? precipitationSeries.first.points as List<core_models.TimePoint>
        : <core_models.TimePoint>[];

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ChartProbability(precipitationValues: precipitationPoints),
          ),
        ),
        SizedBox(
          height: 48,
          child: const ExportBar(),
        ),
      ],
    );
  }

  Widget _heatmapTab(List<core_models.Series> series) {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: HeatmapPlaceholder(series: series),
          ),
        ),
        const ExportBar(),
      ],
    );
  }
}
