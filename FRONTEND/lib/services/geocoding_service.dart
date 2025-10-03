import 'dart:convert';

import 'package:http/http.dart' as http;

class PlaceSuggestion {
  final String displayName;
  final double lat;
  final double lon;

  PlaceSuggestion({required this.displayName, required this.lat, required this.lon});

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    return PlaceSuggestion(
      displayName: json['display_name'] as String,
      lat: double.parse(json['lat'] as String),
      lon: double.parse(json['lon'] as String),
    );
  }
}

class GeocodingService {
  // Use Nominatim (OpenStreetMap) for free geocoding
  static const _searchUrl = 'https://nominatim.openstreetmap.org/search';
  static const _reverseUrl = 'https://nominatim.openstreetmap.org/reverse';

  /// Query suggestions from Nominatim.
  static Future<List<PlaceSuggestion>> search(String q, {int limit = 5}) async {
    final uri = Uri.parse(_searchUrl).replace(queryParameters: {
      'q': q,
      'format': 'json',
      'addressdetails': '0',
      'limit': limit.toString(),
    });

    final resp = await http.get(uri, headers: {
      'User-Agent': 'aeronimbus/1.0 (your@email.example)'
    });

    if (resp.statusCode != 200) return [];

    final List data = json.decode(resp.body) as List;
    return data.map((e) => PlaceSuggestion.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Reverse geocode lat/lon to a display name.
  static Future<PlaceSuggestion?> reverse(double lat, double lon) async {
    final uri = Uri.parse(_reverseUrl).replace(queryParameters: {
      'lat': lat.toString(),
      'lon': lon.toString(),
      'format': 'json',
    });

    final resp = await http.get(uri, headers: {
      'User-Agent': 'aeronimbus/1.0 (your@email.example)'
    });

    if (resp.statusCode != 200) return null;

    final Map<String, dynamic> data = json.decode(resp.body) as Map<String, dynamic>;
    final display = data['display_name'] as String?;
    if (display == null) return null;

    return PlaceSuggestion(displayName: display, lat: lat, lon: lon);
  }
}