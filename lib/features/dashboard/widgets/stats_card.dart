import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 12),
            
            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            
            // Value
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatsCardGrid extends StatelessWidget {
  final Map<String, double> stats;

  const StatsCardGrid({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (stats.containsKey('average_temperature'))
          StatsCard(
            title: 'Average Temperature',
            value: '${stats['average_temperature']!.toStringAsFixed(1)}°C',
            icon: Icons.thermostat,
            color: AppColors.primary,
          ),
        if (stats.containsKey('average_humidity'))
          StatsCard(
            title: 'Average Humidity',
            value: '${stats['average_humidity']!.toStringAsFixed(1)}%',
            icon: Icons.water_drop,
            color: Colors.blue,
          ),
        if (stats.containsKey('occupancy_rate'))
          StatsCard(
            title: 'Occupancy Rate',
            value: '${stats['occupancy_rate']!.toStringAsFixed(0)}%',
            icon: Icons.people,
            color: Colors.green,
          ),
        if (stats.containsKey('alert_count'))
          StatsCard(
            title: 'Active Alerts',
            value: '${stats['alert_count']!.toInt()}',
            icon: Icons.warning_amber,
            color: stats['alert_count']! > 0 ? AppColors.warning : AppColors.success,
          ),
      ],
    );
  }
} 