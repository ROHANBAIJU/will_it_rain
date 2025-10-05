import 'package:flutter/material.dart';

import '../widgets/footer.dart';

import 'package:flutter_map/flutter_map.dart';

import 'package:latlong2/latlong.dart';
import '../services/geocoding_service.dart';
import '../state/app_state.dart';
import '../services/api_client.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';

String _shortWeekday(int weekday) {
  const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return names[(weekday - 1) % 7];
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

enum _DashTab { today, tomorrow, tenDays }

class _DashboardPageState extends State<DashboardPage> {
  bool isCalendarOpen = false;
  _DashTab selected = _DashTab.today;
  // Map/search state
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<PlaceSuggestion> _suggestions = [];
  LatLng _mapCenter = LatLng(40.7128, -74.0060);
  Marker? _selectedMarker;
  final MapController _mapController = MapController();

  late final VoidCallback _locationListener;

  @override
  void initState() {
    super.initState();
    _locationListener = () async {
      final loc = AppState.location.value;
      if (loc == null || loc.trim().isEmpty) return;
      try {
        final res = await GeocodingService.search(loc.trim(), limit: 1);
        if (res.isNotEmpty) {
          final s = res.first;
          if (!mounted) return;
          setState(() {
            _mapCenter = LatLng(s.lat, s.lon);
            _selectedMarker = Marker(
              point: _mapCenter,
              width: 40,
              height: 40,
              builder: (ctx) => const Icon(
                Icons.location_pin,
                color: Colors.red,
                size: 40,
              ),
            );
            _searchController.text = s.displayName;
          });
          try {
            _mapController.move(_mapCenter, 12.0);
          } catch (_) {}
        }
      } catch (_) {}
    };

    // Register listener
    AppState.location.addListener(_locationListener);

    // Weather state
    _loadingCurrentWeather = true;
    _currentWeatherData = null;

    // Load initial weather for default center
    _loadCurrentWeather();
    // Load extended payloads
    _loadTodayPayload();
    _loadTomorrowPayload();
    _load10DayPayload();
  }

  bool _loadingCurrentWeather = false;
  Map<String, dynamic>? _currentWeatherData;

  // New: today/tomorrow/ten-day payloads
  bool _loadingToday = false;
  Map<String, dynamic>? _todayPayload;

  bool _loadingTomorrow = false;
  Map<String, dynamic>? _tomorrowPayload;

  bool _loading10Day = false;
  Map<String, dynamic>? _tenDayPayload;

  Future<void> _loadCurrentWeather() async {
    setState(() => _loadingCurrentWeather = true);
    try {
      final data = await ApiClient.instance.getJson(
        '/weather/current?lat=${_mapCenter.latitude}&lon=${_mapCenter.longitude}',
      );
      if (!mounted) return;
      setState(() {
        _currentWeatherData = data;
        _loadingCurrentWeather = false;
      });
    } catch (e) {
      // ignore errors but stop loading
      if (!mounted) return;
      setState(() => _loadingCurrentWeather = false);
    }
  }

  Future<void> _loadTodayPayload() async {
    setState(() => _loadingToday = true);
    try {
      final data = await ApiClient.instance.getJson('/weather/today?lat=${_mapCenter.latitude}&lon=${_mapCenter.longitude}');
      if (!mounted) return;
      setState(() {
        _todayPayload = data;
        _loadingToday = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingToday = false);
    }
  }

  Future<void> _loadTomorrowPayload() async {
    setState(() => _loadingTomorrow = true);
    try {
      final data = await ApiClient.instance.getJson('/weather/tomorrow?lat=${_mapCenter.latitude}&lon=${_mapCenter.longitude}');
      if (!mounted) return;
      setState(() {
        _tomorrowPayload = data;
        _loadingTomorrow = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingTomorrow = false);
    }
  }

  Future<void> _load10DayPayload() async {
    setState(() => _loading10Day = true);
    try {
      final data = await ApiClient.instance.getJson('/weather/10day?lat=${_mapCenter.latitude}&lon=${_mapCenter.longitude}');
      if (!mounted) return;
      setState(() {
        _tenDayPayload = data;
        _loading10Day = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading10Day = false);
    }
  }

  @override
  void dispose() {
    AppState.location.removeListener(_locationListener);
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ===== Hero Weather Card =====
          _HeroWeather(
            location: _searchController.text.isNotEmpty ? _searchController.text : 'Current location',
            data: _currentWeatherData,
            loading: _loadingCurrentWeather,
          ),

          const SizedBox(height: 12),

          // ===== Tab Pills (with overflow prevention) =====
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _pill(
                  label: 'Today',
                  active: selected == _DashTab.today,
                  onTap: () => setState(() => selected = _DashTab.today),
                ),
                const SizedBox(width: 8),
                _pill(
                  label: 'Tomorrow',
                  active: selected == _DashTab.tomorrow,
                  onTap: () => setState(() => selected = _DashTab.tomorrow),
                ),
                const SizedBox(width: 8),
                _pill(
                  label: '10 days',
                  active: selected == _DashTab.tenDays,
                  onTap: () => setState(() => selected = _DashTab.tenDays),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ===== Tab Content =====
          if (selected == _DashTab.today) _TodayCard(payload: _todayPayload, loading: _loadingToday),
          if (selected == _DashTab.tomorrow) _TomorrowCard(payload: _tomorrowPayload, loading: _loadingTomorrow),
          if (selected == _DashTab.tenDays) _TenDayCard(payload: _tenDayPayload, loading: _loading10Day),

          const SizedBox(height: 12),

          // ===== Google Maps Placeholder =====
          // ===== OpenStreetMap Widget =====
          SizedBox(
            height: 360,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  // Search bar
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: const Color(0x0DFFFFFF),
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search location or use auto-locate',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.my_location),
                                onPressed: () async {
                                  bool serviceEnabled;
                                  LocationPermission permission;

                                  serviceEnabled = await Geolocator.isLocationServiceEnabled();
                                  if (!serviceEnabled) {
                                    // Location services are not enabled
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Location services are disabled.')),
                                    );
                                    return;
                                  }

                                  permission = await Geolocator.checkPermission();
                                  if (permission == LocationPermission.denied) {
                                    permission = await Geolocator.requestPermission();
                                    if (permission == LocationPermission.denied) {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Location permissions are denied.')),
                                      );
                                      return;
                                    }
                                  }

                                  if (permission == LocationPermission.deniedForever) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Location permissions are permanently denied.')),
                                    );
                                    return;
                                  }

                                  final pos = await Geolocator.getCurrentPosition();
                                  // Immediately update the map using device coords so marker appears
                                  final latlon = LatLng(pos.latitude, pos.longitude);
                                  if (!mounted) return;
                                  setState(() {
                                    _mapCenter = latlon;
                                    _selectedMarker = Marker(
                                      point: _mapCenter,
                                      width: 40,
                                      height: 40,
                                      builder: (ctx) => const Icon(
                                        Icons.location_pin,
                                        color: Colors.red,
                                        size: 40,
                                      ),
                                    );
                                  });
                                  try {
                                    _mapController.move(_mapCenter, 12.0);
                                  } catch (_) {}

                                  // Then try reverse geocoding to show a friendly place name (may fail on web due to CORS)
                                  try {
                                    final place = await GeocodingService.reverse(pos.latitude, pos.longitude);
                                    if (place != null) {
                                      if (!mounted) return;
                                      setState(() {
                                        _searchController.text = place.displayName;
                                      });
                                    }
                                  } catch (_) {
                                    // ignore reverse geocode errors (CORS or network)
                                  }
                                },
                            ),
                          ),
                            onSubmitted: (v) async {
                              if (v.trim().isEmpty) return;
                              final res = await GeocodingService.search(v.trim(), limit: 1);
                              if (res.isNotEmpty) {
                                final s = res.first;
                                setState(() {
                                  _mapCenter = LatLng(s.lat, s.lon);
                                  _selectedMarker = Marker(
                                    point: _mapCenter,
                                    width: 40,
                                    height: 40,
                                    builder: (ctx) => const Icon(
                                      Icons.location_pin,
                                      color: Colors.red,
                                      size: 40,
                                    ),
                                  );
                                  _suggestions = [];
                                  _searchController.text = s.displayName;
                                });
                                try {
                                  _mapController.move(_mapCenter, 12.0);
                                } catch (_) {}
                              }
                            },
                          onChanged: (v) {
                            if (_debounce?.isActive ?? false) _debounce!.cancel();
                            _debounce = Timer(const Duration(milliseconds: 400), () async {
                              if (v.trim().isEmpty) {
                                setState(() => _suggestions = []);
                                return;
                              }
                              final res = await GeocodingService.search(v.trim());
                              setState(() => _suggestions = res);
                            });
                          },
                        ),
                        // suggestions
                        if (_suggestions.isNotEmpty)
                          Container(
                            constraints: const BoxConstraints(maxHeight: 140),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _suggestions.length,
                              itemBuilder: (context, idx) {
                                final s = _suggestions[idx];
                                return ListTile(
                                  title: Text(s.displayName, style: const TextStyle(color: Colors.black, fontSize: 13)),
                                  onTap: () {
                                    // center map and add marker
                                    setState(() {
                                      _mapCenter = LatLng(s.lat, s.lon);
                                      _selectedMarker = Marker(
                                        point: _mapCenter,
                                        width: 40,
                                        height: 40,
                                        builder: (ctx) => const Icon(
                                          Icons.location_pin,
                                          color: Colors.red,
                                          size: 40,
                                        ),
                                      );
                                      _suggestions = [];
                                      _searchController.text = s.displayName;
                                    });
                                    try {
                                      _mapController.move(_mapCenter, 12.0);
                                    } catch (_) {}
                                  },
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Map
                  Expanded(
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        center: _mapCenter,
                        zoom: 12,
                        // Allow tapping to place a pin anywhere on the map
                        onTap: (tapPos, latlng) async {
                          if (!mounted) return;
                          setState(() {
                            _mapCenter = latlng;
                            _selectedMarker = Marker(
                              point: _mapCenter,
                              width: 40,
                              height: 40,
                              builder: (ctx) => const Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 40,
                              ),
                            );
                          });
                          try {
                            _mapController.move(_mapCenter, 12.0);
                          } catch (_) {}

                          // Load weather for tapped coordinates
                          _loadCurrentWeather();

                          // Try reverse geocoding to a friendly name and update search box / app state
                          try {
                            final place = await GeocodingService.reverse(latlng.latitude, latlng.longitude);
                            if (place != null && mounted) {
                              setState(() {
                                _searchController.text = place.displayName;
                                AppState.location.value = place.displayName;
                              });
                            }
                          } catch (_) {}
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.aeronimbus',
                        ),
                        MarkerLayer(
                          markers: [
                            if (_selectedMarker != null) _selectedMarker!,
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Coordinates readout
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'Lat: ${_mapCenter.latitude.toStringAsFixed(5)}, Lon: ${_mapCenter.longitude.toStringAsFixed(5)}',
                          style: const TextStyle(color: Colors.black, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ===== Calendar Integration (Collapsible) =====
          Theme(
            data: Theme.of(context).copyWith(
              dividerColor: const Color(0x00000000),
              canvasColor: Colors.transparent,
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 8),
              initiallyExpanded: isCalendarOpen,
              onExpansionChanged: (v) => setState(() => isCalendarOpen = v),
              title: Row(
                children: const [
                  Icon(
                    Icons.calendar_month,
                    color: Color(0xFF06B6D4),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Calendar Integration',
                    style: TextStyle(color: Color(0xFF000000)),
                  ),
                ],
              ),
              trailing: Icon(
                isCalendarOpen ? Icons.expand_less : Icons.expand_more,
                color: Colors.black54,
                size: 20,
              ),
              backgroundColor: const Color(0x0DFFFFFF),
              collapsedBackgroundColor: const Color(0x0DFFFFFF),
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Connect your calendar to see weather forecasts for your events and get alerts for outdoor activities.',
                        style: TextStyle(color: Color(0xFF6B6B6B)),
                      ),
                      const SizedBox(height: 12),
                      // Calendar provider tabs (Google / Outlook)
                      DefaultTabController(
                        length: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0x0DFFFFFF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0x1AFFFFFF)),
                          ),
                          child: Column(
                            children: [
                              TabBar(
                                isScrollable: false,
                                labelColor: Colors.black,
                                unselectedLabelColor: const Color(0xB36B6B6B),
                                indicatorColor: const Color(0xFFFACC15),
                                tabs: const [
                                  Tab(
                                    icon: Icon(Icons.calendar_today),
                                    text: 'Google',
                                  ),
                                  Tab(
                                    icon: Icon(Icons.mail_outline),
                                    text: 'Outlook',
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 100,
                                child: TabBarView(
                                  children: [
                                    // Google
                                    Center(
                                      child: ElevatedButton.icon(
                                        onPressed: () {},
                                        icon: const Icon(Icons.link, size: 18),
                                        label: const Text('Connect'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF2563EB,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Outlook
                                    Center(
                                      child: ElevatedButton.icon(
                                        onPressed: () {},
                                        icon: const Icon(Icons.link, size: 18),
                                        label: const Text('Connect'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF4F46E5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0x0DFFFFFF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x1AFFFFFF)),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            _eventRow(
                              'Morning Jog • Tomorrow 7:00 AM',
                              'Perfect Weather',
                              chipColor: const Color(0x3310B981),
                              chipTextColor: const Color(0xFF6EE7B7),
                            ),
                            const SizedBox(height: 8),
                            _eventRow(
                              'Outdoor Meeting • Thu 2:00 PM',
                              'Bring Umbrella',
                              chipColor: const Color(0x33F59E0B),
                              chipTextColor: const Color(0xFFFACC15),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          const SizedBox(height: 20),
          const FooterBar(),
        ],
      ),
    );
  }

  // --- small helpers ---

  static Widget _pill({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF7C6BAD) : const Color(0xFFF5F3FF),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF7C6BAD),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static Widget _eventRow(
    String title,
    String badge, {
    required Color chipColor,
    required Color chipTextColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(fit: FlexFit.loose,
          child: Text(
            title,
            style: const TextStyle(color: Color(0xFF6B6B6B)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: chipColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE8E4F3)),
          ),
          child: Text(
            badge,
            style: TextStyle(
              color: chipTextColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

// ====== HERO WEATHER CARD ======

class _HeroWeather extends StatelessWidget {
  final Map<String, dynamic>? data;
  final bool loading;
  final String? location;

  const _HeroWeather({this.data, this.loading = false, this.location});

  @override
  Widget build(BuildContext context) {
    // Extract live values or fall back to placeholders.
    // Be tolerant of different backend key names.
    String fmtNum(dynamic v) {
      if (v == null) return '--';
      double? asNum;
      if (v is double) {
        asNum = v;
      } else if (v is int) asNum = v.toDouble();
      else if (v is String) asNum = double.tryParse(v);

      // Treat sentinel/unrealistic numbers (like -999) as missing
      if (asNum == null) return '--';
      if (asNum <= -500) return '--';

      return asNum.round().toString();
    }

    final tempCandidates = [
      () => data?['temperature']?['celsius'],
      () => data?['temp_c'],
      () => data?['temperature_celsius'],
      () => data?['temp'],
    ];
    String tempC = '--';
    for (final c in tempCandidates) {
      final v = c();
      if (v != null) {
        tempC = fmtNum(v);
        break;
      }
    }

    final condition = () {
      final c = data?['condition'] ?? data?['description'] ?? data?['weather'];
      if (c == null) return 'unknown';
      return c.toString().toLowerCase();
    }();

    // Friendly label and icon mapping
    String conditionLabel() {
      if (condition.contains('partly')) return 'Partly cloudy';
      if (condition.contains('cloud')) return 'Cloudy';
      if (condition.contains('sun') || condition.contains('clear')) return 'Sunny';
      if (condition.contains('rain')) return 'Rainy';
      if (condition.contains('snow')) return 'Snowy';
      return condition[0].toUpperCase() + condition.substring(1);
    }

    IconData conditionIcon() {
      if (condition.contains('partly') || condition.contains('cloud')) return Icons.cloud;
      if (condition.contains('rain')) return Icons.beach_access; // rain umbrella-like
      if (condition.contains('snow')) return Icons.ac_unit;
      return Icons.wb_sunny;
    }

    Color conditionColor() {
      if (condition.contains('partly') || condition.contains('cloud')) return const Color(0xFF90A4AE);
      if (condition.contains('rain')) return const Color(0xFF2196F3);
      if (condition.contains('snow')) return const Color(0xFF81D4FA);
      return const Color(0xFFFACC15);
    }

    // Humidity
    final humidityCandidates = [() => data?['humidity'], () => data?['humidity_percent'], () => data?['average_humidity_percent']];
    String humidity = '--';
    for (final c in humidityCandidates) {
      final v = c();
      if (v != null) {
        humidity = fmtNum(v);
        break;
      }
    }

    // Wind speed (prefer km/h). Convert from m/s to km/h when keys indicate meters-per-second
    final windCandidates = [
      () => data?['wind_speed'],
      () => data?['wind_kph'],
      () => data?['average_wind_speed_mps'],
      () => data?['wind']
    ];
    String wind = '--';
    for (final c in windCandidates) {
      final v = c();
      if (v != null) {
        // If the key name contains 'mps' or 'm/s' treat the number as meters-per-second and convert to km/h
        final raw = v;
        double? asNum;
        if (raw is double) {
          asNum = raw;
        } else if (raw is int) asNum = raw.toDouble();
        else if (raw is String) asNum = double.tryParse(raw);

        if (asNum != null) {
          // heuristic: if this candidate came from average_wind_speed_mps or looks like m/s, convert
          if (c.toString().contains('mps') || c.toString().contains('m/s') || raw is double && asNum < 20) {
            // convert m/s -> km/h
            asNum = asNum * 3.6;
          }
          wind = asNum.round().toString();
        } else {
          wind = fmtNum(v);
        }
        break;
      }
    }

    // Precipitation probability
    final precipCandidates = [() => data?['precipitation_probability_percent'], () => data?['precipitation_probability'], () => data?['precipitation'], () => data?['rain_probability']];
    String rainProb = '--';
    for (final c in precipCandidates) {
      final v = c();
      if (v != null) {
        rainProb = fmtNum(v);
        break;
      }
    }
    return Container(
      width: double.infinity,
      // Clean white card with purple gradient accent
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Purple gradient background on top portion
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            // Increase the purple header height to give the hero card more visual weight
            height: 260,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6B5BA6), // Deep purple
                    Color(0xFF8B7AB8), // Soft lavender
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Location + Live badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          // Ellipsize long locations and show full name on hover/tap via Tooltip
                          Expanded(
                            child: Tooltip(
                              message: location ?? 'Current location',
                              child: Text(
                                location ?? 'Current location',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: const Text(
                        'Live',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Temperature & extras - Make responsive
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmallScreen = constraints.maxWidth < 400;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main Temp
                        Flexible(fit: FlexFit.loose,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '$tempC°',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isSmallScreen ? 52 : 72,
                                      fontWeight: FontWeight.w600,
                                      shadows: [
                                        Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'C',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.95),
                                      fontSize: isSmallScreen ? 18 : 24,
                                      shadows: [
                                        Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 3),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                conditionLabel(),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.95),
                                  fontSize: isSmallScreen ? 16 : 20,
                                  fontWeight: FontWeight.w600,
                                  shadows: [
                                    Shadow(color: Colors.black26, offset: Offset(0, 1), blurRadius: 3),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              _MiniStat(
                                icon: Icons.thermostat,
                                label: 'Feels like $tempC°',
                                color: Colors.white70,
                              ),
                              const SizedBox(height: 4),
                              _MiniStat(
                                icon: Icons.opacity,
                                label: '$humidity% humidity',
                                color: Colors.white70,
                              ),
                            ],
                          ),
                        ),

                        // Radial sun + right stats
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              width: isSmallScreen ? 72 : 96,
                              height: isSmallScreen ? 72 : 96,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0x33FACC15),
                              ),
                              alignment: Alignment.center,
                              child: Container(
                                width: isSmallScreen ? 48 : 64,
                                height: isSmallScreen ? 48 : 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: conditionColor(),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  conditionIcon(),
                                  color: Colors.white,
                                  size: isSmallScreen ? 28 : 36,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.umbrella,
                                  size: 16,
                                  color: condition.contains('rain') ? const Color(0xFF1976D2) : const Color(0xFF7C6BAD),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${rainProb == '--' ? '0' : rainProb}% rain',
                                  style: const TextStyle(color: Color(0xFF6B6B6B)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.air,
                                  size: 16,
                                  color: Color(0xFF7C6BAD),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  wind == '--' ? '--' : '$wind km/h',
                                  style: const TextStyle(color: Color(0xFF6B6B6B)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 8),

                // Quick Stats grid - show live values coming from the same `data` as temperature
                const Divider(color: Color(0xFFE8E4F3)),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmallScreen = constraints.maxWidth < 400;

                    // helper: format numbers and treat sentinel values as missing
                    String fmtQuick(dynamic v) {
                      if (v == null) return '--';
                      double? n;
                      if (v is double) {
                        n = v;
                      } else if (v is int) n = v.toDouble();
                      else if (v is String) n = double.tryParse(v);
                      if (n == null) return '--';
                      if (n <= -500) return '--';
                      return n.round().toString();
                    }

                    // (removed fmtTime helper - sunrise/time quick stat replaced by cloud cover)

                    // Wind speed candidates from various backends
                    final windCandidates = [() => data?['wind_speed'], () => data?['wind_speed_mps'], () => data?['wind_speed_ms'], () => data?['wind_mps'], () => data?['wind']];
                    String wind = '--';
                    for (final c in windCandidates) {
                      final v = c();
                      if (v != null) {
                        wind = fmtQuick(v);
                        break;
                      }
                    }
                    final windQuick = wind == '--' ? '--' : '$wind m/s';

                    // Humidity (we already computed humidity earlier)
                    final humidityQuick = humidity != '--' ? '$humidity%' : '--';

                    // Pressure candidates
                    final pressureCandidates = [() => data?['pressure'], () => data?['pressure_hpa'], () => data?['pressure_mbar'], () => data?['sea_level_pressure']];
                    String pressure = '--';
                    for (final c in pressureCandidates) {
                      final v = c();
                      if (v != null) {
                        pressure = fmtQuick(v);
                        break;
                      }
                    }

                    // Cloud cover candidates
                    final cloudCandidates = [() => data?['cloud_cover'], () => data?['clouds'], () => data?['cloudiness']];
                    String cloud = '--';
                    for (final c in cloudCandidates) {
                      final v = c();
                      if (v != null) {
                        cloud = fmtQuick(v);
                        break;
                      }
                    }
                    final cloudQuick = cloud == '--' ? '--' : '$cloud%';

                    if (isSmallScreen) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: _QuickStat(value: windQuick, label: 'Wind Speed', color: const Color(0xFF3B82F6)),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: _QuickStat(value: humidityQuick, label: 'Humidity', color: const Color(0xFF06B6D4)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Flexible(
                                child: _QuickStat(value: pressure == '--' ? '--' : pressure, label: 'Pressure (hPa)', color: const Color(0xFF10B981)),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: _QuickStat(value: cloudQuick, label: 'Cloud Cover', color: const Color(0xFF8B5CF6)),
                              ),
                            ],
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Flexible(child: _QuickStat(value: windQuick, label: 'Wind Speed', color: const Color(0xFF3B82F6))),
                        const SizedBox(width: 8),
                        Flexible(child: _QuickStat(value: humidityQuick, label: 'Humidity', color: const Color(0xFF06B6D4))),
                        const SizedBox(width: 8),
                        Flexible(child: _QuickStat(value: pressure == '--' ? '--' : pressure, label: 'Pressure (hPa)', color: const Color(0xFF10B981))),
                        const SizedBox(width: 8),
                        Flexible(child: _QuickStat(value: cloudQuick, label: 'Cloud Cover', color: const Color(0xFF8B5CF6))),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 12),
                const Divider(color: Color(0x1AFFFFFF)),
                const SizedBox(height: 12),

                // Action-Oriented Insight
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8E4F3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD1CBE8)),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C6BAD),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Flexible(fit: FlexFit.loose,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Perfect conditions for outdoor activities',
                              style: TextStyle(color: Color(0xFF7C6BAD), fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Low rain probability, comfortable temperature, light winds',
                              style: TextStyle(
                                color: Color(0xFF6B6B6B),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ====== TODAY CARD ======

class _TodayCard extends StatelessWidget {
  final Map<String, dynamic>? payload;
  final bool loading;
  const _TodayCard({this.payload, this.loading = false});

  @override
  Widget build(BuildContext context) {
    // Build hourly slots from current Asia/Kolkata time to end of day (23:00)
    DateTime nowUtc = DateTime.now().toUtc();
    // IST is UTC+5:30
    final istNow = nowUtc.add(const Duration(hours: 5, minutes: 30));
    final startHour = istNow.hour;
    final List<Map<String, String>> hours = [];
    for (int h = startHour; h <= 23; h++) {
      String label;
      if (h == istNow.hour) {
        label = 'Now';
      } else {
        final isPm = h >= 12;
        final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
        label = isPm ? '$hour12 PM' : '$hour12 AM';
      }
      // placeholders for temp and icon; if you have hourly data, replace here
      hours.add({'time': label, 'temp': '--', 'icon': '⛅'});
    }

    // If payload contains hourly, map temperatures/icons from payload
    if (payload != null && payload!['hourly'] != null) {
      final ph = payload!['hourly'] as List<dynamic>;
      for (int i = 0; i < ph.length; i++) {
        final item = ph[i] as Map<String, dynamic>;
        // Only replace matching labels (assumes today's hours)
        if (i < hours.length) {
          final tempVal = item['temperature_c'];
          hours[i]['temp'] = (tempVal != null) ? '${(tempVal as num).round()}°' : (hours[i]['temp'] ?? '--');
          // choose simple icon mapping by cloud_cover/precipitation
          final cc = item['cloud_cover'] ?? 0;
          final precip = item['precipitation'] ?? 0;
          if (precip is num && precip > 1) hours[i]['icon'] = '🌧';
          else if (cc is num && cc > 70) hours[i]['icon'] = '☁';
          else if (cc is num && cc > 40) hours[i]['icon'] = '⛅';
          else hours[i]['icon'] = '☀';
        }
      }
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hourly Forecast',
            style: TextStyle(color: Color(0xFF2D2D2D), fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          // New polished horizontal hourly list
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: hours.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, idx) {
                final h = hours[idx];
                final bool isNow = h['time'] == 'Now';
                return Container(
                  width: 84,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  decoration: BoxDecoration(
                    color: isNow ? const Color(0xFFFBF7EE) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF1EEF6)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(h['time']!, style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 12)),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isNow ? const Color(0xFFFFF6EA) : const Color(0xFFF7F7FA),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(h['icon']!, style: const TextStyle(fontSize: 20)),
                      ),
                      Text(h['temp']!, style: const TextStyle(color: Color(0xFF2D2D2D), fontWeight: FontWeight.w700)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ====== TOMORROW CARD ======

class _TomorrowCard extends StatelessWidget {
  final Map<String, dynamic>? payload;
  final bool loading;
  const _TomorrowCard({this.payload, this.loading = false});

  @override
  Widget build(BuildContext context) {
    final hours = [
      {'time': '6 AM', 'temp': '19°', 'icon': '🌅'},
      {'time': '9 AM', 'temp': '21°', 'icon': '☀'},
      {'time': '12 PM', 'temp': '24°', 'icon': '☀'},
      {'time': '3 PM', 'temp': '26°', 'icon': '☀'},
      {'time': '6 PM', 'temp': '23°', 'icon': '🌤'},
      {'time': '9 PM', 'temp': '20°', 'icon': '🌙'},
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tomorrow's Forecast",
            style: TextStyle(color: Color(0xFF2D2D2D), fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Flexible(fit: FlexFit.loose,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '26°',
                          style: TextStyle(color: Color(0xFF2D2D2D), fontSize: 44, fontWeight: FontWeight.w300),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'C',
                          style: TextStyle(color: Color(0xFF6B6B6B), fontSize: 20),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Sunny',
                      style: TextStyle(color: Color(0xFF6B6B6B), fontSize: 16),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'High: 26° / Low: 19°',
                      style: TextStyle(color: Color(0xFF6B6B6B), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0x33FACC15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFACC15),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final h in hours)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Text(
                          '${h['time']}',
                          style: const TextStyle(
                            color: Color(0xFF6B6B6B),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${h['icon']}',
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${h['temp']}',
                          style: const TextStyle(color: Color(0xFF2D2D2D), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ====== 10-DAY CARD ======

class _TenDayCard extends StatelessWidget {
  final Map<String, dynamic>? payload;
  final bool loading;
  const _TenDayCard({this.payload, this.loading = false});

  @override
  Widget build(BuildContext context) {
  // If payload has forecasts, map them into days
  List<Map<String, dynamic>> days = [
      {
        'day': 'Today',
        'high': '24°',
        'low': '18°',
        'condition': 'Partly Cloudy',
        'icon': '🌤',
      },
      {
        'day': 'Tomorrow',
        'high': '26°',
        'low': '19°',
        'condition': 'Sunny',
        'icon': '☀',
      },
      {
        'day': 'Wed',
        'high': '23°',
        'low': '17°',
        'condition': 'Cloudy',
        'icon': '☁',
      },
      {
        'day': 'Thu',
        'high': '21°',
        'low': '15°',
        'condition': 'Rain',
        'icon': '🌧',
      },
      {
        'day': 'Fri',
        'high': '25°',
        'low': '18°',
        'condition': 'Partly Cloudy',
        'icon': '🌤',
      },
      {
        'day': 'Sat',
        'high': '27°',
        'low': '20°',
        'condition': 'Sunny',
        'icon': '☀',
      },
      {
        'day': 'Sun',
        'high': '24°',
        'low': '17°',
        'condition': 'Thunderstorm',
        'icon': '⛈',
      },
      {
        'day': 'Mon',
        'high': '22°',
        'low': '16°',
        'condition': 'Cloudy',
        'icon': '☁',
      },
      {
        'day': 'Tue',
        'high': '23°',
        'low': '17°',
        'condition': 'Partly Cloudy',
        'icon': '🌤',
      },
      {
        'day': 'Wed',
        'high': '25°',
        'low': '18°',
        'condition': 'Sunny',
        'icon': '☀',
      },
    ];

    // If backend provided ten-day forecasts, replace placeholders
    if (payload != null && payload!['forecasts'] != null) {
      final list = payload!['forecasts'] as List<dynamic>;
      final mapped = <Map<String, dynamic>>[];
      for (final item in list) {
        final d = item as Map<String, dynamic>;
        final date = DateTime.parse(d['date']);
        final dayLabel = (mapped.length == 0) ? 'Today' : _shortWeekday(date.weekday);
        final stats = d['prediction'] != null ? (d['prediction']['statistics'] ?? {}) : {};
        mapped.add({
          'day': dayLabel,
          'high': stats['max_temperature_celsius'] != null ? '${(stats['max_temperature_celsius']).round()}°' : '--',
          'low': stats['min_temperature_celsius'] != null ? '${(stats['min_temperature_celsius']).round()}°' : '--',
          'condition': d['prediction'] != null ? (d['prediction']['statistics']['condition'] ?? '—') : '—',
          'icon': '☀',
        });
      }
      if (mapped.isNotEmpty) days = mapped;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              '10-Day Forecast',
              style: TextStyle(color: Color(0xFF2D2D2D), fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int i = 0; i < days.length; i++)
                    Padding(
                      padding: EdgeInsets.only(left: i == 0 ? 8 : 12, right: i == days.length - 1 ? 8 : 0),
                      child: Container(
                        width: 140,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: i == 0 ? const Color(0xFFFBF7EE) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF1EEF6)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  days[i]['day'] as String,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2D2D2D)),
                                ),
                                Text(
                                  days[i]['icon'] as String,
                                  style: const TextStyle(fontSize: 20),
                                ),
                              ],
                            ),
                            Text(
                              days[i]['condition'] as String,
                              style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 12),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  days[i]['high'] as String,
                                  style: const TextStyle(color: Color(0xFF2D2D2D), fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  days[i]['low'] as String,
                                  style: const TextStyle(color: Color(0xFF9B9B9B)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ====== Small visual helpers used inside the hero card ======

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _MiniStat({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? const Color(0xFF7C6BAD)),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: color ?? const Color(0xFF6B6B6B), fontSize: 12),
        ),
      ],
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _QuickStat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 12),
        ),
      ],
    );
  }
}


// Starfield painter removed for clean light theme