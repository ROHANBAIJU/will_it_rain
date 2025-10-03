import 'package:flutter/material.dart';

class BestDaysPage extends StatefulWidget {
  const BestDaysPage({super.key});

  @override
  State<BestDaysPage> createState() => _BestDaysPageState();
}

class _BestDaysPageState extends State<BestDaysPage> {
  late int selectedMonth; // 1-based (January = 1)
  late int selectedYear;
  late List<_DayInfo> calendarDays;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedMonth = now.month; // 1-based for DateTime
    selectedYear = now.year;
    calendarDays = _generateCalendarData(selectedYear, selectedMonth);
  }

  List<_DayInfo> _generateCalendarData(int year, int month) {
    final today = DateTime.now();
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final days = <_DayInfo>[];
    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(year, month, i);
      final weather = _getWeatherForDate(i);
      final score = _getWeatherScore(i);
      days.add(_DayInfo(
        dateOnly: i,
        fullDate: date,
        weather: weather,
        score: score,
        isToday: today.day == i && today.month == month && today.year == year,
      ));
    }
    return days;
  }

  _Weather _getWeatherForDate(int day) {
    final patterns = <_Weather>[
      _Weather(condition: 'Sunny', temp: 25, rain: 0, wind: 8, icon: _WIcon.sun),
      _Weather(condition: 'Partly Cloudy', temp: 22, rain: 15, wind: 12, icon: _WIcon.partly),
      _Weather(condition: 'Cloudy', temp: 20, rain: 30, wind: 15, icon: _WIcon.cloud),
      _Weather(condition: 'Light Rain', temp: 18, rain: 65, wind: 20, icon: _WIcon.rain),
      _Weather(condition: 'Rainy', temp: 16, rain: 85, wind: 25, icon: _WIcon.rain),
    ];
    final index = (day * 7) % patterns.length;
    return patterns[index];
  }

  int _getWeatherScore(int day) {
    final w = _getWeatherForDate(day);
    double score = 100;
    score -= w.rain * 0.8;
    if (w.wind > 20) score -= (w.wind - 20) * 2;
    if (w.temp < 20 || w.temp > 25) score -= (w.temp - 22.5).abs() * 3;
    return score.clamp(0, 100).round();
  }

  Color _scoreColor(int score) {
    if (score >= 80) return const Color(0xFF10B981);
    if (score >= 60) return const Color(0xFFF59E0B);
    if (score >= 40) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  String _scoreText(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Poor';
  }

  static const _monthNames = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December'
  ];

  static const _weekdayShort = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];

  int _calculateInitialPadding(int year, int month) {
    // DateTime.weekday: 1=Mon, ..., 7=Sun
    final firstDay = DateTime(year, month, 1);
    return firstDay.weekday % 7;
  }

  @override
  Widget build(BuildContext context) {
    final bestDays = [...calendarDays]
      ..retainWhere((d) => d.score >= 70)
      ..sort((a, b) => b.score.compareTo(a.score));
    final top5 = bestDays.take(5).toList();

    return Scaffold(
      // Avoid fully transparent background to prevent blank look on some hosts
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ---------- Best Days Overview ----------
            _panel(
              title: 'Best Days This Month',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Optimal weather conditions for outdoor activities',
                    style: TextStyle(color: Color(0xFF6EE7B7)),
                  ),
                  const SizedBox(height: 12),
                  if (top5.isEmpty)
                    const Text('No excellent days this month.',
                        style: TextStyle(color: Colors.white70)),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final d in top5)
                        _badge(
                          '${_monthNames[selectedMonth - 1]} ${d.dateOnly} (${d.score}%)',
                          bg: const Color(0x3348BB78),
                          fg: const Color(0xFF6EE7B7),
                          border: const Color(0x4D10B981),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ---------- Calendar Heatmap ----------
            _panel(
              title: '${_monthNames[selectedMonth - 1]} $selectedYear Weather Outlook',
              leading: const Icon(Icons.calendar_month, color: Colors.white70, size: 18),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _weekdayShort
                        .map((s) => Expanded(
                              child: Center(
                                child: Text(
                                  s,
                                  style: const TextStyle(
                                      color: Color(0x99FFFFFF), fontSize: 12),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  _calendarGrid(calendarDays, selectedYear, selectedMonth),
                  const SizedBox(height: 16),
                  const Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 24,
                    runSpacing: 12,
                    children: [
                      _LegendDot(color: Color(0xFF10B981), label: 'Excellent (80%+)'),
                      _LegendDot(color: Color(0xFFF59E0B), label: 'Good (60–79%)'),
                      _LegendDot(color: Color(0xFFF97316), label: 'Fair (40–59%)'),
                      _LegendDot(color: Color(0xFFEF4444), label: 'Poor (0–39%)'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ---------- Best Days Detail ----------
            _panel(
              title: 'Top 5 Days This Month',
              child: Column(
                children: [
                  if (top5.isEmpty)
                    const Text('No top days this month.',
                        style: TextStyle(color: Colors.white70)),
                  for (int i = 0; i < top5.length; i++)
                    Padding(
                      padding: EdgeInsets.only(bottom: i == top5.length - 1 ? 0 : 8),
                      child: _topDayRow(index: i + 1, day: top5[i]),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ---------- Scoring Criteria ----------
            _panel(
              title: 'Scoring Criteria',
              child: LayoutBuilder(
                builder: (context, c) {
                  final isWide = c.maxWidth >= 720;
                  final itemW = isWide ? (c.maxWidth - 16 * 2) / 3 : c.maxWidth;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: itemW,
                        child: _criteriaBlock(
                          title: 'Temperature',
                          color: const Color(0xFF6EE7B7),
                          lines: const ['Optimal: 20–25°C', 'Perfect for outdoor activities'],
                        ),
                      ),
                      SizedBox(
                        width: itemW,
                        child: _criteriaBlock(
                          title: 'Rain Probability',
                          color: const Color(0xFF06B6D4),
                          lines: const ['Lower is better', 'Less than 20% is ideal'],
                        ),
                      ),
                      SizedBox(
                        width: itemW,
                        child: _criteriaBlock(
                          title: 'Wind Speed',
                          color: const Color(0xFFFACC15),
                          lines: const ['Under 20 km/h preferred', 'Gentle breeze for comfort'],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // ---------- Actions ----------
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED), // purple-600
                  ),
                  onPressed: () {},
                  child: const Text('Add to Calendar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981), // emerald-600
                  ),
                  onPressed: () {},
                  child: const Text('Set Reminders'),
                ),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0x33FFFFFF)), // 20%
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Export Schedule'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------- small UI helpers ----------

  static Widget _panel({required String title, Widget? leading, required Widget child}) {
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
          Row(children: [
            if (leading != null) ...[leading, const SizedBox(width: 8)],
            Text(title,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
          ]),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  static Widget _badge(String text,
      {required Color bg, required Color fg, required Color border}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(text,
          style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }

  static Widget _calendarGrid(List<_DayInfo> days, int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final initialPadding = firstDay.weekday % 7; // 0..6, where 0 = Sunday

    // Build cells: leading blanks + actual days + trailing blanks to complete rows of 7
    final cells = <Widget>[];
    for (int i = 0; i < initialPadding; i++) {
      cells.add(const SizedBox.shrink());
    }

    cells.addAll(days.map((d) {
      final base = _scoreColorStatic(d.score);
      final bg = base.withAlpha(51); // ~20%
      final ring = d.isToday ? const Color(0xFFFACC15) : const Color(0x1AFFFFFF);
      return Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ring),
        ),
        padding: const EdgeInsets.all(4),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('${d.dateOnly}',
                  style: const TextStyle(color: Colors.white, fontSize: 10)),
              const SizedBox(height: 2),
              Icon(_iconFor(d.weather.icon),
                  size: 12, color: const Color(0xB3FFFFFF)),
              const SizedBox(height: 2),
              Text('${d.score}%',
                  style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 8)),
            ],
          ),
        ),
      );
    }));

    // pad to full weeks (multiple of 7) for stable GridView layout
    while (cells.length % 7 != 0) {
      cells.add(const SizedBox.shrink());
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: cells.length,
      itemBuilder: (_, i) => cells[i],
    );
  }

  Widget _topDayRow({required int index, required _DayInfo day}) {
    final color = _scoreColor(day.score);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x0DFFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text('#$index', style: const TextStyle(color: Color(0xFFFACC15))),
              const SizedBox(width: 10),
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_monthNames[day.fullDate.month - 1]} ${day.dateOnly}', style: const TextStyle(color: Colors.white)),
                  Text(_weekdayLabel(day.fullDate), style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Icon(_iconFor(day.weather.icon), color: const Color(0xB3FFFFFF), size: 20),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${day.weather.temp}°C', style: const TextStyle(color: Colors.white)),
                  Text(day.weather.condition, style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),
                ],
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${day.score}%', style: const TextStyle(color: Colors.white)),
                  Text(_scoreText(day.score), style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _criteriaBlock({
    required String title,
    required Color color,
    required List<String> lines,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          for (final l in lines)
            Text(l, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  static String _weekdayLabel(DateTime d) {
    return ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'][d.weekday - 1];
  }

  static IconData _iconFor(_WIcon icon) {
    switch (icon) {
      case _WIcon.sun:
        return Icons.wb_sunny;
      case _WIcon.partly:
        return Icons.wb_cloudy;
      case _WIcon.cloud:
        return Icons.cloud;
      case _WIcon.rain:
        // Use a widely available icon to avoid asset issues on older builds
        return Icons.beach_access; // umbrella alternative
    }
  }

  static Color _scoreColorStatic(int score) {
    if (score >= 80) return const Color(0xFF10B981);
    if (score >= 60) return const Color(0xFFF59E0B);
    if (score >= 40) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }
}

// ---------- tiny models ----------

enum _WIcon { sun, partly, cloud, rain }

class _Weather {
  final String condition;
  final int temp, rain, wind;
  final _WIcon icon;
  _Weather({
    required this.condition,
    required this.temp,
    required this.rain,
    required this.wind,
    required this.icon,
  });
}

class _DayInfo {
  final int dateOnly;
  final DateTime fullDate;
  final _Weather weather;
  final int score;
  final bool isToday;
  _DayInfo({
    required this.dateOnly,
    required this.fullDate,
    required this.weather,
    required this.score,
    required this.isToday,
  });
}

// Legend dot widget
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({super.key, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Flexible(child: Text(label, style: const TextStyle(color: Color(0x99FFFFFF)))),
      ],
    );
  }
}


