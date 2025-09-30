import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models.dart';
import 'palette.dart';

/// Provider for selected weather variables
final selectedVariablesProvider = StateProvider<Set<String>>((ref) {
  return {'Temperature'}; // Default to temperature
});

/// Provider for locations list
final locationsProvider = StateProvider<List<LocationItem>>((ref) {
  return []; // Start empty as requested
});

/// Provider for time range selection
final rangeProvider = StateProvider<DateTimeRange>((ref) {
  final now = DateTime.now();
  return DateTimeRange(
    start: now,
    end: now.add(const Duration(hours: 48)), // Default: now to +48h
  );
});

/// Provider for time series data, keyed by locationId-variable
final seriesProvider = StateProvider<Map<String, Series>>((ref) {
  return {}; // Start empty
});

/// Provider for forecast summary
final summaryProvider = StateProvider<ForecastSummary>((ref) {
  return const ForecastSummary(
    text: 'No forecast data available',
    rainProb: null,
  );
});

/// Provider for the current selected location (derived from locations)
final selectedLocationProvider = Provider<LocationItem?>((ref) {
  final locations = ref.watch(locationsProvider);
  return locations.isNotEmpty ? locations.first : null;
});

/// Provider for active locations only
final activeLocationsProvider = Provider<List<LocationItem>>((ref) {
  final locations = ref.watch(locationsProvider);
  return locations.where((loc) => loc.active).toList();
});

/// Provider for series keys (locationId-variable combinations)
final seriesKeysProvider = Provider<List<String>>((ref) {
  final series = ref.watch(seriesProvider);
  return series.keys.toList();
});

/// Provider for series grouped by location
final seriesByLocationProvider = Provider<Map<String, List<Series>>>((ref) {
  final series = ref.watch(seriesProvider);
  final Map<String, List<Series>> grouped = {};
  
  for (final entry in series.entries) {
    final key = entry.key;
    final seriesData = entry.value;
    
    // Extract location ID from key (assuming format: "locationId-variable")
    final parts = key.split('-');
    if (parts.length >= 2) {
      final locationId = parts[0];
      grouped.putIfAbsent(locationId, () => []).add(seriesData);
    }
  }
  
  return grouped;
});

/// Provider for series grouped by variable
final seriesByVariableProvider = Provider<Map<String, List<Series>>>((ref) {
  final series = ref.watch(seriesProvider);
  final Map<String, List<Series>> grouped = {};
  
  for (final entry in series.entries) {
    final key = entry.key;
    final seriesData = entry.value;
    
    // Extract variable from key (assuming format: "locationId-variable")
    final parts = key.split('-');
    if (parts.length >= 2) {
      final variable = parts.sublist(1).join('-'); // Handle variables with hyphens
      grouped.putIfAbsent(variable, () => []).add(seriesData);
    }
  }
  
  return grouped;
});

/// Provider for all unique variables across all series
final availableVariablesProvider = Provider<Set<String>>((ref) {
  final series = ref.watch(seriesProvider);
  final variables = <String>{};
  
  for (final key in series.keys) {
    final parts = key.split('-');
    if (parts.length >= 2) {
      final variable = parts.sublist(1).join('-');
      variables.add(variable);
    }
  }
  
  return variables;
});

/// Provider for the next available color index
final nextColorIndexProvider = StateProvider<int>((ref) {
  return 0; // Start at 0, will increment as colors are assigned
});

/// Provider for getting the next color for a new series
final nextColorProvider = Provider<Color>((ref) {
  final index = ref.watch(nextColorIndexProvider);
  return Palette.getColor(index);
});

/// Provider for getting the next color value as integer
final nextColorValueProvider = Provider<int>((ref) {
  final index = ref.watch(nextColorIndexProvider);
  return Palette.getColorValue(index);
});

/// Provider for time range duration
final rangeDurationProvider = Provider<Duration>((ref) {
  final range = ref.watch(rangeProvider);
  return range.duration;
});

/// Provider for time range start as string
final rangeStartStringProvider = Provider<String>((ref) {
  final range = ref.watch(rangeProvider);
  return '${range.start.day}/${range.start.month} ${range.start.hour.toString().padLeft(2, '0')}:${range.start.minute.toString().padLeft(2, '0')}';
});

/// Provider for time range end as string
final rangeEndStringProvider = Provider<String>((ref) {
  final range = ref.watch(rangeProvider);
  return '${range.end.day}/${range.end.month} ${range.end.hour.toString().padLeft(2, '0')}:${range.end.minute.toString().padLeft(2, '0')}';
});

/// Provider for formatted time range string
final rangeStringProvider = Provider<String>((ref) {
  final start = ref.watch(rangeStartStringProvider);
  final end = ref.watch(rangeEndStringProvider);
  return '$start - $end';
});

/// Provider for checking if we have any data
final hasDataProvider = Provider<bool>((ref) {
  final series = ref.watch(seriesProvider);
  return series.isNotEmpty;
});

/// Provider for checking if we have any locations
final hasLocationsProvider = Provider<bool>((ref) {
  final locations = ref.watch(locationsProvider);
  return locations.isNotEmpty;
});

/// Provider for checking if we have any active locations
final hasActiveLocationsProvider = Provider<bool>((ref) {
  final activeLocations = ref.watch(activeLocationsProvider);
  return activeLocations.isNotEmpty;
});

/// Provider for the total number of data points across all series
final totalDataPointsProvider = Provider<int>((ref) {
  final series = ref.watch(seriesProvider);
  return series.values.fold(0, (sum, s) => sum + s.length);
});

/// Provider for the overall time range across all series
final overallTimeRangeProvider = Provider<DateTimeRange?>((ref) {
  final series = ref.watch(seriesProvider);
  if (series.isEmpty) return null;
  
  DateTime? earliest;
  DateTime? latest;
  
  for (final s in series.values) {
    final range = s.timeRange;
    if (range != null) {
      if (earliest == null || range.start.isBefore(earliest)) {
        earliest = range.start;
      }
      if (latest == null || range.end.isAfter(latest)) {
        latest = range.end;
      }
    }
  }
  
  if (earliest == null || latest == null) return null;
  return DateTimeRange(start: earliest, end: latest);
});

/// Provider for the overall value range across all series
final overallValueRangeProvider = Provider<({double min, double max})?>((ref) {
  final series = ref.watch(seriesProvider);
  if (series.isEmpty) return null;
  
  double? minValue;
  double? maxValue;
  
  for (final s in series.values) {
    final range = s.valueRange;
    if (range != null) {
      if (minValue == null || range.min < minValue) {
        minValue = range.min;
      }
      if (maxValue == null || range.max > maxValue) {
        maxValue = range.max;
      }
    }
  }
  
  if (minValue == null || maxValue == null) return null;
  return (min: minValue, max: maxValue);
});

/// Notifier for managing locations
class LocationsNotifier extends StateNotifier<List<LocationItem>> {
  LocationsNotifier() : super([]);

  /// Add a new location
  void addLocation(LocationItem location) {
    state = [...state, location];
  }

  /// Remove a location by name
  void removeLocation(String name) {
    state = state.where((loc) => loc.name != name).toList();
  }

  /// Update a location
  void updateLocation(String name, LocationItem updatedLocation) {
    state = state.map((loc) => loc.name == name ? updatedLocation : loc).toList();
  }

  /// Toggle active status of a location
  void toggleLocationActive(String name) {
    state = state.map((loc) {
      if (loc.name == name) {
        return loc.copyWith(active: !loc.active);
      }
      return loc;
    }).toList();
  }

  /// Clear all locations
  void clearLocations() {
    state = [];
  }

  /// Set all locations
  void setLocations(List<LocationItem> locations) {
    state = locations;
  }
}

/// Provider for locations notifier
final locationsNotifierProvider = StateNotifierProvider<LocationsNotifier, List<LocationItem>>((ref) {
  return LocationsNotifier();
});

/// Notifier for managing series data
class SeriesNotifier extends StateNotifier<Map<String, Series>> {
  SeriesNotifier() : super({});

  /// Add or update a series
  void setSeries(String key, Series series) {
    state = {...state, key: series};
  }

  /// Remove a series
  void removeSeries(String key) {
    final newState = Map<String, Series>.from(state);
    newState.remove(key);
    state = newState;
  }

  /// Clear all series
  void clearSeries() {
    state = {};
  }

  /// Update multiple series at once
  void setMultipleSeries(Map<String, Series> series) {
    state = {...state, ...series};
  }

  /// Remove all series for a specific location
  void removeSeriesForLocation(String locationId) {
    final newState = Map<String, Series>.from(state);
    newState.removeWhere((key, _) => key.startsWith('$locationId-'));
    state = newState;
  }

  /// Remove all series for a specific variable
  void removeSeriesForVariable(String variable) {
    final newState = Map<String, Series>.from(state);
    newState.removeWhere((key, _) => key.endsWith('-$variable'));
    state = newState;
  }
}

/// Provider for series notifier
final seriesNotifierProvider = StateNotifierProvider<SeriesNotifier, Map<String, Series>>((ref) {
  return SeriesNotifier();
});


