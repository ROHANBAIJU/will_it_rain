import 'package:flutter/material.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  // thresholds
  double rain = 25;
  double wind = 30;
  double temp = 35;
  double pollen = 50;
  double aqi = 100;
  double mold = 70;
  bool alertsEnabled = true;

  // current mock conditions
  final _current = const {
    'rain': 15.0,
    'wind': 12.0,
    'temperature': 22.0,
    'pollen': 35.0,
    'aqi': 85.0,
    'mold': 45.0,
  };

  bool _isAlert(double current, double threshold) => current > threshold;

  Icon _statusIcon(double current, double threshold) {
    final alert = _isAlert(current, threshold);
    return Icon(
      alert ? Icons.cancel : Icons.check_circle,
      color: alert ? const Color(0xFFDC2626) : const Color(0xFF7C6BAD),
      size: 20,
    );
  }

  String _statusText(double current, double threshold) =>
      _isAlert(current, threshold) ? 'Alert Triggered' : 'All Clear';

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
          // ---- Overview ----
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 500) {
                  // Stack vertically on small screens
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle, color: Color(0xFF7C6BAD), size: 28),
                          SizedBox(width: 10),
                          Expanded(
                            child: _TitleBlock(
                              title: 'Health & Weather Status: All Clear',
                              subtitle:
                                  'All weather and health conditions within your defined thresholds',
                              reason:
                                  'Clear skies and high pressure system reducing allergen dispersion',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Icon(Icons.notifications_active,
                              color: Color(0xFF7C6BAD), size: 18),
                          const SizedBox(width: 8),
                          Switch(
                            value: alertsEnabled,
                            onChanged: (v) => setState(() => alertsEnabled = v),
                            thumbColor:
                                const WidgetStatePropertyAll(Color(0xFF7C6BAD)),
                            trackColor:
                                const WidgetStatePropertyAll(Color(0xFFE8E4F3)),
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
                      const Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Color(0xFF7C6BAD), size: 28),
                            SizedBox(width: 10),
                            Expanded(
                              child: _TitleBlock(
                                title: 'Health & Weather Status: All Clear',
                                subtitle:
                                    'All weather and health conditions within your defined thresholds',
                                reason:
                                    'Clear skies and high pressure system reducing allergen dispersion',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.notifications_active,
                              color: Color(0xFF7C6BAD), size: 18),
                          const SizedBox(width: 8),
                          Switch(
                            value: alertsEnabled,
                            onChanged: (v) => setState(() => alertsEnabled = v),
                            thumbColor:
                                const WidgetStatePropertyAll(Color(0xFF7C6BAD)),
                            trackColor:
                                const WidgetStatePropertyAll(Color(0xFFE8E4F3)),
                          ),
                        ],
                      ),
                    ],
                  );
                }
              },
            ),
          ),

          const SizedBox(height: 16),

          // ---- Weather Conditions ----
          const Text('Weather Conditions',
              style: TextStyle(color: Color(0xFF2D2D2D), fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _grid3(children: [
            _thresholdCard(
              icon: Icons.grain, // raindrops alt
              iconColor: const Color(0xFF7C6BAD),
              title: 'Rain Probability',
              thresholdLabel: '${rain.toInt()}%',
              slider: Slider(
                value: rain,
                min: 0,
                max: 100,
                divisions: 20,
                label: '${rain.toInt()}%',
                onChanged: (v) => setState(() => rain = v),
              ),
              statusLeft: 'Current: ${_current['rain']!.toInt()}%',
              statusRight: _statusText(_current['rain']!, rain),
              statusIcon: _statusIcon(_current['rain']!, rain),
            ),
            _thresholdCard(
              icon: Icons.air,
              iconColor: const Color(0xFF7C6BAD),
              title: 'Wind Speed',
              thresholdLabel: '${wind.toInt()} km/h',
              slider: Slider(
                value: wind,
                min: 0,
                max: 100,
                divisions: 20,
                label: '${wind.toInt()} km/h',
                onChanged: (v) => setState(() => wind = v),
              ),
              statusLeft: 'Current: ${_current['wind']!.toInt()} km/h',
              statusRight: _statusText(_current['wind']!, wind),
              statusIcon: _statusIcon(_current['wind']!, wind),
            ),
            _thresholdCard(
              icon: Icons.thermostat,
              iconColor: const Color(0xFF7C6BAD),
              title: 'Temperature',
              thresholdLabel: '${temp.toInt()}°C',
              slider: Slider(
                value: temp,
                min: 10,
                max: 50,
                divisions: 40,
                label: '${temp.toInt()}°C',
                onChanged: (v) => setState(() => temp = v),
              ),
              statusLeft: 'Current: ${_current['temperature']!.toInt()}°C',
              statusRight: _statusText(_current['temperature']!, temp),
              statusIcon: _statusIcon(_current['temperature']!, temp),
            ),
          ]),

          const SizedBox(height: 16),

          // ---- Health & Allergy Triggers ----
          const Text('Health & Allergy Triggers',
              style: TextStyle(color: Color(0xFF2D2D2D), fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _grid3(children: [
            _thresholdCard(
              icon: Icons.local_florist,
              iconColor: const Color(0xFF7C6BAD),
              title: 'Pollen Count',
              thresholdLabel: '${pollen.toInt()} grains/m³',
              slider: Slider(
                value: pollen,
                min: 0,
                max: 200,
                divisions: 20,
                label: '${pollen.toInt()}',
                onChanged: (v) => setState(() => pollen = v),
              ),
              statusLeft:
                  'Current: ${_current['pollen']!.toInt()} grains/m³',
              statusRight: _statusText(_current['pollen']!, pollen),
              statusIcon: _statusIcon(_current['pollen']!, pollen),
            ),
            _thresholdCard(
              icon: Icons.eco,
              iconColor: const Color(0xFF7C6BAD),
              title: 'Air Quality (AQI)',
              thresholdLabel: 'AQI ${aqi.toInt()}',
              slider: Slider(
                value: aqi,
                min: 0,
                max: 300,
                divisions: 30,
                label: 'AQI ${aqi.toInt()}',
                onChanged: (v) => setState(() => aqi = v),
              ),
              statusLeft: 'Current: AQI ${_current['aqi']!.toInt()}',
              statusRight: _statusText(_current['aqi']!, aqi),
              statusIcon: _statusIcon(_current['aqi']!, aqi),
            ),
            _thresholdCard(
              icon: Icons.biotech,
              iconColor: const Color(0xFF7C6BAD),
              title: 'Mold Risk',
              thresholdLabel: '${mold.toInt()}% Risk',
              slider: Slider(
                value: mold,
                min: 0,
                max: 100,
                divisions: 20,
                label: '${mold.toInt()}%',
                onChanged: (v) => setState(() => mold = v),
              ),
              statusLeft: 'Current: ${_current['mold']!.toInt()}% Risk',
              statusRight: _statusText(_current['mold']!, mold),
              statusIcon: _statusIcon(_current['mold']!, mold),
            ),
          ]),

          const SizedBox(height: 16),

          // ---- Recent Alerts ----
          _panel(
            title: 'Recent Health & Weather Alerts',
            child: Column(
              children: [
                _alertRow(
                  bg: const Color(0xFFFFF8E7),
                  border: const Color(0xFFFFE4A3),
                  icon: Icons.local_florist,
                  iconColor: const Color(0xFFFACC15),
                  title: 'Pollen Alert: Tree Pollen High',
                  time: '1 hour ago • Tree pollen reached 65 grains/m³',
                  reason:
                      'Warm, dry conditions increasing birch and oak pollen release',
                  badgeText: 'Active',
                  badgeColor: const Color(0xFFFFE4A3),
                  badgeTextColor: const Color(0xFFD97706),
                  badgeBorder: const Color(0xFFFFD96B),
                ),
                const SizedBox(height: 8),
                _alertRow(
                  bg: const Color(0xFFF5F3FF),
                  border: const Color(0xFFE8E4F3),
                  icon: Icons.eco,
                  iconColor: const Color(0xFF7C6BAD),
                  title: 'Air Quality Good',
                  time: '30 min ago • AQI dropped to 75',
                  reason: 'Light winds dispersing urban pollutants effectively',
                  badgeText: 'Clear',
                  badgeColor: const Color(0xFFE8E4F3),
                  badgeTextColor: const Color(0xFF7C6BAD),
                  badgeBorder: const Color(0xFFD1CBE8),
                ),
                const SizedBox(height: 8),
                _alertRow(
                  bg: const Color(0xFFF5F3FF),
                  border: const Color(0xFFE8E4F3),
                  icon: Icons.biotech,
                  iconColor: const Color(0xFF7C6BAD),
                  title: 'Mold Risk Elevated',
                  time: 'Yesterday • Mold risk reached 75%',
                  reason:
                      'High humidity and warm temperatures favoring mold spore growth',
                  badgeText: 'Past',
                  badgeColor: const Color(0xFFE8E4F3),
                  badgeTextColor: const Color(0xFF9B8BC6),
                  badgeBorder: const Color(0xFFD1CBE8),
                ),
                const SizedBox(height: 8),
                _alertRow(
                  bg: const Color(0xFFFEE2E2),
                  border: const Color(0xFFFCA5A5),
                  icon: Icons.grain,
                  iconColor: const Color(0xFF7C6BAD),
                  title: 'Rain Alert Triggered',
                  time: '2 days ago • 85% chance of rain detected',
                  reason:
                      'Low pressure system moving in from the west bringing moisture',
                  badgeText: 'Past',
                  badgeColor: const Color(0xFFFCA5A5),
                  badgeTextColor: const Color(0xFFDC2626),
                  badgeBorder: const Color(0xFFF87171),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ---- Actions (with overflow prevention) ----
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 400) {
                // Stack buttons vertically on small screens
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C6BAD),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {},
                      child: const Text('Test All Alerts'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE8E4F3)),
                        foregroundColor: const Color(0xFF7C6BAD),
                      ),
                      child: const Text('Export Alert History'),
                    ),
                  ],
                );
              } else {
                // Use Row for larger screens
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
                      child: const Text('Test All Alerts'),
                    ),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE8E4F3)),
                        foregroundColor: const Color(0xFF7C6BAD),
                      ),
                      child: const Text('Export Alert History'),
                    ),
                  ],
                );
              }
            },
          ),
      ],
    );
  }

  // ---------- small UI helpers ----------

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

  static Widget _grid3({required List<Widget> children}) {
    // Responsive grid that adapts to screen size
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final isMediumScreen = constraints.maxWidth < 900;
        
        if (isSmallScreen) {
          // Single column on small screens
          return Column(
            children: children,
          );
        } else if (isMediumScreen) {
          // Two columns on medium screens
          return Column(
            children: [
              for (int i = 0; i < children.length; i += 2)
                Row(
                  children: [
                    Expanded(child: children[i]),
                    if (i + 1 < children.length) ...[
                      const SizedBox(width: 16),
                      Expanded(child: children[i + 1]),
                    ],
                  ],
                ),
              if (children.length % 2 == 1) const SizedBox(height: 16),
            ],
          );
        } else {
          // Three columns on large screens
          return Column(
            children: [
              for (int i = 0; i < children.length; i += 3)
                Row(
                  children: [
                    Expanded(child: children[i]),
                    if (i + 1 < children.length) ...[
                      const SizedBox(width: 16),
                      Expanded(child: children[i + 1]),
                    ],
                    if (i + 2 < children.length) ...[
                      const SizedBox(width: 16),
                      Expanded(child: children[i + 2]),
                    ],
                  ],
                ),
              if (children.length % 3 != 0) const SizedBox(height: 16),
            ],
          );
        }
      },
    );
  }

  Widget _thresholdCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String thresholdLabel,
    required Widget slider,
    required String statusLeft,
    required String statusRight,
    required Icon statusIcon,
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
          // Header with icon and title - ensure no overflow
          Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title, 
                  style: const TextStyle(color: Color(0xFF2D2D2D), fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Threshold row with proper spacing
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Threshold',
                  style: TextStyle(color: Color(0xFF6B6B6B), fontSize: 12)),
              Flexible(
                child: Text(
                  thresholdLabel,
                  style: TextStyle(color: iconColor, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          // Slider with proper constraints
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              activeTrackColor: const Color(0xFF7C6BAD),
              inactiveTrackColor: const Color(0xFFE8E4F3),
              thumbColor: const Color(0xFF7C6BAD),
            ),
            child: slider,
          ),
          // Status container with improved responsive layout
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(10),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 200) {
                  // Stack vertically on very narrow cards
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(statusLeft,
                          style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 12),
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(statusRight,
                                style: const TextStyle(color: Color(0xFF9B9B9B), fontSize: 10),
                                overflow: TextOverflow.ellipsis),
                          ),
                          statusIcon,
                        ],
                      ),
                    ],
                  );
                } else {
                  // Horizontal layout for normal width
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(statusLeft,
                                style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 13),
                                overflow: TextOverflow.ellipsis),
                            Text(statusRight,
                                style: const TextStyle(color: Color(0xFF9B9B9B), fontSize: 11),
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      statusIcon,
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  final String title, subtitle, reason;
  const _TitleBlock({
    required this.title,
    required this.subtitle,
    required this.reason,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: Color(0xFF2D2D2D),
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        const Text('All weather and health conditions within your defined thresholds',
            style: TextStyle(color: Color(0xFF6B6B6B), fontSize: 12)),
        const SizedBox(height: 4),
        Text(reason, style: const TextStyle(color: Color(0xFF7C6BAD), fontSize: 11)),
      ],
    );
  }
}

// ---- Alert row (top-level helper) ----
Widget _alertRow({
  required Color bg,
  required Color border,
  required IconData icon,
  required Color iconColor,
  required String title,
  required String time,
  required String reason,
  required String badgeText,
  required Color badgeColor,
  required Color badgeTextColor,
  required Color badgeBorder,
}) {
  return Container(
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: border),
    ),
    padding: const EdgeInsets.all(12),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 400;
        
        if (isSmallScreen) {
          // Stack vertically on small screens
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(title, style: const TextStyle(color: Color(0xFF2D2D2D), fontWeight: FontWeight.w600)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: badgeBorder),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeTextColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(time,
                  style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                reason,
                style: TextStyle(
                  color: iconColor.withAlpha(204), // ~0.8 opacity
                  fontSize: 11,
                ),
              ),
            ],
          );
        } else {
          // Horizontal layout on larger screens
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(icon, color: iconColor, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(color: Color(0xFF2D2D2D), fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(time,
                              style: const TextStyle(color: Color(0xFF6B6B6B), fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(
                            reason,
                            style: TextStyle(
                              color: iconColor.withAlpha(204), // ~0.8 opacity
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: badgeBorder),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeTextColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          );
        }
      },
    ),
  );
}
