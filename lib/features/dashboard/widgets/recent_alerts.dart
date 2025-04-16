import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/alert_model.dart';
import '../../../core/utils/app_utils.dart';

class RecentAlerts extends StatelessWidget {
  final List<AlertModel> alerts;
  final VoidCallback onViewAllTap;

  const RecentAlerts({
    super.key,
    required this.alerts,
    required this.onViewAllTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Alerts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              TextButton(
                onPressed: onViewAllTap,
                child: const Text('View All'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        
        // Alert list
        if (alerts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                'No recent alerts',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: alerts.length,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              return AlertListItem(alert: alerts[index]);
            },
          ),
      ],
    );
  }
}

class AlertListItem extends StatelessWidget {
  final AlertModel alert;

  const AlertListItem({
    super.key,
    required this.alert,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Alert icon with severity color background
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: alert.severityColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                alert.alertIcon,
                color: alert.severityColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            
            // Alert info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.message,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Timestamp
            Text(
              formatDateTime(alert.timestamp),
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 