import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_client.dart';
import '../services/geocoding_service.dart';
import 'dart:async';
import '../widgets/weather_visualization.dart';

class PlanAheadWidget extends StatefulWidget {
  @override
  _PlanAheadWidgetState createState() => _PlanAheadWidgetState();
}

class _PlanAheadWidgetState extends State<PlanAheadWidget> {
  final TextEditingController _activityController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lonController = TextEditingController();
  final MapController _mapController = MapController();
  Timer? _debounce;
  List<PlaceSuggestion> _suggestions = [];
  
  LatLng _mapCenter = LatLng(40.7128, -74.0060); // Default: New York
  Marker? _selectedMarker;
  DateTime? _selectedDate;
  
  bool _isLoading = false;
  Map<String, dynamic>? _weatherData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _activityController.text = 'picnic'; // Default activity
    // Initialize lat/lon inputs from the default map center
    _latController.text = _mapCenter.latitude.toStringAsFixed(6);
    _lonController.text = _mapCenter.longitude.toStringAsFixed(6);
  }

  void _moveToLatLonFromFields() {
    String latText;
    String lonText;
    try {
      latText = _latController.text.trim();
      lonText = _lonController.text.trim();
    } catch (e) {
      // Controller may be temporarily null during hot-reload; don't crash
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lat/Lon input not available')));
      return;
    }
    if (latText.isEmpty || lonText.isEmpty) return;

    final lat = double.tryParse(latText);
    final lon = double.tryParse(lonText);
    if (lat == null || lon == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid latitude or longitude')));
      return;
    }

    final point = LatLng(lat, lon);
    setState(() {
      _mapCenter = point;
      _selectedMarker = Marker(
        point: point,
        builder: (_) => const Icon(
          Icons.location_on,
          color: Color(0xFF7C6BAD),
          size: 40,
        ),
      );
    });
    _mapController.move(point, 13.0);
  }

  @override
  void dispose() {
    _activityController.dispose();
    _searchController.dispose();
    _latController.dispose();
    _lonController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF7C6BAD),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF2D2D2D),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _autoLocate() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission permanently denied')),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _mapCenter = LatLng(position.latitude, position.longitude);
        _selectedMarker = Marker(
          point: _mapCenter,
          builder: (_) => const Icon(
            Icons.location_on,
            color: Color(0xFF7C6BAD),
            size: 40,
          ),
        );
      });
      _mapController.move(_mapCenter, 13.0);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  Future<void> _fetchForecast() async {
    if (_selectedDate == null) {
      setState(() {
        _errorMessage = 'Please select a date';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _weatherData = null;
    });

    try {
      final dateStr = _selectedDate!.toIso8601String().split('T')[0];
      final activity = _activityController.text.trim();
      final path = '/predict?lat=${_mapCenter.latitude}&lon=${_mapCenter.longitude}&date=$dateStr${activity.isNotEmpty ? '&activity=$activity' : ''}';

      final data = await ApiClient.instance.getJson(path);

      // Log the raw backend JSON to the frontend terminal (and browser console)
      try {
        print('Backend /predict response: ${data}');
      } catch (_) {}

      if (data == null) {
        throw Exception('Empty response from server');
      }

      setState(() {
        _weatherData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch forecast: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with AI Nimbus branding
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C6BAD), Color(0xFF9D8EC4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C6BAD).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.wb_cloudy,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Planning Ahead?',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'AI Nimbus helps you plan with confidence',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Activity Input
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'What are you planning?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _activityController,
                      decoration: InputDecoration(
                        hintText: 'e.g., picnic, trekking, wedding, outdoor concert',
                        hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
                        prefixIcon: const Icon(Icons.event, color: Color(0xFF7C6BAD)),
                        filled: true,
                        fillColor: const Color(0xFFF9F9F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF7C6BAD), width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Location & Date Selection
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Location',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D2D2D),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _autoLocate,
                          icon: const Icon(Icons.my_location, size: 18),
                          label: const Text('Auto-locate'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF7C6BAD),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Search bar for Plan Ahead location
                    // Latitude / Longitude quick inputs
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _latController,
                            keyboardType: TextInputType.numberWithOptions(signed: true, decimal: true),
                            decoration: InputDecoration(
                              hintText: 'Lat',
                              prefixIcon: const Icon(Icons.my_location, color: Color(0xFF7C6BAD)),
                              filled: true,
                              fillColor: const Color(0xFFF9F9F9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                              ),
                            ),
                            onSubmitted: (_) => _moveToLatLonFromFields(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _lonController,
                            keyboardType: TextInputType.numberWithOptions(signed: true, decimal: true),
                            decoration: InputDecoration(
                              hintText: 'Lon',
                              prefixIcon: const Icon(Icons.location_on, color: Color(0xFF7C6BAD)),
                              filled: true,
                              fillColor: const Color(0xFFF9F9F9),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                              ),
                            ),
                            onSubmitted: (_) => _moveToLatLonFromFields(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _moveToLatLonFromFields,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C6BAD),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
                            child: Text('Go'),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Enter city or ZIP code',
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF7C6BAD)),
                        filled: true,
                        fillColor: const Color(0xFFF9F9F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                        ),
                      ),
                      onChanged: (v) {
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        _debounce = Timer(const Duration(milliseconds: 400), () async {
                          if (v.trim().isEmpty) {
                            if (!mounted) return;
                            setState(() => _suggestions = []);
                            return;
                          }
                          try {
                            final res = await GeocodingService.search(v.trim(), limit: 5);
                            if (!mounted) return;
                            setState(() => _suggestions = res);
                          } catch (_) {
                            if (!mounted) return;
                            setState(() => _suggestions = []);
                          }
                        });
                      },
                    ),
                    if (_suggestions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 160),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _suggestions.length,
                          itemBuilder: (ctx, i) {
                            final s = _suggestions[i];
                            return ListTile(
                              title: Text(s.displayName, style: const TextStyle(color: Colors.black, fontSize: 13)),
                              onTap: () {
                                setState(() {
                                  _mapCenter = LatLng(s.lat, s.lon);
                                  _selectedMarker = Marker(
                                    point: _mapCenter,
                                    builder: (_) => const Icon(
                                      Icons.location_on,
                                      color: Color(0xFF7C6BAD),
                                      size: 40,
                                    ),
                                  );
                                  _suggestions = [];
                                  _searchController.text = s.displayName;
                                      // Update lat/lon inputs when user picks a suggestion (guard in case controller is not available)
                                      try {
                                        _latController.text = _mapCenter.latitude.toStringAsFixed(6);
                                        _lonController.text = _mapCenter.longitude.toStringAsFixed(6);
                                      } catch (_) {}
                                });
                                _mapController.move(_mapCenter, 13.0);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E5E5)),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          center: _mapCenter,
                          zoom: 10.0,
                          onTap: (tapPosition, point) {
                            setState(() {
                              _mapCenter = point;
                              _selectedMarker = Marker(
                                point: point,
                                builder: (_) => const Icon(
                                  Icons.location_on,
                                  color: Color(0xFF7C6BAD),
                                  size: 40,
                                ),
                              );
                              // Fill lat/lon inputs when user taps the map (guard controllers)
                              try {
                                _latController.text = _mapCenter.latitude.toStringAsFixed(6);
                                _lonController.text = _mapCenter.longitude.toStringAsFixed(6);
                              } catch (_) {}
                            });
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.app',
                          ),
                          if (_selectedMarker != null)
                            MarkerLayer(markers: [_selectedMarker!]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F9F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE5E5E5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 18, color: Color(0xFF7C6BAD)),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedDate == null
                                      ? 'Select date'
                                      : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF2D2D2D),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _pickDate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C6BAD),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Pick Date'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Get Forecast Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _fetchForecast,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C6BAD),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Get Weather Forecast',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Error Message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Weather Data Visualization
              if (_weatherData != null) ...[
                const SizedBox(height: 8),
                // _weatherData is the full response; pass the nested `statistics` dictionary to the widget
                WeatherDataVisualization(statistics: _weatherData!['statistics'] ?? _weatherData!),
                const SizedBox(height: 12),
                // AI Insight card (if present)
                if ((_weatherData!['ai_insight'] ?? null) != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Insight',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          (_weatherData!['ai_insight'] is String)
                              ? _weatherData!['ai_insight']
                              : (_weatherData!['ai_insight'] is Map
                                  ? (_weatherData!['ai_insight']['reasoning'] ?? '')
                                  : ''),
                          style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
