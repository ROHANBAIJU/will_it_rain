import 'package:flutter/material.dart';
import '../widgets/dynamic_weather_card.dart';
import '../services/api_client.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool isCalendarOpen = false;
  
  // Current weather state
  bool _loadingCurrentWeather = true;
  Map<String, dynamic>? _currentWeatherData;
  
  // Map/search state
  final TextEditingController _searchController = TextEditingController();
  LatLng _mapCenter = LatLng(40.7128, -74.0060);
  Marker? _selectedMarker;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadCurrentWeather();
  }

  Future<void> _loadCurrentWeather() async {
    setState(() => _loadingCurrentWeather = true);
    
    try {
      final data = await ApiClient.instance.getJson(
        '/weather/current?lat=${_mapCenter.latitude}&lon=${_mapCenter.longitude}',
      );
      
      setState(() {
        _currentWeatherData = data;
        _loadingCurrentWeather = false;
      });
    } catch (e) {
      print('Error loading current weather: $e');
      setState(() => _loadingCurrentWeather = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Planning Ahead Header
          _buildPlanningHeader(),
          
          const SizedBox(height: 20),
          
          // Current Weather Card (Dynamic)
          _buildCurrentWeatherCard(),

          const SizedBox(height: 24),

          // Search and Auto-locate
          _buildSearchSection(),

          const SizedBox(height: 24),

          // OpenStreetMap Widget
          _buildMapSection(),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPlanningHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF7C6BAD),
            Color(0xFF9B87C4),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C6BAD).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
              Icons.wb_sunny_outlined,
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
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Use our Weather Predictor AI Nimbus to check weather conditions for any future date',
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
    );
  }

  Widget _buildCurrentWeatherCard() {
    if (_loadingCurrentWeather || _currentWeatherData == null) {
      return const DynamicWeatherCard(
        condition: 'sunny',
        temperature: 0,
        description: 'Loading...',
        isLoading: true,
      );
    }

    final temp = _currentWeatherData!['temperature'];
    return DynamicWeatherCard(
      condition: _currentWeatherData!['condition'] ?? 'sunny',
      temperature: (temp['celsius'] ?? 0.0).toDouble(),
      description: _currentWeatherData!['description'] ?? 'Current conditions',
      isLoading: false,
    );
  }

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Search Location',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Click on map or use auto-locate',
            prefixIcon: const Icon(Icons.search, color: Color(0xFF7C6BAD)),
            suffixIcon: IconButton(
              icon: const Icon(Icons.my_location, color: Color(0xFF7C6BAD)),
              onPressed: _autoLocate,
            ),
            filled: true,
            fillColor: Colors.white,
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
          readOnly: true,
        ),
      ],
    );
  }

  Widget _buildMapSection() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: _mapCenter,
            zoom: 13.0,
            onTap: (_, latLng) {
              setState(() {
                _mapCenter = latLng;
                _selectedMarker = Marker(
                  point: latLng,
                  builder: (_) => const Icon(
                    Icons.location_on,
                    color: Color(0xFF7C6BAD),
                    size: 40,
                  ),
                );
              });
              _loadCurrentWeather();
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.aeronimbus.app',
            ),
            if (_selectedMarker != null)
              MarkerLayer(markers: [_selectedMarker!]),
          ],
        ),
      ),
    );
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
      _loadCurrentWeather();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
