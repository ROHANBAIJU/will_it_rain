import 'package:flutter/material.dart';

class AppDialogs {
  static void showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.help_outline),
              SizedBox(width: 8),
              Text('Help & Usage'),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'How to use this app:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('1. Add locations using the location input field'),
                Text('2. Select weather variables to track'),
                Text('3. Choose your forecast time range'),
                Text('4. View results in the charts and heatmap'),
                SizedBox(height: 16),
                Text(
                  'Data Sources:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('• NASA Earth Observations'),
                Text('• NOAA Weather Data'),
                Text('• OpenWeatherMap API'),
                SizedBox(height: 16),
                Text(
                  'Features:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('• Time-series forecasting'),
                Text('• Probability distributions'),
                Text('• Regional heatmaps'),
                Text('• Data export (CSV, JSON, PNG)'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  static void showSettingsDialog(BuildContext context) {
    String selectedTheme = 'Auto';
    String selectedTemperatureUnit = '°C';
    String selectedWindUnit = 'km/h';
    String selectedDefaultRange = '48h';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.settings),
                  SizedBox(width: 8),
                  Text('Settings'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Theme Selection
                    const Text(
                      'Theme',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedTheme,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: ['Light', 'Dark', 'Auto']
                          .map((theme) => DropdownMenuItem(
                                value: theme,
                                child: Text(theme),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedTheme = value ?? 'Auto';
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Temperature Unit
                    const Text(
                      'Temperature Unit',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedTemperatureUnit,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: ['°C', '°F']
                          .map((unit) => DropdownMenuItem(
                                value: unit,
                                child: Text(unit),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedTemperatureUnit = value ?? '°C';
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Wind Speed Unit
                    const Text(
                      'Wind Speed Unit',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedWindUnit,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: ['km/h', 'mph', 'm/s']
                          .map((unit) => DropdownMenuItem(
                                value: unit,
                                child: Text(unit),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedWindUnit = value ?? 'km/h';
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Default Range
                    const Text(
                      'Default Forecast Range',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedDefaultRange,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: ['24h', '48h', '7d', '14d']
                          .map((range) => DropdownMenuItem(
                                value: range,
                                child: Text(range),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedDefaultRange = value ?? '48h';
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Save settings
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Settings saved'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static void showProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.person_outline),
              SizedBox(width: 8),
              Text('Profile'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              CircleAvatar(
                radius: 40,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // User info
              const Text(
                'NASA Space App User',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Weather Forecasting App',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 16),

              // App info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Information',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('Version: 1.0.0'),
                    Text('Build: 1'),
                    Text('Last Updated: Today'),
                    SizedBox(height: 8),
                    Text(
                      'Data Sources:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('• NASA Earth Observations'),
                    Text('• NOAA Weather Data'),
                    Text('• OpenWeatherMap API'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
