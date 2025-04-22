import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/security_provider.dart';
import '../widgets/security_status_card.dart';
import '../widgets/security_event_list.dart';
import '../widgets/device_status_grid.dart';
import '../widgets/alarm_control_widget.dart';
import 'security_events_screen.dart';
import '../../../core/constants/app_constants.dart';

class SecurityDashboardScreen extends StatefulWidget {
  const SecurityDashboardScreen({super.key});

  @override
  State<SecurityDashboardScreen> createState() => _SecurityDashboardScreenState();
}

class _SecurityDashboardScreenState extends State<SecurityDashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = Provider.of<SecurityProvider>(context, listen: false);
    await provider.refreshSecurityData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.event_note),
            tooltip: 'View All Events',
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.securityEvents);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Consumer<SecurityProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.devices.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.errorMessage != null && provider.devices.isEmpty) {
              return _buildErrorView(context, provider);
            }

            return _buildDashboard(context, provider);
          },
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, SecurityProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Security Status Summary
          SecurityStatusCard(stats: provider.securityStats),
          
          const SizedBox(height: 24),
          
          // Door/Window Status Section
          const Text(
            'Security Status by Location',
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          DeviceStatusGrid(
            doorDevices: provider.doorDevices,
            windowDevices: provider.windowDevices,
            motionDevices: provider.motionDevices,
            onToggleDevice: (deviceId, secure) {
              provider.toggleSecurityDevice(deviceId: deviceId, secure: secure);
            },
          ),
          
          const SizedBox(height: 24),
          
          // Recent Events Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Events',
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.securityEvents);
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SecurityEventList(
            events: provider.recentEvents,
            onAcknowledge: (eventId) {
              provider.acknowledgeSecurityEvent(eventId);
            },
            compact: true,
            maxEvents: 5,
          ),
          
          const SizedBox(height: 24),
          
          // Alarm System Controls Section
          const Text(
            'Alarm System',
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          AlarmControlWidget(
            isActive: provider.alarmSystemActive,
            onToggle: (active) {
              provider.toggleAlarmSystem(active: active);
            },
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, SecurityProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            provider.errorMessage ?? 'An error occurred',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.error),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}