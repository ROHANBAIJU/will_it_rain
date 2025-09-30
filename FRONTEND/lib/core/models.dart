import 'package:flutter/material.dart';

class TimePoint {
  final DateTime t;
  final double v;

  TimePoint({
    required this.t,
    required this.v,
  });

  @override
  String toString() => 'TimePoint(t: $t, v: $v)';
}

class Series {
  final String id;
  final String label;
  final int color;
  final List<TimePoint> points;

  Series({
    required this.id,
    required this.label,
    required this.color,
    required this.points,
  });

  @override
  String toString() => 'Series(id: $id, label: $label, color: $color, points: ${points.length})';

  // Helper methods for state management
  int get length => points.length;

  DateTimeRange? get timeRange {
    if (points.isEmpty) return null;
    return DateTimeRange(start: points.first.t, end: points.last.t);
  }

  ({double min, double max})? get valueRange {
    if (points.isEmpty) return null;
    final values = points.map((p) => p.v).toList();
    return (min: values.reduce((a, b) => a < b ? a : b), max: values.reduce((a, b) => a > b ? a : b));
  }
}

class LocationItem {
  final String name;
  final double lat;
  final double lng;
  final bool active;
  final int colorValue;

  const LocationItem({
    required this.name,
    required this.lat,
    required this.lng,
    this.active = true,
    required this.colorValue,
  });

  LocationItem copyWith({
    String? name,
    double? lat,
    double? lng,
    bool? active,
    int? colorValue,
  }) {
    return LocationItem(
      name: name ?? this.name,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      active: active ?? this.active,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  @override
  String toString() => 'LocationItem(name: $name, lat: $lat, lng: $lng, active: $active)';
}

class ForecastSummary {
  final String text;
  final double? rainProb;

  const ForecastSummary({
    required this.text,
    this.rainProb,
  });

  bool get hasRainProb => rainProb != null;

  String? get rainProbText {
    if (rainProb == null) return null;
    return '${(rainProb! * 100).toInt()}% chance of rain';
  }

  @override
  String toString() => 'ForecastSummary(text: $text, rainProb: $rainProb)';
}