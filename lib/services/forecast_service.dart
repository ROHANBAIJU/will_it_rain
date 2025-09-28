import 'dart:math';
import '../core/models.dart';

class ForecastService {

  /// Generate deterministic dummy data for charts using sine wave + noise
  static List<TimePoint> generateSeries(
    String locationName,
    String variableKey,
    DateTime start,
    DateTime end,
  ) {
    final List<TimePoint> points = [];
    
    // Different baseline shifts for different variables
    final baselineShifts = {
      'precipitation': 20.0,  // Lower baseline
      'temperature': 50.0,    // Mid-range
      'windspeed': 15.0,      // Lower baseline
      'humidity': 60.0,       // Higher baseline
      'pressure': 45.0,       // Mid-range
    };

    final baseline = baselineShifts[variableKey.toLowerCase()] ?? 50.0;
    final seed = locationName.hashCode + variableKey.hashCode;
    final seededRandom = Random(seed);

    // Generate hourly points
    DateTime current = start;
    int hourIndex = 0;
    
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      // Create sine wave with period of 24 hours (daily cycle)
      final sineValue = sin((hourIndex * 2 * pi) / 24);
      
      // Add some weekly variation (7-day cycle)
      final weeklyVariation = sin((hourIndex * 2 * pi) / (24 * 7));
      
      // Combine sine waves and add noise
      final noise = (seededRandom.nextDouble() - 0.5) * 10; // ±5 noise
      double value = baseline + (sineValue * 25) + (weeklyVariation * 10) + noise;
      
      // Clamp between 0 and 100
      value = value.clamp(0.0, 100.0);
      
      points.add(TimePoint(t: current, v: value));
      
      current = current.add(const Duration(hours: 1));
      hourIndex++;
    }

    return points;
  }

  /// Generate multiple series for different variables at a location
  static List<Series> generateMultipleSeries(
    String locationName,
    List<String> variables,
    DateTime start,
    DateTime end,
  ) {
    final colors = [
      0xFF2196F3, // Blue
      0xFF4CAF50, // Green
      0xFFFF9800, // Orange
      0xFFE91E63, // Pink
      0xFF9C27B0, // Purple
      0xFF00BCD4, // Cyan
      0xFFFF5722, // Deep Orange
      0xFF795548, // Brown
    ];

    return variables.asMap().entries.map((entry) {
      final index = entry.key;
      final variable = entry.value;
      
      return Series(
        id: '${locationName}_$variable',
        label: '${_capitalizeFirst(locationName)} - ${_capitalizeFirst(variable)}',
        color: colors[index % colors.length],
        points: generateSeries(locationName, variable, start, end),
      );
    }).toList();
  }

  /// Calculate statistics for precipitation values
  static Map<String, double> calculatePrecipitationStats(List<TimePoint> points) {
    if (points.isEmpty) {
      return {'mean': 0.0, 'stddev': 0.0};
    }

    final values = points.map((p) => p.v).toList();
    final mean = values.reduce((a, b) => a + b) / values.length;
    
    final variance = values
        .map((v) => (v - mean) * (v - mean))
        .reduce((a, b) => a + b) / values.length;
    
    return {
      'mean': mean,
      'stddev': sqrt(variance),
    };
  }

  static String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}