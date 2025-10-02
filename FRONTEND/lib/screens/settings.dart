import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  // toggles
  bool notifications = true;
  bool weatherUpdates = true;
  bool healthAlerts = true;

  // slider
  double updateFrequency = 3;

  // simple unit state (no backend yet)
  String tempUnit = 'C';
  String windUnit = 'km/h';

  late final TabController _tab;

  final List<_DataSource> dataSources = const [
    _DataSource(
      name: 'NASA MODIS Terra/Aqua',
      type: 'Satellite Imagery',
      description: 'High-resolution atmospheric and surface observations',
      lastUpdate: '2024-09-30 14:30 UTC',
      coverage: 'Global',
      resolution: '1km',
      url: 'https://modis.gsfc.nasa.gov/',
      status: 'Active',
    ),
    _DataSource(
      name: 'NASA GPM IMERG',
      type: 'Precipitation',
      description: 'Global Precipitation Measurement mission data',
      lastUpdate: '2024-09-30 12:00 UTC',
      coverage: '60°S-60°N',
      resolution: '0.1°',
      url: 'https://gpm.nasa.gov/',
      status: 'Active',
    ),
    _DataSource(
      name: 'EPA AirNow',
      type: 'Air Quality',
      description: 'Real-time air quality index and pollutant data',
      lastUpdate: '2024-09-30 16:00 UTC',
      coverage: 'US & Canada',
      resolution: 'City-level',
      url: 'https://www.airnow.gov/',
      status: 'Active',
    ),
    _DataSource(
      name: 'NAB Pollen Network',
      type: 'Pollen Data',
      description: 'National Allergy Bureau pollen count monitoring',
      lastUpdate: '2024-09-30 09:00 UTC',
      coverage: 'North America',
      resolution: 'Regional',
      url: 'https://www.aaaai.org/',
      status: 'Active',
    ),
  ];

  final List<_Metric> dataMetrics = const [
    _Metric(label: 'Total Data Points', value: '2.4M', change: '+12% today'),
    _Metric(label: 'Update Frequency', value: 'Every 3hrs', change: 'Real-time'),
    _Metric(label: 'Data Accuracy', value: '98.7%', change: '+0.3% this week'),
    _Metric(label: 'Coverage Area', value: 'Global', change: '100% operational'),
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ---------- Header ----------
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x4DA78BFA)),
            gradient: const LinearGradient(
              colors: [Color(0x334C1D95), Color(0x33312E81)], // purple/indigo /20
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0x334C1D95),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.settings, color: Color(0xFFA78BFA)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Settings & Data Management',
                        style: TextStyle(color: Colors.white, fontSize: 18)),
                    SizedBox(height: 2),
                    Text(
                      'Configure your AeroNimbus experience and view data sources',
                      style: TextStyle(color: Color(0xFFDDD6FE)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ---------- Tabs ----------
        Container(
          decoration: BoxDecoration(
            color: const Color(0x0DFFFFFF), // 5%
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x1AFFFFFF)), // 10%
          ),
          child: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Color(0x0DFFFFFF),
                  border: Border(
                    bottom: BorderSide(color: Color(0x1AFFFFFF)),
                  ),
                ),
                child: TabBar(
                  controller: _tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xB3FFFFFF),
                  indicatorColor: const Color(0xFFFACC15),
                  tabs: const [
                    Tab(text: 'Preferences'),
                    Tab(text: 'Notifications'),
                    Tab(text: 'Data Sources'),
                    Tab(text: 'Privacy'),
                  ],
                ),
              ),
              SizedBox(
                height: 900, // enough to render all lists; ListView wrapper scrolls
                child: TabBarView(
                  controller: _tab,
                  children: [
                    _preferencesTab(),
                    _notificationsTab(),
                    _dataTab(),
                    _privacyTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------- Tab: Preferences ----------
  Widget _preferencesTab() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: _panel(
        title: const Text('General Preferences',
            style: TextStyle(color: Colors.white)),
        child: Column(
          children: [
            _rowSetting(
              label: 'Temperature Unit',
              description: 'Choose between Celsius and Fahrenheit',
              trailing: Row(
                children: [
                  _pillButton('°C', active: tempUnit == 'C', onTap: () {
                    setState(() => tempUnit = 'C');
                  }, activeColor: const Color(0xFFEAB308)),
                  const SizedBox(width: 8),
                  _pillOutline('°F', active: tempUnit == 'F', onTap: () {
                    setState(() => tempUnit = 'F');
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _rowSetting(
              label: 'Wind Speed Unit',
              description: 'Display wind speed in your preferred unit',
              trailing: Row(
                children: [
                  _pillButton('km/h', active: windUnit == 'km/h', onTap: () {
                    setState(() => windUnit = 'km/h');
                  }, activeColor: const Color(0xFF06B6D4)),
                  const SizedBox(width: 8),
                  _pillOutline('mph', active: windUnit == 'mph', onTap: () {
                    setState(() => windUnit = 'mph');
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Data Update Frequency',
                    style: TextStyle(color: Colors.white)),
                const SizedBox(height: 6),
                Text('Every ${updateFrequency.toInt()} hours',
                    style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),
                Slider(
                  value: updateFrequency,
                  min: 1,
                  max: 12,
                  divisions: 11,
                  label: '${updateFrequency.toInt()}h',
                  onChanged: (v) => setState(() => updateFrequency = v),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Tab: Notifications ----------
  Widget _notificationsTab() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: _panel(
        title: const Text('Notification Settings',
            style: TextStyle(color: Colors.white)),
        child: Column(
          children: [
            _switchRow(
              title: 'Push Notifications',
              subtitle: 'Receive alerts on your device',
              value: notifications,
              onChanged: (v) => setState(() => notifications = v),
            ),
            const SizedBox(height: 12),
            _switchRow(
              title: 'Weather Updates',
              subtitle: 'Get notified of significant weather changes',
              value: weatherUpdates,
              onChanged: (v) => setState(() => weatherUpdates = v),
            ),
            const SizedBox(height: 12),
            _switchRow(
              title: 'Health & Allergy Alerts',
              subtitle: 'Receive pollen, AQI, and mold risk notifications',
              value: healthAlerts,
              onChanged: (v) => setState(() => healthAlerts = v),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Tab: Data ----------
  Widget _dataTab() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // Metrics
          LayoutBuilder(
            builder: (context, c) {
              final isWide = c.maxWidth >= 900;
              final w = isWide ? (c.maxWidth - 12 * 3) / 4 : c.maxWidth;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: dataMetrics
                    .map((m) => SizedBox(
                          width: w,
                          child: _metricCard(m),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 16),

          // Data sources list
          _panel(
            title: Row(
              children: const [
                Icon(Icons.storage, color: Colors.white70, size: 18),
                SizedBox(width: 8),
                Text('Data Sources & Transparency',
                    style: TextStyle(color: Colors.white)),
              ],
            ),
            child: Column(
              children: dataSources
                  .map((s) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0x0DFFFFFF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0x1AFFFFFF)),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 600) {
                              // Stack vertically on small screens
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header row with icon and name
                                  Row(
                                    children: [
                                      const Icon(Icons.satellite_alt,
                                          color: Color(0xFF06B6D4), size: 18),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(s.name,
                                            style: const TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Badges row
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      _badge(s.type,
                                          bg: const Color(0x3348BB78),
                                          fg: const Color(0xFF6EE7B7),
                                          border: const Color(0x4D10B981)),
                                      _badge(s.status,
                                          bg: const Color(0x33A78BFA),
                                          fg: const Color(0xFFA78BFA),
                                          border: const Color(0x4DA78BFA)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Description
                                  Text(s.description,
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 13)),
                                  const SizedBox(height: 8),
                                  // Metadata
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 6,
                                    children: [
                                      _kv('Coverage', s.coverage),
                                      _kv('Resolution', s.resolution),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time,
                                          size: 14, color: Colors.white60),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text('Updated: ${s.lastUpdate}',
                                            style: const TextStyle(
                                                color: Colors.white60,
                                                fontSize: 12),
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () {},
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Color(0x33FFFFFF)),
                                        foregroundColor: Colors.white,
                                      ),
                                      icon: const Icon(Icons.open_in_new, size: 16),
                                      label: const Text('View Source'),
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              // Horizontal layout for larger screens
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.satellite_alt,
                                      color: Color(0xFF06B6D4), size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(s.name,
                                                  style: const TextStyle(
                                                      color: Colors.white)),
                                            ),
                                            _badge(s.type,
                                                bg: const Color(0x3348BB78),
                                                fg: const Color(0xFF6EE7B7),
                                                border: const Color(0x4D10B981)),
                                            const SizedBox(width: 6),
                                            _badge(s.status,
                                                bg: const Color(0x33A78BFA),
                                                fg: const Color(0xFFA78BFA),
                                                border: const Color(0x4DA78BFA)),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(s.description,
                                            style: const TextStyle(
                                                color: Colors.white70, fontSize: 13)),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 16,
                                          runSpacing: 8,
                                          children: [
                                            _kv('Coverage', s.coverage),
                                            _kv('Resolution', s.resolution),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.access_time,
                                                    size: 14, color: Colors.white60),
                                                const SizedBox(width: 4),
                                                Text('Updated: ${s.lastUpdate}',
                                                    style: const TextStyle(
                                                        color: Colors.white60,
                                                        fontSize: 12)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    onPressed: () {},
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0x33FFFFFF)),
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: const Icon(Icons.open_in_new, size: 16),
                                    label: const Text('View Source'),
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Export
          _panel(
            title: Row(
              children: const [
                Icon(Icons.download, color: Colors.white70, size: 18),
                SizedBox(width: 8),
                Text('Export Data', style: TextStyle(color: Colors.white)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Download weather and health data for analysis. All exports include metadata and timestamps.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                // Export buttons with overflow prevention
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 600) {
                      // Stack buttons vertically on smaller screens
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C3AED),
                            ),
                            child: const Text('Download CSV'),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                            ),
                            child: const Text('Download JSON'),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0x33FFFFFF)),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('API Access'),
                          ),
                        ],
                      );
                    } else {
                      // Use Wrap for larger screens to handle overflow
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C3AED),
                            ),
                            child: const Text('Download CSV'),
                          ),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                            ),
                            child: const Text('Download JSON'),
                          ),
                          OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0x33FFFFFF)),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('API Access'),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Tab: Privacy ----------
  Widget _privacyTab() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: _panel(
        title: const Text('Privacy & Data Usage',
            style: TextStyle(color: Colors.white)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('Data Collection'),
            const _Bullet('Location data is processed locally and not stored'),
            const _Bullet('Weather preferences are saved on-device'),
            const _Bullet('No personal health information is collected'),
            const _Bullet('Anonymous usage analytics help improve the service'),
            const SizedBox(height: 16),
            const _SectionTitle('Third-Party Data'),
            const _Bullet('NASA Earth Observation data is publicly available'),
            const _Bullet('EPA air quality data follows public use guidelines'),
            const _Bullet('Pollen data from certified monitoring stations'),
            const _Bullet('All data sources maintain their own privacy policies'),
            const SizedBox(height: 16),
            // Privacy buttons with overflow prevention
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 500) {
                  // Stack buttons vertically on smaller screens
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _outline('Privacy Policy'),
                      const SizedBox(height: 8),
                      _outline('Terms of Service'),
                      const SizedBox(height: 8),
                      _outline('Data License'),
                    ],
                  );
                } else {
                  // Use Wrap for larger screens
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _outline('Privacy Policy'),
                      _outline('Terms of Service'),
                      _outline('Data License'),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------- small UI helpers ----------
  static Widget _panel({required Widget title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  static Widget _rowSetting({
    required String label,
    required String description,
    required Widget trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 2),
              Text(description,
                  style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          fit: FlexFit.loose,
          child: Align(
            alignment: Alignment.centerRight,
            child: trailing,
          ),
        ),
      ],
    );
  }

  static Widget _pillButton(String text,
      {required bool active,
      required VoidCallback onTap,
      required Color activeColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? activeColor : const Color(0x0DFFFFFF),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: active ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static Widget _pillOutline(String text,
      {required bool active, required VoidCallback onTap}) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0x33FFFFFF)),
        foregroundColor: Colors.white,
      ),
      child: Text(text),
    );
  }

  static Widget _switchRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFF10B981)),
      ],
    );
  }

  static Widget _metricCard(_Metric m) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(m.label, style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),
          const SizedBox(height: 4),
          Text(m.value, style: const TextStyle(color: Colors.white, fontSize: 22)),
          const SizedBox(height: 2),
          Text(m.change, style: const TextStyle(color: Color(0xFF34D399), fontSize: 12)),
        ],
      ),
    );
  }

  static Widget _badge(String text,
      {required Color bg, required Color fg, required Color border}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  static Widget _kv(String k, String v) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$k: ', style: const TextStyle(color: Color(0x66FFFFFF), fontSize: 12)),
        Text(v, style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),
      ],
    );
  }

  static Widget _outline(String text) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Color(0x33FFFFFF)),
        foregroundColor: Colors.white,
      ),
      child: Text(text),
    );
  }
}

// --------- tiny data classes ---------
class _DataSource {
  final String name, type, description, lastUpdate, coverage, resolution, url, status;
  const _DataSource({
    required this.name,
    required this.type,
    required this.description,
    required this.lastUpdate,
    required this.coverage,
    required this.resolution,
    required this.url,
    required this.status,
  });
}

class _Metric {
  final String label, value, change;
  const _Metric({required this.label, required this.value, required this.change});
}

// --------- small text helpers (previously missing) ---------
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.white70)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
