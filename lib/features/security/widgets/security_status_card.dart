import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

class SecurityStatusCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  
  const SecurityStatusCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final totalDevices = stats['total_devices'] as int? ?? 0;
    final securedDevices = stats['secured_devices'] as int? ?? 0;
    final breachedDevices = stats['breached_devices'] as int? ?? 0;
    final offlineDevices = stats['offline_devices'] as int? ?? 0;
    final alarmStatus = stats['alarm_status'] as String? ?? 'inactive';
    
    final securityStatus = breachedDevices > 0 
      ? 'At Risk' 
      : (offlineDevices > 0 ? 'Warning' : 'Secured');
    
    // Calculate security score (0-100)
    final securityScore = totalDevices > 0
        ? ((securedDevices / totalDevices) * 100).round()
        : 100;
        
    // Determine overall color
    final Color statusColor;
    if (breachedDevices > 0) {
      statusColor = AppColors.error;
    } else if (offlineDevices > 0) {
      statusColor = AppColors.warning;
    } else {
      statusColor = AppColors.success;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: statusColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  breachedDevices > 0 
                    ? Icons.warning_amber 
                    : (offlineDevices > 0 ? Icons.info : Icons.security),
                  color: statusColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Security Status: $securityStatus',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      Text(
                        'Alarm System: ${alarmStatus == 'active' ? 'Active' : 'Inactive'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: alarmStatus == 'active' ? AppColors.success : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor.withOpacity(0.1),
                    border: Border.all(color: statusColor),
                  ),
                  child: Center(
                    child: Text(
                      '$securityScore%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusItem(
                  'Secured', 
                  securedDevices, 
                  Icons.lock, 
                  AppColors.success,
                ),
                _buildStatusItem(
                  'Breached', 
                  breachedDevices, 
                  Icons.lock_open, 
                  AppColors.error,
                ),
                _buildStatusItem(
                  'Offline', 
                  offlineDevices, 
                  Icons.offline_bolt, 
                  AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusItem(String label, int count, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }
}