import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/geocoding_service.dart';
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  String activeLayer = 'temperature';
  bool showSatellite = false;

  // Interactive map state (from Dashboard)
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<PlaceSuggestion> _suggestions = [];
  LatLng _interactiveMapCenter = LatLng(40.7128, -74.0060);
  Marker? _interactiveSelectedMarker;
  final MapController _interactiveMapController = MapController();

  static const _mapLayers = [
    _Layer(id: 'temperature', name: 'Temperature', icon: Icons.thermostat, color: Color(0xFFFACC15)), // Keep yellow for temperature
    _Layer(id: 'precipitation', name: 'Precipitation', icon: Icons.opacity, color: Color(0xFF06B6D4)), // Keep cyan for water
    _Layer(id: 'wind', name: 'Wind Speed', icon: Icons.air, color: Color(0xFF10B981)), // Keep green for wind
    _Layer(id: 'pressure', name: 'Pressure', icon: Icons.bolt, color: Color(0xFF7C6BAD)), // Update to purple theme
  ];

  final List<_Station> _stations = [
    _Station(id: 1, name: 'Central Park',    lat: 40.7829, lng: -73.9654, temp: 22, condition: 'Partly Cloudy', active: true),
    _Station(id: 2, name: 'Brooklyn Bridge', lat: 40.7061, lng: -73.9969, temp: 21, condition: 'Cloudy'),
    _Station(id: 3, name: 'Times Square',    lat: 40.7580, lng: -73.9855, temp: 23, condition: 'Clear'),
    _Station(id: 4, name: 'Staten Island',   lat: 40.5795, lng: -74.1502, temp: 20, condition: 'Light Rain'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ---- Map controls header (with overflow prevention) ----
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 800) {
              // Stack vertically on smaller screens
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: const [
                    Flexible(
                      child: Text('Interactive Weather Map',
                          style: TextStyle(color: Color(0xFF2D2D2D), fontSize: 18, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis),
                    ),
                    SizedBox(width: 10),
                    _Badge(text: 'NASA Data'),
                  ]),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.satellite_alt, color: Color(0xFF6B6B6B), size: 18),
                          const SizedBox(width: 6),
                          const Text('Satellite View',
                              style: TextStyle(color: Color(0xFF6B6B6B), fontSize: 12)),
                          const SizedBox(width: 8),
                          Switch(
                            value: showSatellite,
                            onChanged: (v) => setState(() => showSatellite = v),
                            thumbColor: const WidgetStatePropertyAll(Color(0xFF7C6BAD)),
                            trackColor: const WidgetStatePropertyAll(Color(0xFFE8E4F3)),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.location_pin, size: 18),
                        label: const Text('Add Location'),
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C6BAD),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            } else {
              // Horizontal layout for larger screens
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(children: const [
                      Text('Interactive Weather Map',
                          style: TextStyle(color: Color(0xFF2D2D2D), fontSize: 18, fontWeight: FontWeight.w600)),
                      SizedBox(width: 10),
                      _Badge(text: 'NASA Data'),
                    ]),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.satellite_alt, color: Color(0xFF6B6B6B), size: 18),
                      const SizedBox(width: 6),
                      const Text('Satellite View',
                          style: TextStyle(color: Color(0xFF6B6B6B), fontSize: 12)),
                      const SizedBox(width: 8),
                      Switch(
                        value: showSatellite,
                        onChanged: (v) => setState(() => showSatellite = v),
                        thumbColor: const WidgetStatePropertyAll(Color(0xFF7C6BAD)),
                        trackColor: const WidgetStatePropertyAll(Color(0xFFE8E4F3)),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.location_pin, size: 18),
                        label: const Text('Add Location'),
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C6BAD),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }
          },
        ),

        const SizedBox(height: 16),

        // ---- Grid: Map (3 cols) + Side panel (1 col) (improved responsiveness) ----
        LayoutBuilder(
          builder: (context, c) {
            final isWide = c.maxWidth >= 900; // Reduced threshold for better mobile experience
            final mapWidth = isWide ? (c.maxWidth - 16) * 0.75 : c.maxWidth;
            final sideWidth = isWide ? (c.maxWidth - 16) * 0.25 : c.maxWidth;
            final mapHeight = isWide ? 500.0 : 300.0; // Reduced height on small screens

            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                // Map area
                SizedBox(
                  width: mapWidth,
                  child: _panel(
                    child: SizedBox(
                      height: mapHeight,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Search field
                            TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search location or tap map',
                                prefixIcon: const Icon(Icons.search, color: Color(0xFF7C6BAD)),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
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
                                          _interactiveMapCenter = LatLng(s.lat, s.lon);
                                          _interactiveSelectedMarker = Marker(
                                            point: _interactiveMapCenter,
                                            width: 40,
                                            height: 40,
                                            builder: (ctx) => const Icon(Icons.location_pin, color: Colors.red, size: 40),
                                          );
                                          _suggestions = [];
                                          _searchController.text = s.displayName;
                                        });
                                        try {
                                          _interactiveMapController.move(_interactiveMapCenter, 12.0);
                                        } catch (_) {}
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],

                            const SizedBox(height: 8),
                            // Map
                            Expanded(
                              child: FlutterMap(
                                mapController: _interactiveMapController,
                                options: MapOptions(
                                  center: _interactiveMapCenter,
                                  zoom: 12.0,
                                  onTap: (tap, latlng) async {
                                    if (!mounted) return;
                                    setState(() {
                                      _interactiveMapCenter = latlng;
                                      _interactiveSelectedMarker = Marker(
                                        point: latlng,
                                        width: 40,
                                        height: 40,
                                        builder: (ctx) => const Icon(Icons.location_pin, color: Colors.red, size: 40),
                                      );
                                    });
                                    try {
                                      _interactiveMapController.move(latlng, 12.0);
                                    } catch (_) {}
                                  },
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.example.aeronimbus',
                                  ),
                                  MarkerLayer(markers: [if (_interactiveSelectedMarker != null) _interactiveSelectedMarker!]),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),
                            Text(
                              'Lat: ${_interactiveMapCenter.latitude.toStringAsFixed(5)}, Lon: ${_interactiveMapCenter.longitude.toStringAsFixed(5)}',
                              style: const TextStyle(color: Color(0xFF2D2D2D), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Side panel
                SizedBox(
                  width: sideWidth,
                  child: Column(
                    children: [
                      // Layers
                      _panel(
                        title: Row(
                          children: const [
                            Icon(Icons.layers, size: 18, color: Color(0xFF7C6BAD)),
                            SizedBox(width: 8),
                            Text('Map Layers',
                                style: TextStyle(color: Color(0xFF2D2D2D), fontWeight: FontWeight.w600)),
                          ],
                        ),
                        child: Column(
                          children: _mapLayers.map((layer) {
                            final active = activeLayer == layer.id;
                            return InkWell(
                              onTap: () => setState(() => activeLayer = layer.id),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: active ? const Color(0xFFE8E4F3) : const Color(0xFFF5F3FF),
                                  borderRadius: BorderRadius.circular(10),
                                  border: active ? Border.all(color: const Color(0xFF7C6BAD)) : null,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(children: [
                                      Icon(layer.icon, color: layer.color),
                                      const SizedBox(width: 8),
                                      Text(layer.name,
                                          style: const TextStyle(color: Color(0xFF2D2D2D), fontWeight: FontWeight.w600)),
                                    ]),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: active ? const Color(0xFF7C6BAD) : const Color(0xFFE8E4F3),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Stations
                      _panel(
                        title: const Text('Weather Stations',
                            style: TextStyle(color: Color(0xFF2D2D2D), fontWeight: FontWeight.w600)),
                        child: Column(
                          children: _stations.map((s) {
                            final active = s.active;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: active ? const Color(0xFFE8E4F3) : const Color(0xFFF5F3FF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: active ? const Color(0xFF7C6BAD) : const Color(0xFFE8E4F3),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s.name,
                                          style: const TextStyle(
                                              color: Color(0xFF2D2D2D), fontSize: 13, fontWeight: FontWeight.w600)),
                                      Text(s.condition,
                                          style: const TextStyle(
                                              color: Color(0xFF6B6B6B), fontSize: 11)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('${s.temp}°C',
                                          style: const TextStyle(color: Color(0xFF2D2D2D), fontWeight: FontWeight.w600)),
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(top: 6),
                                        decoration: BoxDecoration(
                                          color: active ? const Color(0xFF7C6BAD) : const Color(0xFFE8E4F3),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Legend
                      _panel(
                        title: const Text('Legend',
                            style: TextStyle(color: Colors.white)),
                        child: _legendFor(activeLayer),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ---- Map overlays ----

  static List<Widget> _temperatureBlobs() => const [
        _Blob(top: 80, left: 80, w: 120, h: 120, color: Color(0x4DFACC15)), // yellow/30
        _Blob(top: 160, right: 160, w: 160, h: 160, color: Color(0x66FB923C)), // orange/40
        _Blob(bottom: 120, left: 120, w: 140, h: 140, color: Color(0x33EF4444)), // red/20
      ];

  static List<Widget> _precipitationBlobs() => const [
        _Blob(top: 140, right: 80, w: 190, h: 190, color: Color(0x3310B981)), // cyan/teal mix
        _Blob(bottom: 140, left: 160, w: 140, h: 140, color: Color(0x4D60A5FA)), // blue/30
      ];

  static List<Widget> _windGlyphs(BuildContext context, double mapHeight) {
    final rand = Random(42);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 900;
    final effectiveWidth = isWide ? screenWidth * 0.7 : screenWidth;
    
    return List.generate(15, (i) { // Reduced count for better performance
      final left = rand.nextDouble();
      final top = rand.nextDouble();
      final rot = rand.nextDouble() * 360;
      return Positioned(
        left: left * effectiveWidth,
        top: top * mapHeight,
        child: Transform.rotate(
          angle: rot * pi / 180,
          child: Container(
            width: 2,
            height: isWide ? 20 : 15, // Smaller on mobile
            color: const Color(0x9910B981),
          ),
        ),
      );
    });
  }

  // Convert station lat/lng to approximate canvas coords (mock mapping for NYC box)
  static Widget _pinForStation(BuildContext context, _Station s, double mapHeight) {
    final leftPct = ((s.lng + 74.2) / 0.4).clamp(0, 1); // ~[-74.2,-73.8]
    final topPct = ((40.9 - s.lat) / 0.4).clamp(0, 1);  // ~[40.5,40.9]
    
    // Responsive positioning based on screen size
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 900;
    final mapWidthFactor = isWide ? 0.7 : 1.0;

    return Positioned(
      left: (leftPct * (screenWidth * mapWidthFactor)).clamp(8.0, screenWidth - 50),
      top: (topPct * (mapHeight - 20)).clamp(8.0, mapHeight - 50),
      child: Transform.translate(
        offset: const Offset(-8, -8),
        child: _StationPin(station: s),
      ),
    );
  }

  // ---- Legend ----
  static Widget _legendFor(String layer) {
    switch (layer) {
      case 'temperature':
        return _legendRows(const [
          _LegendRow(color: Color(0xFFEF4444), label: 'High (25°C+)'),
          _LegendRow(color: Color(0xFFFACC15), label: 'Moderate (15–25°C)'),
          _LegendRow(color: Color(0xFF60A5FA), label: 'Low (Below 15°C)'),
        ]);
      case 'precipitation':
        return _legendRows(const [
          _LegendRow(color: Color(0xFF2563EB), label: 'Heavy Rain'),
          _LegendRow(color: Color(0xFF06B6D4), label: 'Light Rain'),
          _LegendRow(color: Color(0xFF9CA3AF), label: 'No Precipitation'),
        ]);
      case 'wind':
        return _legendRows(const [
          _LegendRow(color: Color(0xFF10B981), label: 'Wind glyphs show direction'),
        ]);
      case 'pressure':
        return _legendRows(const [
          _LegendRow(color: Color(0xFF7C6BAD), label: 'Higher Pressure'),
          _LegendRow(color: Color(0xFF6B7280), label: 'Lower Pressure'),
        ]);
      default:
        return const SizedBox.shrink();
    }
  }

  static Widget _legendRows(List<_LegendRow> rows) {
    return Column(
      children: rows
          .map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: r.color, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text(r.label, style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 12)),
                  ],
                ),
              ))
          .toList(),
    );
  }

  // ---- Small UI building blocks ----
  static Widget _panel({Widget? title, required Widget child}) {
    return Container(
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
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: title,
            ),
          child,
        ],
      ),
    );
  }

  static Widget _chip(String text, {required Color bg, required Color border, required Color fg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(text, style: TextStyle(color: fg, fontSize: 12)),
    );
  }
}

// ---------- painters & small widgets ----------

class _GridPainter extends CustomPainter {
  final double cell;
  const _GridPainter({required this.cell});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x1AFFFFFF)
      ..strokeWidth = 1;

    for (double y = 0; y <= size.height; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = 0; x <= size.width; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => oldDelegate.cell != cell;
}

class _Blob extends StatelessWidget {
  final double? top, left, right, bottom, w, h;
  final Color color;
  const _Blob({
    this.top,
    this.left,
    this.right,
    this.bottom,
    this.w,
    this.h,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8E4F3),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE8E4F3)),
      ),
      child: Text(text, style: const TextStyle(color: Color(0xFF7C6BAD), fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _StationPin extends StatefulWidget {
  final _Station station;
  const _StationPin({required this.station});

  @override
  State<_StationPin> createState() => _StationPinState();
}

class _StationPinState extends State<_StationPin> {
  @override
  Widget build(BuildContext context) {
    final s = widget.station;
    return GestureDetector(
      onTap: () => setState(() {
        s.active = !s.active;
      }),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: s.active ? 10 : 8,
            height: s.active ? 10 : 8,
            decoration: BoxDecoration(
              color: s.active ? const Color(0xFF7C6BAD) : const Color(0xFF6B6B6B),
              shape: BoxShape.circle,
              boxShadow: s.active
                  ? const [BoxShadow(color: Color(0x807C6BAD), blurRadius: 12, spreadRadius: 2)]
                  : null,
            ),
          ),
          if (s.active)
            Positioned(
              top: 16,
              left: -60,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final isSmallScreen = screenWidth < 600;
                  
                  return Container(
                    width: isSmallScreen ? 120 : 140,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          s.name.length > 15 ? '${s.name.substring(0, 15)}...' : s.name, 
                          style: const TextStyle(color: Color(0xFF2D2D2D), fontSize: 12, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 2),
                        const Divider(height: 8, color: Color(0xFFE8E4F3)),
                        Text('${s.temp}°C', style: const TextStyle(color: Color(0xFF7C6BAD), fontWeight: FontWeight.w600)),
                        Text(
                          s.condition, 
                          style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
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

// ---- tiny data classes ----

class _Layer {
  final String id, name;
  final IconData icon;
  final Color color;
  const _Layer({required this.id, required this.name, required this.icon, required this.color});
}

class _Station {
  final int id;
  final String name;
  final double lat, lng;
  final int temp;
  final String condition;
  bool active;
  _Station({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.temp,
    required this.condition,
    this.active = false,
  });
}

class _LegendRow {
  final Color color;
  final String label;
  const _LegendRow({required this.color, required this.label});
}
