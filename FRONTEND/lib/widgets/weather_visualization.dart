import 'package:flutter/material.dart';
// ...existing code...

/// Weather Data Visualization Widget
/// Shows animated charts for weather statistics
class WeatherDataVisualization extends StatelessWidget {
  final Map<String, dynamic> statistics;
  
  const WeatherDataVisualization({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRainProbabilityBar(),
        const SizedBox(height: 20),
        _buildTemperatureRange(),
        const SizedBox(height: 20),
        _buildWeatherMetrics(),
      ],
    );
  }

  Widget _buildRainProbabilityBar() {
  final rainProb = (statistics['precipitation_probability_percent'] ?? statistics['precipitation_probability'] ?? 0.0).toDouble();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water_drop, color: _getRainColor(rainProb), size: 24),
              const SizedBox(width: 8),
              const Text(
                'Rain Probability',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              const Spacer(),
              Text(
                '${rainProb.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _getRainColor(rainProb),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: rainProb / 100,
              minHeight: 12,
              backgroundColor: const Color(0xFFE5E5E5),
              valueColor: AlwaysStoppedAnimation(_getRainColor(rainProb)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getRainDescription(rainProb),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureRange() {
  final avgTemp = (statistics['average_temperature_celsius'] ?? statistics['avg_temp_celsius'] ?? 20.0).toDouble();
  final minTemp = (statistics['min_temperature_celsius'] ?? statistics['min_temp_celsius'] ?? 15.0).toDouble();
  final maxTemp = (statistics['max_temperature_celsius'] ?? statistics['max_temp_celsius'] ?? 25.0).toDouble();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.thermostat, color: _getTempColor(avgTemp), size: 24),
              const SizedBox(width: 8),
              const Text(
                'Temperature Range',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D2D2D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTempCard(
                  'Min',
                  minTemp,
                  Icons.arrow_downward,
                  const Color(0xFF4A90E2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTempCard(
                  'Avg',
                  avgTemp,
                  Icons.thermostat_outlined,
                  const Color(0xFF7C6BAD),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTempCard(
                  'Max',
                  maxTemp,
                  Icons.arrow_upward,
                  const Color(0xFFE74C3C),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTempCard(String label, double temp, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${temp.toStringAsFixed(1)}°C',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherMetrics() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Additional Metrics',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 16),
          _buildMetricRow(
            Icons.water,
            'Humidity',
            '${(statistics['average_humidity_percent'] ?? statistics['avg_humidity_percent'] ?? 0.0).toStringAsFixed(1)}%',
            const Color(0xFF3498DB),
          ),
          const Divider(height: 24),
          _buildMetricRow(
            Icons.air,
            'Wind Speed',
            '${(statistics['average_wind_speed_mps'] ?? statistics['average_wind_speed_ms'] ?? statistics['avg_wind_speed'] ?? 0.0).toStringAsFixed(1)} m/s',
            const Color(0xFF95A5A6),
          ),
          const Divider(height: 24),
          _buildMetricRow(
            Icons.compress,
            'Pressure',
            '${(statistics['average_pressure_kpa'] ?? statistics['avg_pressure_kpa'] ?? statistics['average_pressure_hpa'] ?? 0.0).toStringAsFixed(1)} kPa',
            const Color(0xFF9B59B6),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _getRainColor(double probability) {
    if (probability < 20) return const Color(0xFF27AE60);
    if (probability < 50) return const Color(0xFFF39C12);
    return const Color(0xFFE74C3C);
  }

  String _getRainDescription(double probability) {
    if (probability < 20) return 'Very unlikely to rain';
    if (probability < 40) return 'Low chance of rain';
    if (probability < 60) return 'Moderate chance of rain';
    if (probability < 80) return 'High chance of rain';
    return 'Very likely to rain';
  }

  Color _getTempColor(double temp) {
    if (temp < 10) return const Color(0xFF3498DB);
    if (temp < 20) return const Color(0xFF27AE60);
    if (temp < 30) return const Color(0xFFF39C12);
    return const Color(0xFFE74C3C);
  }
}
