import 'package:flutter/material.dart';

class ExportBar extends StatelessWidget {
  const ExportBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exporting data to CSV...')),
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('Export CSV'),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exporting data to JSON...')),
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('Export JSON'),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saving plot as PNG...')),
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('Download Plot (PNG)'),
          ),
        ],
      ),
    );
  }
}
