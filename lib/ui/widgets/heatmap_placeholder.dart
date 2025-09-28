import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/models.dart';

class HeatmapPlaceholder extends StatelessWidget {
  final List<Series> series;
  final String title;

  const HeatmapPlaceholder({
    super.key,
    required this.series,
    this.title = 'Regional Heatmap',
  });

  @override
  Widget build(BuildContext context) {
    final locationData = _extractLocationData();

    if (locationData.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined,
                  size: 64,
                  color: Theme.of(context).textTheme.bodySmall?.color),
              const SizedBox(height: 12),
              Text(
                'Add a location to view heatmap',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Keep a friendly height when placed in flexible/Expanded parents
        final h = max(280.0, min(constraints.maxHeight.isFinite ? constraints.maxHeight : 400.0, 400.0));

        return SizedBox(
          height: h,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: RepaintBoundary(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: _initialCenter(locationData),
                  initialZoom: 4.0,
                  minZoom: 3.0,
                  maxZoom: 12.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.nasa_space_app',
                    maxZoom: 19,
                  ),
                  MarkerLayer(
                    markers: locationData.map((data) {
                      final size = _getPrecipitationSize(data['avgPrecipitation'] as double);
                      return Marker(
                        point: data['coordinates'] as LatLng,
                        width: size,
                        height: size,
                        alignment: Alignment.center,
                        child: _buildLocationMarker(
                          context: context,
                          data: data,
                          size: size,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Circle marker with initial letter and color by precipitation.
  Widget _buildLocationMarker({
    required BuildContext context,
    required Map<String, dynamic> data,
    required double size,
  }) {
    final locationName = data['location'] as String;
    final avgPrecip = (data['avgPrecipitation'] as double).clamp(0.0, 100.0);
    final color = _getPrecipitationColor(avgPrecip);

    return Tooltip(
      message:
          '$locationName\nAvg Precipitation: ${avgPrecip.toStringAsFixed(1)}%',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            locationName.isNotEmpty ? locationName[0].toUpperCase() : '?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: size * 0.42,
            ),
          ),
        ),
      ),
    );
  }

  // Blue (low) → Green → Yellow → Orange → Red (high)
  Color _getPrecipitationColor(double precipitation) {
    if (precipitation < 20) return Colors.blue.shade400;
    if (precipitation < 40) return Colors.green.shade500;
    if (precipitation < 60) return Colors.yellow.shade700;
    if (precipitation < 80) return Colors.orange.shade700;
    return Colors.red.shade600;
  }

  // Size 20–50 px based on precipitation %
  double _getPrecipitationSize(double precipitation) {
    return 20 + (precipitation.clamp(0, 100) / 100) * 30;
  }

  /// Build per-location precipitation summary from series (frontend-only).
  List<Map<String, dynamic>> _extractLocationData() {
    final Map<String, List<TimePoint>> grouped = {};

    for (final s in series) {
      if (!s.label.toLowerCase().contains('precipitation')) continue;

      // Expect IDs like "<location>_<variable>"
      final parts = s.id.split('_');
      final locationName = parts.isNotEmpty ? parts.first : s.label;

      final pts = s.points;
      if (pts.isEmpty) continue;

      grouped.putIfAbsent(locationName, () => []);
      grouped[locationName] = pts; // keep last assignment per location
    }

    return grouped.entries.map((e) {
      final name = e.key;
      final pts = e.value;
      final avg = pts.map((p) => p.v).fold<double>(0, (a, b) => a + b) / pts.length;
      return {
        'location': name,
        'avgPrecipitation': avg,
        'coordinates': _getLocationCoordinates(name),
      };
    }).toList();
  }

  /// Default map center: average of marker coordinates.
  LatLng _initialCenter(List<Map<String, dynamic>> locs) {
    double lat = 0, lon = 0;
    for (final d in locs) {
      final c = d['coordinates'] as LatLng;
      lat += c.latitude;
      lon += c.longitude;
    }
    return LatLng(lat / locs.length, lon / locs.length);
  }

  /// Mock coordinates for common US cities; fallback to USA center.
  LatLng _getLocationCoordinates(String locationName) {
    final m = {
      'new york': const LatLng(40.7128, -74.0060),
      'los angeles': const LatLng(34.0522, -118.2437),
      'chicago': const LatLng(41.8781, -87.6298),
      'houston': const LatLng(29.7604, -95.3698),
      'phoenix': const LatLng(33.4484, -112.0740),
      'philadelphia': const LatLng(39.9526, -75.1652),
      'san antonio': const LatLng(29.4241, -98.4936),
      'san diego': const LatLng(32.7157, -117.1611),
      'dallas': const LatLng(32.7767, -96.7970),
      'san jose': const LatLng(37.3382, -121.8863),
      'austin': const LatLng(30.2672, -97.7431),
      'jacksonville': const LatLng(30.3322, -81.6557),
      'fort worth': const LatLng(32.7555, -97.3308),
      'columbus': const LatLng(39.9612, -82.9988),
      'charlotte': const LatLng(35.2271, -80.8431),
      'san francisco': const LatLng(37.7749, -122.4194),
      'indianapolis': const LatLng(39.7684, -86.1581),
      'seattle': const LatLng(47.6062, -122.3321),
      'denver': const LatLng(39.7392, -104.9903),
      'washington': const LatLng(38.9072, -77.0369),
      'boston': const LatLng(42.3601, -71.0589),
      'miami': const LatLng(25.7617, -80.1918),
      // add more as needed…
    };
    return m[locationName.toLowerCase()] ?? const LatLng(39.8283, -98.5795);
  }
}
