import 'package:flutter/material.dart';

class TransparencyPage extends StatelessWidget {
  const TransparencyPage({super.key});

  // ----- mock data ported from TSX -----
  List<_Metric> get _metrics => const [
        _Metric(label: 'Total Data Points', value: '2.4M', change: '+12% today'),
        _Metric(label: 'Update Frequency', value: 'Every 3hrs', change: 'Real-time'),
        _Metric(label: 'Data Accuracy', value: '98.7%', change: '+0.3% this week'),
        _Metric(label: 'Coverage Area', value: 'Global', change: '100% operational'),
      ];

  List<_Source> get _sources => const [
        _Source(
          name: 'NASA MODIS Terra/Aqua',
          type: 'Satellite Imagery',
          description: 'High-resolution atmospheric and surface observations',
          lastUpdate: '2024-09-30 14:30 UTC',
          coverage: 'Global',
          resolution: '1km',
          url: 'https://modis.gsfc.nasa.gov/',
          status: 'Active',
        ),
        _Source(
          name: 'NASA GPM IMERG',
          type: 'Precipitation',
          description: 'Global Precipitation Measurement mission data',
          lastUpdate: '2024-09-30 12:00 UTC',
          coverage: '60°S-60°N',
          resolution: '0.1°',
          url: 'https://gpm.nasa.gov/',
          status: 'Active',
        ),
        _Source(
          name: 'NASA GEOS-5 FP',
          type: 'Atmospheric Model',
          description: 'Forward Processing for atmospheric analysis',
          lastUpdate: '2024-09-30 18:00 UTC',
          coverage: 'Global',
          resolution: '0.25°',
          url: 'https://gmao.gsfc.nasa.gov/',
          status: 'Active',
        ),
        _Source(
          name: 'NOAA GFS',
          type: 'Weather Model',
          description: 'Global Forecast System numerical weather prediction',
          lastUpdate: '2024-09-30 15:45 UTC',
          coverage: 'Global',
          resolution: '13km',
          url: 'https://www.ncei.noaa.gov/',
          status: 'Active',
        ),
      ];

  List<_DownloadFmt> get _formats => const [
        _DownloadFmt(format: 'CSV', description: 'Comma-separated values for spreadsheets', size: '~2.1MB'),
        _DownloadFmt(format: 'JSON', description: 'JavaScript Object Notation for APIs', size: '~3.4MB'),
        _DownloadFmt(format: 'NetCDF', description: 'Network Common Data Form for scientific data', size: '~5.8MB'),
        _DownloadFmt(format: 'GeoTIFF', description: 'Geographic Tagged Image File Format', size: '~12.3MB'),
      ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ----- Header -----
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
                child: const Icon(Icons.shield, color: Color(0xFFA78BFA), size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Data Transparency & Sources',
                        style: TextStyle(color: Colors.white, fontSize: 18)),
                    SizedBox(height: 2),
                    Text(
                      'All weather predictions powered by NASA Earth Observation Data',
                      style: TextStyle(color: Color(0xFFDDD6FE)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ----- Data Metrics -----
        LayoutBuilder(
          builder: (context, c) {
            final isWide = c.maxWidth >= 900;
            final w = isWide ? (c.maxWidth - 12 * 3) / 4 : c.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _metrics
                  .map((m) => SizedBox(width: w, child: _metricCard(m)))
                  .toList(),
            );
          },
        ),

        const SizedBox(height: 16),

        // ----- Data Sources -----
        _panel(
          title: Row(
            children: const [
              Icon(Icons.storage, color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Text('Primary Data Sources', style: TextStyle(color: Colors.white)),
            ],
          ),
          child: Column(
            children: _sources
                .map(
                  (s) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0x0DFFFFFF), // 5%
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x1AFFFFFF)), // 10%
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.satellite_alt, color: Color(0xFF06B6D4), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(
                                  child: Text(s.name, style: const TextStyle(color: Colors.white)),
                                ),
                                _badge(
                                  s.type,
                                  bg: const Color(0x3348BB78),
                                  fg: const Color(0xFF6EE7B7),
                                  border: const Color(0x4D10B981),
                                ),
                                const SizedBox(width: 6),
                                _badge(
                                  s.status,
                                  bg: const Color(0x33A78BFA),
                                  fg: const Color(0xFFA78BFA),
                                  border: const Color(0x4DA78BFA),
                                ),
                              ]),
                              const SizedBox(height: 8),
                              Text(
                                s.description,
                                style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 16,
                                runSpacing: 8,
                                children: [
                                  _kv('Coverage', s.coverage),
                                  _kv('Resolution', s.resolution),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.access_time, size: 14, color: Color(0x99FFFFFF)),
                                      SizedBox(width: 4),
                                      // s.lastUpdate below
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(width: 18), // align with icon space
                                      Text(
                                        'Updated: ${s.lastUpdate}',
                                        style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12),
                                      ),
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
                            side: const BorderSide(color: Color(0x33FFFFFF)), // 20%
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text('View Source'),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),

        const SizedBox(height: 16),

        // ----- Download Raw Data -----
        _panel(
          title: Row(
            children: const [
              Icon(Icons.download, color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Text('Download Raw Data', style: TextStyle(color: Colors.white)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Access the raw weather data used in AeroNimbus for your own analysis and research. '
                'All datasets include metadata and quality indicators.',
                style: TextStyle(color: Color(0xB3FFFFFF)),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, c) {
                  final isWide = c.maxWidth >= 720;
                  final w = isWide ? (c.maxWidth - 12) / 2 : c.maxWidth;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _formats
                        .map(
                          (f) => SizedBox(
                            width: w,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0x0DFFFFFF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0x1AFFFFFF)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(f.format, style: const TextStyle(color: Colors.white)),
                                      const SizedBox(height: 4),
                                      Text(
                                        f.description,
                                        style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Size: ${f.size}',
                                        style: const TextStyle(color: Color(0x66FFFFFF), fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton(
                                    onPressed: () {},
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF7C3AED), // purple
                                    ),
                                    child: const Text('Download'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ----- API Access -----
        _panel(
          title: const Text('API Access', style: TextStyle(color: Colors.white)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Programmatic access to weather data and forecasts through our RESTful API.',
                style: TextStyle(color: Color(0xB3FFFFFF)),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0x8030313D),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0x1AFFFFFF)),
                ),
                child: const Text(
                  'GET https://api.aeronimbus.nasa.gov/v1/weather?lat=40.7128&lon=-74.0060',
                  style: TextStyle(color: Color(0xFF6EE7B7), fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                    ),
                    child: const Text('View API Docs'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0x33FFFFFF)),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Get API Key'),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ----- Data Usage & Privacy -----
        _panel(
          title: const Text('Data Usage & Privacy', style: TextStyle(color: Colors.white)),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, c) {
                  final isWide = c.maxWidth >= 900;
                  final w = isWide ? (c.maxWidth - 16) / 2 : c.maxWidth;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: w,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Usage Guidelines', style: TextStyle(color: Colors.white)),
                            SizedBox(height: 6),
                            _Bullet('• All NASA data is publicly available and free to use'),
                            _Bullet('• Attribution to NASA required for commercial use'),
                            _Bullet('• Data provided "as-is" without warranty'),
                            _Bullet('• Rate limits apply to API access'),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: w,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Privacy Policy', style: TextStyle(color: Colors.white)),
                            SizedBox(height: 6),
                            _Bullet('• No personal data is stored or transmitted'),
                            _Bullet('• Location data is processed locally'),
                            _Bullet('• Anonymous usage statistics collected'),
                            _Bullet('• Full transparency in data handling'),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _outline('Data License'),
                  const SizedBox(width: 8),
                  _outline('Privacy Policy'),
                  const SizedBox(width: 8),
                  _outline('Terms of Use'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ----- small UI helpers -----
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

  static Widget _badge(String text, {required Color bg, required Color fg, required Color border}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }

  static Widget _kv(String k, String v) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$k: ', style: const TextStyle(color: Color(0x66FFFFFF), fontSize: 12)), // 40% white
        Text(v, style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),     // 60% white
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

// ----- tiny models & widgets -----
class _Metric {
  final String label, value, change;
  const _Metric({required this.label, required this.value, required this.change});
}

class _Source {
  final String name, type, description, lastUpdate, coverage, resolution, url, status;
  const _Source({
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

class _DownloadFmt {
  final String format, description, size;
  const _DownloadFmt({required this.format, required this.description, required this.size});
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text, {super.key});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 13)),
    );
  }
}
