// lib/widgets/footer.dart
// FooterBar widget to include at the bottom of scrollable pages

import 'package:flutter/material.dart';

class FooterBar extends StatelessWidget {
  const FooterBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 700;
          if (isSmall) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  alignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: const [
                    Text('© 2025 AeroNimbus', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text('•', style: TextStyle(color: Colors.white38)),
                    Text('NASA Data', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Badge(
                      label: 'All Systems OK',
                      bg: Color(0x3310B981),
                      fg: Color(0xFF6EE7B7),
                      border: Color(0x4D10B981),
                      small: true,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Updated: ${TimeOfDay.now().format(context)}',
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 2,
                child: Wrap(
                  alignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: const [
                    Text('© 2025 AeroNimbus', style: TextStyle(color: Colors.white70)),
                    Text('•', style: TextStyle(color: Colors.white38)),
                    Text('Powered by NASA Earth Observation Data',
                        style: TextStyle(color: Colors.white70)),
                    Text('•', style: TextStyle(color: Colors.white38)),
                    _Badge(
                      label: 'All Systems Operational',
                      bg: Color(0x3310B981),
                      fg: Color(0xFF6EE7B7),
                      border: Color(0x4D10B981),
                      small: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  'Last updated: ${TimeOfDay.now().format(context)}',
                  style: const TextStyle(color: Colors.white54),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color bg, fg, border;
  final bool small;

  const _Badge({
    required this.label,
    required this.bg,
    required this.fg,
    required this.border,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: small ? 11 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
