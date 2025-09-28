import 'package:flutter/material.dart';

class ExportBar extends StatelessWidget {
  final VoidCallback? onExportCSV;
  final VoidCallback? onExportJSON;
  final VoidCallback? onExportPNG;
  final VoidCallback? onShare;

  const ExportBar({
    super.key,
    this.onExportCSV,
    this.onExportJSON,
    this.onExportPNG,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildExportButton(
            context,
            icon: Icons.table_chart,
            label: 'CSV',
            onPressed: onExportCSV ?? () => _showStubMessage(context, 'CSV'),
          ),
          _buildExportButton(
            context,
            icon: Icons.code,
            label: 'JSON',
            onPressed: onExportJSON ?? () => _showStubMessage(context, 'JSON'),
          ),
          _buildExportButton(
            context,
            icon: Icons.image,
            label: 'PNG',
            onPressed: onExportPNG ?? () => _showStubMessage(context, 'PNG'),
          ),
          _buildExportButton(
            context,
            icon: Icons.share,
            label: 'Share',
            onPressed: onShare ?? () => _showStubMessage(context, 'Share'),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    );
  }

  void _showStubMessage(BuildContext context, String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exported $format (stub)'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}