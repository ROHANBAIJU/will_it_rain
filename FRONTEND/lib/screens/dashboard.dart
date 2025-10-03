import 'package:flutter/material.dart';

import '../widgets/footer.dart';

import 'package:flutter_map/flutter_map.dart';

import 'package:latlong2/latlong.dart';
import '../services/geocoding_service.dart';
import 'dart:async';

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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ===== Hero Weather Card =====
          _HeroWeather(),

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
          if (selected == _DashTab.today) _TodayCard(),
          if (selected == _DashTab.tomorrow) _TomorrowCard(),
          if (selected == _DashTab.tenDays) _TenDayCard(),

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
                                // attempt to use device location
                                try {
                                  // get current position via geolocator package
                                  // to avoid adding an import and extra logic here,
                                  // we will rely on suggestions or future improvements
                                } catch (e) {
                                  // ignore for now
                                }
                              },
                            ),
                          ),
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
                                  title: Text(s.displayName, style: const TextStyle(color: Colors.white70, fontSize: 13)),
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
                      options: MapOptions(
                        center: _mapCenter,
                        zoom: 12,
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
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              trailing: Icon(
                isCalendarOpen ? Icons.expand_less : Icons.expand_more,
                color: Colors.white70,
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
                        style: TextStyle(color: Colors.white70),
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
                                labelColor: Colors.white,
                                unselectedLabelColor: const Color(0xB3FFFFFF),
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
          color: active ? const Color(0xFFFFFFFF) : const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFF3C126E) : Colors.white,
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
        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: Colors.white70),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: chipColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0x1AFFFFFF)),
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
  @override
  Widget build(BuildContext context) {
    return Container(
      // gradient & subtle starfield
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1AFFFFFF)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xE61F1440), // purple-900 ~90%
            Color(0xE61E1B4B), // indigo-800 ~90%
            Color(0xE6331E6F), // purple-700 ~90%
          ],
        ),
      ),
      child: Stack(
        children: [
          // star specks
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.20,
                child: CustomPaint(painter: _StarfieldPainterSmall()),
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
                    Row(
                      children: const [
                        Icon(
                          Icons.location_on,
                          color: Colors.white70,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'New York, NY',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x3310B981),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: const Color(0x4D10B981),
                        ), // /30
                      ),
                      child: const Text(
                        'Live',
                        style: TextStyle(
                          color: Color(0xFF6EE7B7),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '22°',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isSmallScreen ? 48 : 64,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'C',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: isSmallScreen ? 18 : 24,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Partly Cloudy',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: isSmallScreen ? 16 : 18,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _MiniStat(
                                icon: Icons.thermostat,
                                label: 'Feels like 25°',
                              ),
                              const SizedBox(height: 4),
                              _MiniStat(
                                icon: Icons.visibility,
                                label: '10km visibility',
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
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFFACC15),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.umbrella,
                                  size: 16,
                                  color: Color(0xFF06B6D4),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  '15% rain',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.air,
                                  size: 16,
                                  color: Color(0xFF10B981),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  '12 km/h',
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Quick Stats grid - Make responsive
                const Divider(color: Color(0x1AFFFFFF)),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmallScreen = constraints.maxWidth < 400;
                    if (isSmallScreen) {
                      // Stack vertically on small screens
                      return Column(
                        children: const [
                          Row(
                            children: [
                              Expanded(
                                child: _QuickStat(
                                  value: 'UV 7',
                                  label: 'High',
                                  color: Color(0xFFFACC15),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: _QuickStat(
                                  value: '68%',
                                  label: 'Humidity',
                                  color: Color(0xFF06B6D4),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _QuickStat(
                                  value: '1013',
                                  label: 'Pressure (hPa)',
                                  color: Color(0xFF10B981),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: _QuickStat(
                                  value: '6:45',
                                  label: 'Sunrise',
                                  color: Color(0xFFA78BFA),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    } else {
                      // Horizontal layout on larger screens
                      return Row(
                        children: const [
                          Expanded(
                            child: _QuickStat(
                              value: 'UV 7',
                              label: 'High',
                              color: Color(0xFFFACC15),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _QuickStat(
                              value: '68%',
                              label: 'Humidity',
                              color: Color(0xFF06B6D4),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _QuickStat(
                              value: '1013',
                              label: 'Pressure (hPa)',
                              color: Color(0xFF10B981),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _QuickStat(
                              value: '6:45',
                              label: 'Sunrise',
                              color: Color(0xFFA78BFA),
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),

                const SizedBox(height: 12),
                const Divider(color: Color(0x1AFFFFFF)),
                const SizedBox(height: 12),

                // Action-Oriented Insight
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0x4D059669),
                        Color(0x4D0D9488),
                      ], // emerald/teal /30
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x3310B981)),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
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
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Perfect conditions for outdoor activities',
                              style: TextStyle(color: Color(0xFF6EE7B7)),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Low rain probability, comfortable temperature, light winds',
                              style: TextStyle(
                                color: Colors.white70,
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
  @override
  Widget build(BuildContext context) {
    final hours = [
      {'time': 'Now', 'temp': '22°', 'icon': '🌤'},
      {'time': '11 AM', 'temp': '23°', 'icon': '☀'},
      {'time': '12 PM', 'temp': '24°', 'icon': '☀'},
      {'time': '1 PM', 'temp': '25°', 'icon': '☀'},
      {'time': '2 PM', 'temp': '25°', 'icon': '🌤'},
      {'time': '3 PM', 'temp': '24°', 'icon': '🌤'},
      {'time': '4 PM', 'temp': '23°', 'icon': '☁'},
      {'time': '5 PM', 'temp': '22°', 'icon': '☁'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hourly Forecast',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
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
                            color: Colors.white60,
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
                          style: const TextStyle(color: Colors.white),
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

// ====== TOMORROW CARD ======

class _TomorrowCard extends StatelessWidget {
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
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tomorrow's Forecast",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '26°',
                          style: TextStyle(color: Colors.white, fontSize: 44),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'C',
                          style: TextStyle(color: Colors.white70, fontSize: 20),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Sunny',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'High: 26° / Low: 19°',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
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
                            color: Colors.white60,
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
                          style: const TextStyle(color: Colors.white),
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
  @override
  Widget build(BuildContext context) {
    final days = [
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
        'day': 'Wednesday',
        'high': '23°',
        'low': '17°',
        'condition': 'Cloudy',
        'icon': '☁',
      },
      {
        'day': 'Thursday',
        'high': '21°',
        'low': '15°',
        'condition': 'Rain',
        'icon': '🌧',
      },
      {
        'day': 'Friday',
        'high': '25°',
        'low': '18°',
        'condition': 'Partly Cloudy',
        'icon': '🌤',
      },
      {
        'day': 'Saturday',
        'high': '27°',
        'low': '20°',
        'condition': 'Sunny',
        'icon': '☀',
      },
      {
        'day': 'Sunday',
        'high': '24°',
        'low': '17°',
        'condition': 'Thunderstorm',
        'icon': '⛈',
      },
      {
        'day': 'Monday',
        'high': '22°',
        'low': '16°',
        'condition': 'Cloudy',
        'icon': '☁',
      },
      {
        'day': 'Tuesday',
        'high': '23°',
        'low': '17°',
        'condition': 'Partly Cloudy',
        'icon': '🌤',
      },
      {
        'day': 'Wednesday',
        'high': '25°',
        'low': '18°',
        'condition': 'Sunny',
        'icon': '☀',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '10-Day Forecast',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Column(
            children: [
              for (int i = 0; i < days.length; i++)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: i == days.length - 1
                            ? const Color(0x00000000)
                            : const Color(0x1AFFFFFF),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        days[i]['icon'] as String,
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              days[i]['day'] as String,
                              style: const TextStyle(color: Colors.white),
                            ),
                            Text(
                              days[i]['condition'] as String,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            days[i]['high'] as String,
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            days[i]['low'] as String,
                            style: const TextStyle(color: Colors.white60),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
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
  const _MiniStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
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
        Text(value, style: TextStyle(color: color, fontSize: 18)),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ],
    );
  }
}


// ====== tiny star painter for hero background ======
class _StarfieldPainterSmall extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xCCFFFFFF);
    final pts = <Offset>[
      Offset(10, 15),
      Offset(30, 35),
      Offset(50, 25),
      Offset(size.width - 30, 40),
      Offset(size.width - 60, 90),
      Offset(size.width * .4, size.height * .3),
      Offset(size.width * .7, size.height * .7),
    ];
    for (final o in pts) {
      canvas.drawCircle(o, 1.0, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}