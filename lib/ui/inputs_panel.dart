import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/state.dart';
import '../core/models.dart';
import '../core/palette.dart';
import '../core/geocoding.dart';

// ---------- local UI providers ----------
final searchQueryProvider = StateProvider<String>((ref) => '');
final isLoadingGeocodingProvider = StateProvider<bool>((ref) => false);
final isLoadingProvider = StateProvider<bool>((ref) => false);
final nextColorIndexProvider = StateProvider<int>((ref) => 0);

// Selected time (optional)
final timeOfDayProvider = StateProvider<TimeOfDay?>((ref) => null);

class InputsPanel extends ConsumerStatefulWidget {
  const InputsPanel({super.key});

  @override
  ConsumerState<InputsPanel> createState() => _InputsPanelState();
}

class _InputsPanelState extends ConsumerState<InputsPanel> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    final range = ref.watch(rangeProvider);
    final selectedVariables = ref.watch(selectedVariablesProvider);
    final locations = ref.watch(locationsNotifierProvider);
    final isLoadingGeocoding = ref.watch(isLoadingGeocodingProvider);
    final isLoading = ref.watch(isLoadingProvider);
    final selectedTime = ref.watch(timeOfDayProvider);

    // ✅ Wrap parameters in collapsible card
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ExpansionTile(
                initiallyExpanded: true,
                title: const Text(
                  'Forecasting Parameters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB),
                  ),
                ),
                childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  _buildLocationSearch(context, ref, searchQuery, isLoadingGeocoding),
                  const SizedBox(height: 16),
                  if (locations.isNotEmpty) ...[
                    _buildLocationChips(context, ref, locations),
                    const SizedBox(height: 24),
                  ],
                  _buildDateTimePicker(context, ref, range, selectedTime),
                  const SizedBox(height: 24),
                  _buildVariableSelector(context, ref, selectedVariables),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildForecastButton(context, ref, isLoading),
          ],
        ),
      ),
    );
  }

  // ---------------------- UI Builders ----------------------

  Widget _buildLocationSearch(
    BuildContext context,
    WidgetRef ref,
    String searchQuery,
    bool isLoadingGeocoding,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Add Location',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search for a city or location...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF2563EB)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).state = value;
                  _debounceSearch(ref, value);
                },
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty && !isLoadingGeocoding) {
                    _addLocation(ref, value.trim());
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: searchQuery.trim().isEmpty || isLoadingGeocoding
                  ? null
                  : () => _addLocation(ref, searchQuery.trim()),
              icon: isLoadingGeocoding
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.add, size: 18),
              label: const Text('Add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationChips(BuildContext context, WidgetRef ref, List<LocationItem> locations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selected Locations',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: locations.map((location) => _buildLocationChip(context, ref, location)).toList(),
        ),
      ],
    );
  }

  Widget _buildLocationChip(BuildContext context, WidgetRef ref, LocationItem location) {
    return Container(
      decoration: BoxDecoration(
        color: location.active ? Color(location.colorValue).withOpacity(0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: location.active ? Color(location.colorValue) : Colors.grey.shade300,
          width: location.active ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _toggleLocationActive(ref, location),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: Color(location.colorValue), shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                location.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: location.active ? FontWeight.w600 : FontWeight.normal,
                  color: location.active ? Color(location.colorValue) : Colors.grey.shade700,
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  Icons.close,
                  size: 16,
                  color: location.active ? Color(location.colorValue) : Colors.grey.shade500,
                ),
                onPressed: () => _removeLocation(ref, location),
                tooltip: 'Remove',
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Date range + Time row (presets removed)
  Widget _buildDateTimePicker(
    BuildContext context,
    WidgetRef ref,
    DateTimeRange range,
    TimeOfDay? selectedTime,
  ) {
    final dateLabel =
        '${DateFormat('MMM dd, yyyy').format(range.start)} - ${DateFormat('MMM dd, yyyy').format(range.end)}';
    final timeLabel = selectedTime == null
        ? 'Pick time'
        : DateFormat('h:mm a').format(
            DateTime(0, 1, 1, selectedTime.hour, selectedTime.minute),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date & Time',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _showDateRangePicker(context, ref, range),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.date_range, color: Color(0xFF2563EB), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          dateLabel,
                          style: const TextStyle(fontSize: 16, color: Color(0xFF374151)),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6B7280)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.schedule_outlined),
                label: Text(timeLabel, overflow: TextOverflow.ellipsis),
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: selectedTime ?? TimeOfDay.now(),
                  );
                  if (picked != null) {
                    ref.read(timeOfDayProvider.notifier).state = picked;
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVariableSelector(BuildContext context, WidgetRef ref, Set<String> selectedVariables) {
    const variables = [
      'Temperature',
      'PrecipitationProb',
      'WindSpeed',
      'AirQualityIndex',
      'Dust',
      'CloudCover',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Weather Variables',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: variables.map((String variable) {
              final isSelected = selectedVariables.contains(variable);
              return CheckboxListTile(
                title: Text(
                  variable,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
                ),
                value: isSelected,
                onChanged: (bool? value) {
                  final newSet = Set<String>.from(selectedVariables);
                  if (value == true) {
                    newSet.add(variable);
                  } else {
                    newSet.remove(variable);
                  }
                  ref.read(selectedVariablesProvider.notifier).state = newSet;
                },
                activeColor: const Color(0xFF2563EB),
                contentPadding: EdgeInsets.zero,
                dense: true,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildForecastButton(BuildContext context, WidgetRef ref, bool isLoading) {
    final locations = ref.watch(locationsNotifierProvider);
    final selectedVariables = ref.watch(selectedVariablesProvider);
    final hasActiveLocations = locations.any((loc) => loc.active);
    final hasSelectedVariables = selectedVariables.isNotEmpty;
    final enabled = hasActiveLocations && hasSelectedVariables && !isLoading;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? () => _getForecast(ref) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF2563EB).withOpacity(0.35),
          disabledForegroundColor: Colors.white.withOpacity(0.85),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Get Forecast Insights',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  // ---------------------- Logic helpers ----------------------
  void _debounceSearch(WidgetRef ref, String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {});
  }

  Future<void> _addLocation(WidgetRef ref, String query) async {
    ref.read(isLoadingGeocodingProvider.notifier).state = true;
    try {
      final result = await GeocodingService.geocode(query);
      if (result != null) {
        final (name, lat, lon) = result;
        final colorIndex = ref.read(nextColorIndexProvider);
        final color = Palette.getColorValue(colorIndex);

        final location = LocationItem(
          name: name,
          lat: lat,
          lng: lon,
          active: true,
          colorValue: color,
        );

        ref.read(locationsNotifierProvider.notifier).addLocation(location);
        ref.read(nextColorIndexProvider.notifier).state = (colorIndex + 1) % 6;
        _searchController.clear();
        ref.read(searchQueryProvider.notifier).state = '';
      }
    } finally {
      ref.read(isLoadingGeocodingProvider.notifier).state = false;
    }
  }

  void _removeLocation(WidgetRef ref, LocationItem location) {
    ref.read(locationsNotifierProvider.notifier).removeLocation(location.name);
  }

  void _toggleLocationActive(WidgetRef ref, LocationItem location) {
    ref.read(locationsNotifierProvider.notifier).toggleLocationActive(location.name);
  }

  Future<void> _showDateRangePicker(
    BuildContext context,
    WidgetRef ref,
    DateTimeRange currentRange,
  ) async {
    final newRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: currentRange,
      helpText: 'Select date range',
      saveText: 'Apply',
    );
    if (newRange != null) {
      ref.read(rangeProvider.notifier).state = newRange;
    }
  }

  Future<void> _getForecast(WidgetRef ref) async {
    final locations = ref.read(locationsNotifierProvider);
    final selectedVariables = ref.read(selectedVariablesProvider);
    final hasActiveLocations = locations.any((loc) => loc.active);
    final hasSelectedVariables = selectedVariables.isNotEmpty;

    if (!hasActiveLocations || !hasSelectedVariables) return;

    ref.read(isLoadingProvider.notifier).state = true;

    try {
      final range = ref.read(rangeProvider);
      final activeLocations = locations.where((loc) => loc.active).toList();
      final selectedTime = ref.read(timeOfDayProvider);

      for (final location in activeLocations) {
        for (final variable in selectedVariables) {
          final seriesKey = '${location.name}-$variable';
          final series = _generateDummySeries(
            location.name,
            variable,
            range,
            location.colorValue,
          );
          ref.read(seriesNotifierProvider.notifier).setSeries(seriesKey, series);
        }
      }

      final city = activeLocations.isEmpty ? 'your location' : activeLocations.first.name;
      final dateStr = DateFormat('MMM d, yyyy').format(range.start);
      final timeStr = selectedTime == null
          ? ''
          : ' at ${DateFormat('h:mm a').format(DateTime(0, 1, 1, selectedTime.hour, selectedTime.minute))}';
      final text = '65% chance of rain on $dateStr$timeStr in $city';

      ref.read(summaryProvider.notifier).state = ForecastSummary(
        text: text,
        rainProb: selectedVariables.contains('PrecipitationProb') ? 0.65 : null,
      );
    } finally {
      ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  Series _generateDummySeries(
    String location,
    String variable,
    DateTimeRange range,
    int color,
  ) {
    final points = <TimePoint>[];
    final hours = max(1, range.duration.inHours);

    for (int i = 0; i <= hours; i++) {
      final time = range.start.add(Duration(hours: i));
      double value;
      switch (variable) {
        case 'Temperature':
          value = 50 + 40 * sin(2 * pi * i / 24);
          break;
        case 'PrecipitationProb':
          value = (50 + 40 * sin(2 * pi * i / 12)) + (i % 6 == 0 ? 10 : 0);
          break;
        case 'WindSpeed':
          value = 20 + 30 * sin(2 * pi * i / 18);
          break;
        case 'AirQualityIndex':
          value = 30 + 20 * sin(2 * pi * i / 48);
          break;
        case 'Dust':
          value = 15 + 25 * sin(2 * pi * i / 36);
          break;
        case 'CloudCover':
          value = 40 + 50 * sin(2 * pi * i / 24);
          break;
        default:
          value = 30 + 20 * sin(2 * pi * i / 24);
      }
      points.add(TimePoint(t: time, v: value.clamp(0, 100).toDouble()));
    }

    return Series(
      id: '$location-$variable',
      label: '$variable ($location)',
      color: color,
      points: points,
    );
  }
}
