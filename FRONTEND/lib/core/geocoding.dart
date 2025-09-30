// lib/core/geocoding.dart
import 'package:flutter/foundation.dart';

typedef GeoResult = (String name, double lat, double lon);

class GeocodingService {
  /// Frontend-only geocoding.
  /// On web we use a small built-in dictionary (no network, no Platform).
  /// On mobile it still works the same way (dictionary first; you can later
  /// replace with a real API if you want).
  static Future<GeoResult?> geocode(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return null;

    // Simple dictionary (add any cities you need)
    const dict = <String, GeoResult>{
      'new york': ('New York, United States', 40.7128, -74.0060),
      'mumbai': ('Mumbai, Maharashtra, India', 19.0760, 72.8777),
      'chennai': ('Chennai, Tamil Nadu, India', 13.0827, 80.2707),
      'delhi': ('Delhi, India', 28.6139, 77.2090),
      'bengaluru': ('Bengaluru, Karnataka, India', 12.9716, 77.5946),
      'bangalore': ('Bengaluru, Karnataka, India', 12.9716, 77.5946),
      'san francisco': ('San Francisco, United States', 37.7749, -122.4194),
      'los angeles': ('Los Angeles, United States', 34.0522, -118.2437),
      'london': ('London, United Kingdom', 51.5072, -0.1276),
      'paris': ('Paris, France', 48.8566, 2.3522),
      'tokyo': ('Tokyo, Japan', 35.6762, 139.6503),
      'sydney': ('Sydney, Australia', -33.8688, 151.2093),
      'singapore': ('Singapore', 1.3521, 103.8198),
    };

    // Try exact match
    if (dict.containsKey(q)) return dict[q];

    // Try fuzzy: first word match
    final hit = dict.keys.firstWhere(
      (k) => k.startsWith(q) || q.startsWith(k),
      orElse: () => '',
    );
    if (hit.isNotEmpty) return dict[hit];

    // As a last resort just return the capitalized input centered on USA.
    // This prevents failures on web. You can improve later.
    return (toTitleCase(query), 39.8283, -98.5795);
  }

  static String toTitleCase(String s) {
    return s.split(' ').where((e) => e.isNotEmpty).map((w) {
      final lower = w.toLowerCase();
      return lower[0].toUpperCase() + lower.substring(1);
    }).join(' ');
  }
}
