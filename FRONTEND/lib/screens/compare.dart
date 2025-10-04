import 'package:flutter/material.dart';

class ComparePage extends StatefulWidget {
  const ComparePage({super.key});

  @override
  State<ComparePage> createState() => _ComparePageState();
}

class _ComparePageState extends State<ComparePage> {
  String comparisonType = 'locations';
  bool isDetailedOpen = true;
  bool isForecastOpen = true;

  final TextEditingController _locA =
      TextEditingController(text: 'New York, NY');
  final TextEditingController _locB =
      TextEditingController(text: 'Los Angeles, CA');

  // Mock data ported from TSX
  final location1 = _CityData(
    name: 'New York, NY',
    current: _Current(temp: 22, condition: 'Partly Cloudy', humidity: 68, wind: 12, pressure: 1013),
    forecast: const [
      _ForecastRow(day: 'Today', high: 24, low: 18, condition: 'Partly Cloudy', rain: 15),
      _ForecastRow(day: 'Tomorrow', high: 26, low: 19, condition: 'Sunny', rain: 5),
      _ForecastRow(day: 'Wed', high: 23, low: 17, condition: 'Cloudy', rain: 30),
    ],
  );

  final location2 = _CityData(
    name: 'Los Angeles, CA',
    current: _Current(temp: 28, condition: 'Sunny', humidity: 45, wind: 8, pressure: 1018),
    forecast: const [
      _ForecastRow(day: 'Today', high: 29, low: 21, condition: 'Sunny', rain: 0),
      _ForecastRow(day: 'Tomorrow', high: 31, low: 22, condition: 'Sunny', rain: 0),
      _ForecastRow(day: 'Wed', high: 30, low: 23, condition: 'Clear', rain: 0),
    ],
  );

  @override
  void dispose() {
    _locA.dispose();
    _locB.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ---- Comparison Type + Inputs ----
        _panel(
          title: 'Weather Comparison',
          child: Column(
            children: [
              // Top controls with responsive layout
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 500) {
                    // Stack vertically on small screens
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F3FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE8E4F3)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: comparisonType,
                              dropdownColor: Colors.white,
                              style: const TextStyle(color: Color(0xFF2D2D2D)),
                              isExpanded: true, // Prevent overflow
                              items: const [
                                DropdownMenuItem(
                                  value: 'locations',
                                  child: Text('Compare Locations'),
                                ),
                                DropdownMenuItem(
                                  value: 'dates',
                                  child: Text('Compare Dates'),
                                ),
                                DropdownMenuItem(
                                  value: 'times',
                                  child: Text('Compare Times'),
                                ),
                              ],
                              onChanged: (v) => setState(() => comparisonType = v ?? 'locations'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C6BAD),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {},
                          child: const Text('Generate Report'),
                        ),
                      ],
                    );
                  } else {
                    // Horizontal layout for larger screens
                    return Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F3FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE8E4F3)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: comparisonType,
                                dropdownColor: Colors.white,
                                style: const TextStyle(color: Color(0xFF2D2D2D)),
                                isExpanded: true, // Prevent overflow
                                items: const [
                                  DropdownMenuItem(
                                    value: 'locations',
                                    child: Text('Compare Locations'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'dates',
                                    child: Text('Compare Dates'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'times',
                                    child: Text('Compare Times'),
                                  ),
                                ],
                                onChanged: (v) => setState(() => comparisonType = v ?? 'locations'),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C6BAD),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {},
                          child: const Text('Generate Report'),
                        ),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 720;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                        child: _textFieldWithLabel(
                          icon: Icons.location_pin,
                          iconColor: const Color(0xFF7C6BAD),
                          label: 'Location A',
                          controller: _locA,
                          hint: 'Enter location...',
                        ),
                      ),
                      SizedBox(
                        width: isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                        child: _textFieldWithLabel(
                          icon: Icons.location_pin,
                          iconColor: const Color(0xFF9B8AC4),
                          label: 'Location B',
                          controller: _locB,
                          hint: 'Enter location...',
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ---- Current Conditions comparison (two cards) ----
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 720;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                  child: _currentCard(
                    city: location1,
                    badgeText: 'Location A',
                    badgeBg: const Color(0xFFE8E4F3),
                    badgeFg: const Color(0xFF7C6BAD),
                    border: const Color(0xFFE8E4F3),
                    gradient: const [],
                  ),
                ),
                SizedBox(
                  width: isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
                  child: _currentCard(
                    city: location2,
                    badgeText: 'Location B',
                    badgeBg: const Color(0xFFE8E4F3),
                    badgeFg: const Color(0xFF9B8AC4),
                    border: const Color(0xFFE8E4F3),
                    gradient: const [],
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 16),

        // ---- Detailed Comparison (collapsible) ----
        _collapsible(
          isOpen: isDetailedOpen,
          onToggle: () => setState(() => isDetailedOpen = !isDetailedOpen),
          title: 'Detailed Comparison',
          child: Column(
            children: [
              _metricRow(
                label: 'Temperature',
                v1: location1.current.temp.toDouble(),
                v2: location2.current.temp.toDouble(),
                unit: '°C',
                higherIsBetter: false,
              ),
              const SizedBox(height: 8),
              _metricRow(
                label: 'Humidity',
                v1: location1.current.humidity.toDouble(),
                v2: location2.current.humidity.toDouble(),
                unit: '%',
                higherIsBetter: false,
              ),
              const SizedBox(height: 8),
              _metricRow(
                label: 'Wind Speed',
                v1: location1.current.wind.toDouble(),
                v2: location2.current.wind.toDouble(),
                unit: ' km/h',
                higherIsBetter: false,
              ),
              const SizedBox(height: 8),
              _metricRow(
                label: 'Pressure',
                v1: location1.current.pressure.toDouble(),
                v2: location2.current.pressure.toDouble(),
                unit: ' hPa',
                higherIsBetter: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ---- 3-Day Forecast Comparison (collapsible) ----
        _collapsible(
          isOpen: isForecastOpen,
          onToggle: () => setState(() => isForecastOpen = !isForecastOpen),
          title: '3-Day Forecast Comparison',
          child: Column(
            children: List.generate(location1.forecast.length, (i) {
              final a = location1.forecast[i];
              final b = location2.forecast[i];
              return Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 600) {
                          // Stack vertically on small screens
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(a.day, style: const TextStyle(color: Color(0xFF2D2D2D), fontWeight: FontWeight.w600)),
                                  Text('${a.rain}% vs ${b.rain}% rain',
                                      style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Column(
                                children: [
                                  _forecastSide(
                                    name: location1.name,
                                    high: a.high,
                                    low: a.low,
                                    condition: a.condition,
                                    nameColor: const Color(0xFF7C6BAD),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text('vs', style: TextStyle(color: Color(0xFF6B6B6B))),
                                  const SizedBox(height: 8),
                                  _forecastSide(
                                    name: location2.name,
                                    high: b.high,
                                    low: b.low,
                                    condition: b.condition,
                                    nameColor: const Color(0xFF9B8AC4),
                                  ),
                                ],
                              ),
                            ],
                          );
                        } else {
                          // Horizontal layout for larger screens
                          return Row(
                            children: [
                              SizedBox(
                                width: 72,
                                child: Text(a.day,
                                    style: const TextStyle(color: Color(0xFF2D2D2D), fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: _forecastSide(
                                        name: location1.name,
                                        high: a.high,
                                        low: a.low,
                                        condition: a.condition,
                                        nameColor: const Color(0xFF7C6BAD),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    const Text('vs',
                                        style: TextStyle(color: Color(0xFF6B6B6B))),
                                    const SizedBox(width: 16),
                                    Flexible(
                                      child: _forecastSide(
                                        name: location2.name,
                                        high: b.high,
                                        low: b.low,
                                        condition: b.condition,
                                        nameColor: const Color(0xFF9B8AC4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Rain Chance',
                                      style: TextStyle(
                                          color: Color(0xFF6B6B6B), fontSize: 12)),
                                  Text('${a.rain}% vs ${b.rain}%',
                                      style: const TextStyle(color: Color(0xFF2D2D2D), fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                  if (i != location1.forecast.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(color: Color(0xFFE8E4F3)),
                    ),
                ],
              );
            }),
          ),
        ),

        const SizedBox(height: 16),

        // ---- Export buttons (with overflow prevention) ----
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              // Stack buttons vertically on smaller screens
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C6BAD),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {},
                    child: const Text('Export as CSV'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9B8AC4),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {},
                    child: const Text('Export as PNG'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE8E4F3)),
                      foregroundColor: const Color(0xFF7C6BAD),
                    ),
                    child: const Text('Share Comparison'),
                  ),
                ],
              );
            } else {
              // Use Wrap for larger screens to handle overflow gracefully
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C6BAD),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {},
                    child: const Text('Export as CSV'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9B8AC4),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {},
                    child: const Text('Export as PNG'),
                  ),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE8E4F3)),
                      foregroundColor: const Color(0xFF7C6BAD),
                    ),
                    child: const Text('Share Comparison'),
                  ),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  // ---- UI helpers ----

  static Widget _panel({required String title, required Widget child}) {
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Color(0xFF2D2D2D),
                  fontWeight: FontWeight.w600,
                  fontSize: 16)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  static Widget _textFieldWithLabel({
    required IconData icon,
    required Color iconColor,
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Color(0xFF6B6B6B))),
        ]),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(color: Color(0xFF2D2D2D)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9B9B9B)),
            filled: true,
            fillColor: const Color(0xFFF5F3FF),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE8E4F3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF7C6BAD), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _currentCard({
    required _CityData city,
    required String badgeText,
    required List<Color> gradient,
    required Color border,
    required Color badgeBg,
    required Color badgeFg,
  }) {
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
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(city.name,
                    style: const TextStyle(color: Color(0xFF2D2D2D), fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              _badge(badgeText, bg: badgeBg, fg: badgeFg, border: border),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              Text('${city.current.temp}°C',
                  style: const TextStyle(color: Color(0xFF2D2D2D), fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(city.current.condition,
                  style: const TextStyle(color: Color(0xFF6B6B6B))),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, c) {
            return Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                _kv('Humidity', '${city.current.humidity}%'),
                _kv('Wind', '${city.current.wind} km/h'),
                _kv('Pressure', '${city.current.pressure} hPa'),
                _kv('Rain Chance', '${city.forecast.first.rain}%'),
              ],
            );
          }),
        ],
      ),
    );
  }

  static Widget _kv(String k, String v) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(k, style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 12)),
          const SizedBox(height: 2),
          Text(v, style: const TextStyle(color: Color(0xFF2D2D2D), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  static Widget _badge(String text, {required Color bg, required Color fg, required Color border}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(text,
          style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }

  Widget _collapsible({
    required bool isOpen,
    required VoidCallback onToggle,
    required String title,
    required Widget child,
  }) {
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
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            color: Color(0xFF2D2D2D), fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.expand_more, color: Color(0xFF7C6BAD), size: 18),
                  ),
                ],
              ),
            ),
          ),
          if (isOpen)
            Divider(height: 1, color: const Color(0xFFE8E4F3)),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: child,
            ),
            crossFadeState:
                isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }

  Widget _metricRow({
    required String label,
    required double v1,
    required double v2,
    required String unit,
    required bool higherIsBetter,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, c) {
          final narrow = c.maxWidth < 360;
          if (narrow) {
            // Stack values below label to avoid right-side overflow on small screens
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFF2D2D2D), fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Text(
                              '${v1.toStringAsFixed(v1 % 1 == 0 ? 0 : 1)}$unit',
                              style: const TextStyle(color: Color(0xFF7C6BAD), fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _trendIcon(v1, v2, higherIsBetter),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('vs', style: TextStyle(color: Color(0xFF6B6B6B))),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _trendIcon(v2, v1, higherIsBetter),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${v2.toStringAsFixed(v2 % 1 == 0 ? 0 : 1)}$unit',
                              style: const TextStyle(color: Color(0xFF9B8AC4), fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          // Wide layout: keep row but constrain text to avoid overflow
          return Row(
            children: [
              Expanded(
                child: Text(label, style: const TextStyle(color: Color(0xFF2D2D2D), fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              '${v1.toStringAsFixed(v1 % 1 == 0 ? 0 : 1)}$unit',
                              style: const TextStyle(color: Color(0xFF7C6BAD), fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _trendIcon(v1, v2, higherIsBetter),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text('vs', style: TextStyle(color: Color(0xFF6B6B6B))),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Row(
                        children: [
                          _trendIcon(v2, v1, higherIsBetter),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${v2.toStringAsFixed(v2 % 1 == 0 ? 0 : 1)}$unit',
                              style: const TextStyle(color: Color(0xFF9B8AC4), fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Icon _trendIcon(double a, double b, bool higherIsBetter) {
    if (a == b) {
      return const Icon(Icons.remove, color: Color(0xFF6B6B6B), size: 18);
    }
    final firstWins = higherIsBetter ? a > b : a < b;
    return Icon(
      firstWins ? Icons.trending_up : Icons.trending_down,
      color: firstWins ? const Color(0xFF7C6BAD) : const Color(0xFFDC2626),
      size: 18,
    );
  }

  static Widget _forecastSide({
    required String name,
    required int high,
    required int low,
    required String condition,
    required Color nameColor,
  }) {
    return Column(
      children: [
        Text(
          name.length > 12 ? '${name.substring(0, 12)}...' : name, 
          style: TextStyle(color: nameColor, fontSize: 12, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '$high° / $low°', 
          style: const TextStyle(color: Color(0xFF2D2D2D), fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          condition, 
          style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 12),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ],
    );
  }
}

// ---- data models (simple) ----
class _CityData {
  final String name;
  final _Current current;
  final List<_ForecastRow> forecast;
  _CityData({required this.name, required this.current, required this.forecast});
}

class _Current {
  final int temp, humidity, wind, pressure;
  final String condition;
  _Current({
    required this.temp,
    required this.condition,
    required this.humidity,
    required this.wind,
    required this.pressure,
  });
}

class _ForecastRow {
  final String day, condition;
  final int high, low, rain;
  const _ForecastRow({
    required this.day,
    required this.high,
    required this.low,
    required this.condition,
    required this.rain,
  });
}
