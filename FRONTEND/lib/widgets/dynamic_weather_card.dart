import 'package:flutter/material.dart';

/// Dynamic Weather Icon Widget
/// Shows animated weather conditions
class DynamicWeatherCard extends StatelessWidget {
  final String condition; // sunny, cloudy, rainy, snowy, partly_cloudy
  final double temperature;
  final String description;
  final bool isLoading;

  const DynamicWeatherCard({
    super.key,
    required this.condition,
    required this.temperature,
    required this.description,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingCard();
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: _getGradientForCondition(condition),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getColorForCondition(condition).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Weather Icon
          _buildWeatherIcon(condition),
          const SizedBox(height: 16),
          
          // Temperature
          Text(
            '${temperature.toStringAsFixed(1)}°C',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Description
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF7C6BAD),
            Color(0xFF9B87C4),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C6BAD).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              'Loading current weather...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherIcon(String condition) {
    IconData icon;
    Color iconColor = Colors.white;

    switch (condition.toLowerCase()) {
      case 'sunny':
        icon = Icons.wb_sunny;
        break;
      case 'cloudy':
        icon = Icons.cloud;
        break;
      case 'partly_cloudy':
        icon = Icons.wb_cloudy;
        break;
      case 'rainy':
        icon = Icons.umbrella;
        break;
      case 'snowy':
        icon = Icons.ac_unit;
        break;
      default:
        icon = Icons.wb_sunny;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 64,
        color: iconColor,
      ),
    );
  }

  LinearGradient _getGradientForCondition(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF39C12),
            Color(0xFFE67E22),
          ],
        );
      case 'cloudy':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF7F8C8D),
            Color(0xFF95A5A6),
          ],
        );
      case 'partly_cloudy':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF5DADE2),
            Color(0xFF85C1E9),
          ],
        );
      case 'rainy':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2980B9),
            Color(0xFF3498DB),
          ],
        );
      case 'snowy':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF85C1E9),
            Color(0xFFAED6F1),
          ],
        );
      default:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF7C6BAD),
            Color(0xFF9B87C4),
          ],
        );
    }
  }

  Color _getColorForCondition(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
        return const Color(0xFFF39C12);
      case 'cloudy':
        return const Color(0xFF7F8C8D);
      case 'partly_cloudy':
        return const Color(0xFF5DADE2);
      case 'rainy':
        return const Color(0xFF2980B9);
      case 'snowy':
        return const Color(0xFF85C1E9);
      default:
        return const Color(0xFF7C6BAD);
    }
  }
}
