import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/alarm_system_model.dart';
import '../../../core/models/security_device_model.dart';
import '../../../core/models/alarm_event_model.dart';
import '../providers/security_provider.dart';
import 'alarm_rules_screen.dart';
import 'alarm_actions_screen.dart';
import 'alarm_events_screen.dart';

class AlarmDetailScreen extends StatefulWidget {
  final int alarmId;
  
  const AlarmDetailScreen({
    super.key,
    required this.alarmId,
  });

  @override
  State<AlarmDetailScreen> createState() => _AlarmDetailScreenState();
}

class _AlarmDetailScreenState extends State<AlarmDetailScreen> {
  bool _isLoading = true;
  bool _isArming = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final provider = Provider.of<SecurityProvider>(context, listen: false);
      await provider.loadAlarmSystem(widget.alarmId);
      await provider.loadAlarmRules(widget.alarmId);
      await provider.loadAlarmActions(widget.alarmId);
      await provider.loadAlarmEvents(widget.alarmId, limit: 5);
      await provider.loadSecurityDevices(alarmId: widget.alarmId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load alarm details: ${e.toString()}')),
        );
      }
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changeArmStatus(String newStatus) async {
    setState(() => _isArming = true);
    
    try {
      final provider = Provider.of<SecurityProvider>(context, listen: false);
      final success = await provider.changeAlarmArmStatus(widget.alarmId, newStatus);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getArmStatusMessage(newStatus)),
            backgroundColor: _getArmStatusColor(newStatus),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to change alarm status: ${e.toString()}')),
        );
      }
    }
    
    if (mounted) {
      setState(() => _isArming = false);
    }
  }
  
  String _getArmStatusMessage(String status) {
    switch (status) {
      case 'armed_stay':
        return 'Alarm system is now armed in stay mode';
      case 'armed_away':
        return 'Alarm system is now armed in away mode';
      case 'disarmed':
        return 'Alarm system is now disarmed';
      default:
        return 'Alarm status changed to $status';
    }
  }
  
  Color _getArmStatusColor(String status) {
    switch (status) {
      case 'armed_stay':
      case 'armed_away':
        return AppColors.success;
      case 'disarmed':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SecurityProvider>(
      builder: (context, provider, _) {
        final alarm = provider.currentAlarmSystem;
        final isLoading = provider.isLoading;
        
        if (isLoading || alarm == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Alarm Details')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        
        final rules = provider.alarmRules;
        final actions = provider.alarmActions;
        final events = provider.alarmEvents;
        final devices = provider.devices;
        
        return Scaffold(
          appBar: AppBar(
            title: Text(alarm.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
                onPressed: _loadData,
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.alarmEdit,
                      arguments: alarm.alarmId,
                    ).then((_) => _loadData());
                  } else if (value == 'delete') {
                    _showDeleteConfirmation(context, alarm);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Edit'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: AppColors.error),
                      title: Text('Delete', style: TextStyle(color: AppColors.error)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Alarm arm status card
                  _buildAlarmStatusCard(context, alarm),
                  
                  const SizedBox(height: 16),
                  
                  // Alarm information card
                  _buildAlarmInfoCard(context, alarm),
                  
                  const SizedBox(height: 16),
                  
                  // Recent events card
                  _buildRecentEventsCard(context, events),
                  
                  const SizedBox(height: 16),
                  
                  // Rules and actions section
                  _buildRulesCard(context, rules),
                  
                  const SizedBox(height: 16),
                  
                  _buildActionsCard(context, actions),
                  
                  const SizedBox(height: 16),
                  
                  // Connected devices section
                  if (devices.isNotEmpty)
                    _buildDevicesCard(context, devices)
                  else
                    _buildEmptyCard(
                      'No Connected Devices',
                      'There are no security devices connected to this alarm system.',
                    ),
                  
                  const SizedBox(height: 80), // Space for FAB
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showArmingOptions(context, alarm),
            backgroundColor: _getArmStatusFabColor(alarm.armStatus),
            child: const Icon(Icons.security),
          ),
        );
      },
    );
  }
  
  Color _getArmStatusFabColor(String status) {
    switch (status) {
      case 'armed_stay':
      case 'armed_away':
        return AppColors.success;
      case 'disarmed':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }
  
  void _showArmingOptions(BuildContext context, AlarmSystemModel alarm) {
    if (_isArming) return;
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Arm Stay'),
                subtitle: const Text('Arms perimeter sensors only'),
                leading: const Icon(Icons.home, color: AppColors.success),
                enabled: alarm.armStatus != 'armed_stay',
                onTap: () {
                  Navigator.pop(context);
                  _changeArmStatus('armed_stay');
                },
              ),
              ListTile(
                title: const Text('Arm Away'),
                subtitle: const Text('Arms all sensors'),
                leading: const Icon(Icons.directions_walk, color: AppColors.success),
                enabled: alarm.armStatus != 'armed_away',
                onTap: () {
                  Navigator.pop(context);
                  _changeArmStatus('armed_away');
                },
              ),
              ListTile(
                title: const Text('Disarm'),
                subtitle: const Text('Turns off all alarm monitoring'),
                leading: const Icon(Icons.lock_open, color: AppColors.warning),
                enabled: alarm.armStatus != 'disarmed',
                onTap: () {
                  Navigator.pop(context);
                  _changeArmStatus('disarmed');
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildAlarmStatusCard(BuildContext context, AlarmSystemModel alarm) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (alarm.armStatus) {
      case 'armed_stay':
        statusColor = AppColors.success;
        statusIcon = Icons.home;
        statusText = 'Armed Stay';
        break;
      case 'armed_away':
        statusColor = AppColors.success;
        statusIcon = Icons.directions_walk;
        statusText = 'Armed Away';
        break;
      case 'disarmed':
        statusColor = AppColors.warning;
        statusIcon = Icons.lock_open;
        statusText = 'Disarmed';
        break;
      default:
        statusColor = AppColors.secondary;
        statusIcon = Icons.security;
        statusText = alarm.armStatus;
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.5), width: 1),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  statusIcon,
                  color: statusColor,
                  size: 36,
                ),
                const SizedBox(width: 16),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Status: ${alarm.isActive ? 'Active' : 'Inactive'}',
              style: TextStyle(
                color: alarm.isActive ? AppColors.success : AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _getStatusDescription(alarm.armStatus),
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => _showArmingOptions(context, alarm),
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all(statusColor),
                side: MaterialStateProperty.all(BorderSide(color: statusColor)),
              ),
              child: const Text('CHANGE STATUS'),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getStatusDescription(String status) {
    switch (status) {
      case 'armed_stay':
        return 'Perimeter sensors are active. Motion sensors inside are ignored.';
      case 'armed_away':
        return 'All sensors are active. The system will trigger alarms for any detected breaches.';
      case 'disarmed':
        return 'The alarm system is not monitoring for breaches. Sensors are still active for status monitoring.';
      default:
        return 'The alarm system is in an unknown state.';
    }
  }
  
  Widget _buildAlarmInfoCard(BuildContext context, AlarmSystemModel alarm) {
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
            const Text(
              'Alarm Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Description', alarm.description ?? 'No description'),
            const Divider(),
            _buildInfoRow('Department', alarm.departmentName ?? 'Not assigned'),
            const Divider(),
            _buildInfoRow('Classroom', alarm.classroomName ?? 'Not assigned'),
            const Divider(),
            _buildInfoRow('Created', _formatDate(alarm.createdAt)),
            const Divider(),
            _buildInfoRow('Last Updated', _formatDate(alarm.updatedAt)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  Widget _buildRecentEventsCard(BuildContext context, List<AlarmEventModel> events) {
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
                    Navigator.pushNamed(
                      context,
                      AppRoutes.alarmEvents,
                      arguments: widget.alarmId,
                    );
                  },
                  child: const Text('VIEW ALL'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (events.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_note,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No events recorded',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: events.length > 5 ? 5 : events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return ListTile(
                    leading: Icon(
                      event.icon,
                      color: event.color,
                    ),
                    title: Text(event.description),
                    subtitle: Text(event.timeAgo),
                    trailing: event.acknowledged
                        ? const Icon(Icons.check_circle, color: AppColors.success, size: 16)
                        : null,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRulesCard(BuildContext context, List<dynamic> rules) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Rules',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AlarmRulesScreen(
                          alarmId: widget.alarmId,
                        ),
                      ),
                    ).then((_) => _loadData());
                  },
                  child: const Text('MANAGE'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (rules.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.rule,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No rules configured',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AlarmRulesScreen(
                                alarmId: widget.alarmId,
                              ),
                            ),
                          ).then((_) => _loadData());
                        },
                        child: const Text('Add Rules'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rules.length > 3 ? 3 : rules.length,
                itemBuilder: (context, index) {
                  final rule = rules[index];
                  return ListTile(
                    leading: Icon(rule.icon),
                    title: Text(rule.ruleName),
                    subtitle: Text(rule.conditionText),
                    trailing: Switch(
                      value: rule.isActive,
                      activeColor: AppColors.success,
                      onChanged: (value) {
                        Provider.of<SecurityProvider>(context, listen: false)
                            .toggleAlarmRuleActive(rule.ruleId, value);
                      },
                    ),
                  );
                },
              ),
            if (rules.length > 3)
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AlarmRulesScreen(
                          alarmId: widget.alarmId,
                        ),
                      ),
                    ).then((_) => _loadData());
                  },
                  child: Text('${rules.length - 3} more rules...'),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionsCard(BuildContext context, List<dynamic> actions) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AlarmActionsScreen(
                          alarmId: widget.alarmId,
                        ),
                      ),
                    ).then((_) => _loadData());
                  },
                  child: const Text('MANAGE'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (actions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.flash_on,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No actions configured',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AlarmActionsScreen(
                                alarmId: widget.alarmId,
                              ),
                            ),
                          ).then((_) => _loadData());
                        },
                        child: const Text('Add Actions'),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: actions.length > 3 ? 3 : actions.length,
                itemBuilder: (context, index) {
                  final action = actions[index];
                  return ListTile(
                    leading: Icon(action.icon, color: action.color),
                    title: Text(action.actionDescription ?? 'Action ${index + 1}'),
                    subtitle: Text(action.actionType.toUpperCase()),
                    trailing: Switch(
                      value: action.isActive,
                      activeColor: AppColors.success,
                      onChanged: (value) {
                        Provider.of<SecurityProvider>(context, listen: false)
                            .toggleAlarmActionActive(action.actionId, value);
                      },
                    ),
                  );
                },
              ),
            if (actions.length > 3)
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AlarmActionsScreen(
                          alarmId: widget.alarmId,
                        ),
                      ),
                    ).then((_) => _loadData());
                  },
                  child: Text('${actions.length - 3} more actions...'),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDevicesCard(BuildContext context, List<SecurityDeviceModel> devices) {
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
            const Text(
              'Connected Devices',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return ListTile(
                  leading: _getDeviceTypeIcon(device.deviceType),
                  title: Text(device.name),
                  subtitle: Text('${device.deviceType} • ${device.status}'),
                  trailing: _getDeviceStatusIndicator(device.status),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyCard(String title, String message) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.devices,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _getDeviceTypeIcon(String deviceType) {
    IconData iconData;
    
    switch (deviceType.toLowerCase()) {
      case 'camera':
        iconData = Icons.videocam;
        break;
      case 'motion':
        iconData = Icons.motion_photos_on;
        break;
      case 'door':
      case 'window':
        iconData = Icons.sensor_door;
        break;
      case 'temperature':
        iconData = Icons.thermostat;
        break;
      case 'smoke':
        iconData = Icons.whatshot;
        break;
      case 'water':
        iconData = Icons.water_damage;
        break;
      default:
        iconData = Icons.developer_board;
    }
    
    return Icon(iconData);
  }
  
  Widget _getDeviceStatusIndicator(String status) {
    Color color;
    String statusText;
    
    switch (status.toLowerCase()) {
      case 'online':
      case 'active':
      case 'secured':
        color = AppColors.success;
        statusText = 'OK';
        break;
      case 'breached':
      case 'triggered':
      case 'alarm':
        color = AppColors.error;
        statusText = '!';
        break;
      case 'offline':
      case 'inactive':
        color = Colors.grey;
        statusText = 'OFF';
        break;
      case 'warning':
        color = AppColors.warning;
        statusText = '!';
        break;
      default:
        color = AppColors.primary;
        statusText = '?';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Future<void> _showDeleteConfirmation(BuildContext context, AlarmSystemModel alarm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Alarm System'),
        content: Text(
          'Are you sure you want to delete "${alarm.name}"? This action cannot be undone and will remove all associated rules, actions, and event history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            style: ButtonStyle(
              foregroundColor: MaterialStateProperty.all(AppColors.error),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        final success = await Provider.of<SecurityProvider>(context, listen: false)
          .deleteAlarmSystem(alarm.alarmId);
          
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Alarm system deleted successfully')),
            );
            
            // Navigate back to alarm systems list
            Navigator.pop(context);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to delete alarm system')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting alarm system: ${e.toString()}')),
          );
        }
      }
    }
  }
}