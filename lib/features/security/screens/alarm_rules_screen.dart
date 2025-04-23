import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/models/camera_model.dart';
import 'package:smart_school/core/models/sensor_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/alarm_rule_model.dart';
import '../../../core/models/security_device_model.dart';
import '../providers/security_provider.dart';

class AlarmRulesScreen extends StatefulWidget {
  final int alarmId;
  
  const AlarmRulesScreen({
    super.key,
    required this.alarmId,
  });

  @override
  State<AlarmRulesScreen> createState() => _AlarmRulesScreenState();
}

class _AlarmRulesScreenState extends State<AlarmRulesScreen> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers and values
  final _ruleNameController = TextEditingController();
  int? _selectedDeviceId;
  String _conditionType = 'threshold';
  double? _thresholdValue;
  String _comparisonOperator = '>';
  String? _statusValue;
  TimeOfDay? _timeRestrictionStart;
  TimeOfDay? _timeRestrictionEnd;
  String _daysActive = 'mon,tue,wed,thu,fri';
  bool _isActive = true;

  // Add this to your _AlarmRulesScreenState class to store a reference to your provider
  late SecurityProvider _securityProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Store a reference to the provider that we can safely use later
    _securityProvider = Provider.of<SecurityProvider>(context, listen: false);
  }
  
  @override
  void initState() {
    super.initState();
    
    // Use addPostFrameCallback to delay data loading until after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }
  
  @override
  void dispose() {
    _ruleNameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final provider = Provider.of<SecurityProvider>(context, listen: false);
      
      // Load rules specific to this alarm
      await provider.loadAlarmRules(widget.alarmId);
      
      // Load ALL available devices for selection in the form
      // Pass 0 or null to get all devices, not just those associated with this alarm
      await provider.loadSecurityDevices(alarmId: 0); // Use 0 to get all devices
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load rules: ${e.toString()}')),
        );
      }
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarm Rules'),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Consumer<SecurityProvider>(
              builder: (context, provider, _) {
                if (provider.alarmRules.isEmpty) {
                  return _buildEmptyView();
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.alarmRules.length,
                  itemBuilder: (context, index) {
                    final rule = provider.alarmRules[index];
                    return _buildRuleCard(context, rule, provider);
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRuleDialog(context, null),
        tooltip: 'Add Rule',
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.rule_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Rules Defined',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Rules define when the alarm system is triggered',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showRuleDialog(context, null),
            icon: const Icon(Icons.add),
            label: const Text('Add First Rule'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRuleCard(BuildContext context, AlarmRuleModel rule, SecurityProvider provider) {
    // Get device name if available
    final device = provider.devices.firstWhere(
      (d) => d.deviceId == rule.deviceId,
      orElse: () => SecurityDeviceModel(
        deviceId: rule.deviceId,
        deviceType: 'unknown',
        name: 'Unknown Device',
        status: 'offline',
        isActive: false,
        lastUpdated: DateTime.now(),
      ),
    );
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(rule.icon),
            title: Text(
              rule.ruleName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(device.name),
            trailing: Switch(
              value: rule.isActive,
              activeColor: AppColors.success,
              onChanged: (value) {
                provider.toggleAlarmRuleActive(rule.ruleId, value);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Condition: ${rule.conditionText}',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Chip(
                  label: Text(rule.conditionType.toUpperCase()),
                  backgroundColor: _getRuleTypeColor(rule.conditionType).withOpacity(0.1),
                  labelStyle: TextStyle(color: _getRuleTypeColor(rule.conditionType)),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit Rule',
                  onPressed: () => _showRuleDialog(context, rule),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.error),
                  tooltip: 'Delete Rule',
                  onPressed: () => _confirmDeleteRule(rule),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getRuleTypeColor(String conditionType) {
    switch (conditionType) {
      case 'threshold':
        return Colors.purple;
      case 'status_change':
        return Colors.blue;
      case 'motion_detected':
        return Colors.orange;
      case 'schedule':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
  
  Future<void> _confirmDeleteRule(AlarmRuleModel rule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Rule'),
        content: Text('Are you sure you want to delete the rule "${rule.ruleName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = Provider.of<SecurityProvider>(context, listen: false);
      final success = await provider.deleteAlarmRule(rule.ruleId);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rule deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete rule')),
        );
      }
    }
  }
  
  void _resetFormValues() {
    _ruleNameController.text = '';
    _selectedDeviceId = null;
    _conditionType = 'threshold';
    _thresholdValue = null;
    _comparisonOperator = '>';
    _statusValue = null;
    _timeRestrictionStart = null;
    _timeRestrictionEnd = null;
    _daysActive = 'mon,tue,wed,thu,fri';
    _isActive = true;
  }
  
  void _loadRuleValues(AlarmRuleModel rule) {
    _ruleNameController.text = rule.ruleName;
    _selectedDeviceId = rule.deviceId;
    _conditionType = rule.conditionType;
    _thresholdValue = rule.thresholdValue;
    _comparisonOperator = rule.comparisonOperator ?? '>';
    _statusValue = rule.statusValue;
    
    // Convert DateTime to TimeOfDay
    _timeRestrictionStart = rule.timeRestrictionStart != null 
        ? TimeOfDay(hour: rule.timeRestrictionStart!.hour, minute: rule.timeRestrictionStart!.minute)
        : null;
    
    _timeRestrictionEnd = rule.timeRestrictionEnd != null 
        ? TimeOfDay(hour: rule.timeRestrictionEnd!.hour, minute: rule.timeRestrictionEnd!.minute)
        : null;
    
    _daysActive = rule.daysActive ?? 'mon,tue,wed,thu,fri';
    _isActive = rule.isActive;
  }
  
  Future<void> _showRuleDialog(BuildContext context, AlarmRuleModel? rule) async {
    _resetFormValues();
    
    if (rule != null) {
      _loadRuleValues(rule);
    }
    
    // Get the provider before entering the dialog builder
    final provider = Provider.of<SecurityProvider>(context, listen: false);
    
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        // Use dialogContext inside the builder, not the outer context
        // But use the provider instance we already grabbed
        title: Text(rule == null ? 'Add Rule' : 'Edit Rule'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _ruleNameController,
                  decoration: const InputDecoration(
                    labelText: 'Rule Name',
                    hintText: 'Enter a name for this rule',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a rule name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Device selection
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Device',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.devices),
                  ),
                  value: _selectedDeviceId,
                  hint: const Text('Select a device'),
                  isExpanded: true, // Make dropdown take full width
                  items: [
                    // Add general security devices
                    ...provider.devices.map((device) {
                      return DropdownMenuItem<int>(
                        value: device.deviceId,
                        child: Row(
                          children: [
                            Icon(
                              _getDeviceIcon(device.deviceType),
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${device.name} (${device.deviceType})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    
                    // Add sensors (if they have a different ID scheme)
                    ...provider.sensors.map((sensor) {
                      final deviceId = sensor.deviceId; // Assuming sensors have deviceId property
                      return DropdownMenuItem<int>(
                        value: deviceId,
                        child: Row(
                          children: [
                            Icon(
                              Icons.sensors,
                              size: 18, 
                              color: AppColors.info,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${sensor.name} (${sensor.sensorType} sensor)',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    
                    // Add cameras (if they have a different ID scheme)
                    ...provider.cameras.map((camera) {
                      final deviceId = camera.deviceId; // Assuming cameras have deviceId property
                      return DropdownMenuItem<int>(
                        value: deviceId,
                        child: Row(
                          children: [
                            Icon(
                              Icons.videocam,
                              size: 18,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${camera.name} (camera)',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedDeviceId = value;
                      // When device changes, update the available condition types
                      // based on the selected device type
                      _updateAvailableConditionTypes();
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a device';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Condition type
                const Text('Condition Type', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Threshold'),
                      selected: _conditionType == 'threshold',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _conditionType = 'threshold';
                          });
                        }
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Status Change'),
                      selected: _conditionType == 'status_change',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _conditionType = 'status_change';
                          });
                        }
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Motion'),
                      selected: _conditionType == 'motion_detected',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _conditionType = 'motion_detected';
                          });
                        }
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Schedule'),
                      selected: _conditionType == 'schedule',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _conditionType = 'schedule';
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Condition specific fields
                if (_conditionType == 'threshold') _buildThresholdFields(),
                if (_conditionType == 'status_change') _buildStatusChangeFields(),
                if (_conditionType == 'schedule') _buildScheduleFields(),
                
                const SizedBox(height: 16),
                
                // Active switch
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Active'),
                    Switch(
                      value: _isActive,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                Navigator.of(context).pop();
                
                final now = DateTime.now();
                
                final alarmRule = AlarmRuleModel(
                  ruleId: rule?.ruleId ?? 0, // Will be set by backend for new rule
                  alarmId: widget.alarmId,
                  ruleName: _ruleNameController.text,
                  deviceId: _selectedDeviceId!,
                  conditionType: _conditionType,
                  thresholdValue: _thresholdValue,
                  comparisonOperator: _conditionType == 'threshold' ? _comparisonOperator : null,
                  statusValue: _conditionType == 'status_change' ? _statusValue : null,
                  timeRestrictionStart: _conditionType == 'schedule' && _timeRestrictionStart != null
                    ? DateTime(now.year, now.month, now.day, _timeRestrictionStart!.hour, _timeRestrictionStart!.minute)
                    : null,
                  timeRestrictionEnd: _conditionType == 'schedule' && _timeRestrictionEnd != null
                    ? DateTime(now.year, now.month, now.day, _timeRestrictionEnd!.hour, _timeRestrictionEnd!.minute)
                    : null,
                  daysActive: _conditionType == 'schedule' ? _daysActive : null,
                  isActive: _isActive,
                  createdAt: rule?.createdAt ?? now,
                  updatedAt: now,
                );
                
                bool success;
                if (rule == null) {
                  success = await provider.saveAlarmRule(alarmRule);
                } else {
                  success = await provider.updateAlarmRule(alarmRule);
                }
                
                if (success) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(rule == null ? 'Rule added successfully' : 'Rule updated successfully')),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(rule == null ? 'Failed to add rule' : 'Failed to update rule')),
                    );
                  }
                }
              }
            },
            child: Text(rule == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildThresholdFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Threshold Configuration'),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _comparisonOperator,
                decoration: const InputDecoration(
                  labelText: 'Operator',
                ),
                items: [
                  const DropdownMenuItem(value: '>', child: Text('>')),
                  const DropdownMenuItem(value: '<', child: Text('<')),
                  const DropdownMenuItem(value: '>=', child: Text('>=')),
                  const DropdownMenuItem(value: '<=', child: Text('<=')),
                  const DropdownMenuItem(value: '=', child: Text('=')),
                  const DropdownMenuItem(value: '<>', child: Text('≠')),
                ],
                onChanged: (value) {
                  setState(() {
                    _comparisonOperator = value!;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Value',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                initialValue: _thresholdValue?.toString() ?? '',
                onChanged: (value) {
                  setState(() {
                    _thresholdValue = double.tryParse(value);
                  });
                },
                validator: (value) {
                  if (_conditionType == 'threshold') {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a threshold value';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildStatusChangeFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Status Change Configuration'),
        DropdownButtonFormField<String>(
          value: _statusValue,
          decoration: const InputDecoration(
            labelText: 'Status Value',
          ),
          items: [
            const DropdownMenuItem(value: 'breached', child: Text('Breached')),
            const DropdownMenuItem(value: 'secured', child: Text('Secured')),
            const DropdownMenuItem(value: 'offline', child: Text('Offline')),
          ],
          onChanged: (value) {
            setState(() {
              _statusValue = value;
            });
          },
          validator: (value) {
            if (_conditionType == 'status_change' && (value == null || value.isEmpty)) {
              return 'Please select a status value';
            }
            return null;
          },
        ),
      ],
    );
  }
  
  Widget _buildScheduleFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Schedule Configuration'),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Start Time',
                ),
                readOnly: true,
                controller: TextEditingController(
                  text: _timeRestrictionStart != null 
                      ? '${_timeRestrictionStart!.hour}:${_timeRestrictionStart!.minute.toString().padLeft(2, '0')}'
                      : '',
                ),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _timeRestrictionStart ?? const TimeOfDay(hour: 8, minute: 0),
                  );
                  if (time != null) {
                    setState(() {
                      _timeRestrictionStart = time;
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'End Time',
                ),
                readOnly: true,
                controller: TextEditingController(
                  text: _timeRestrictionEnd != null 
                      ? '${_timeRestrictionEnd!.hour}:${_timeRestrictionEnd!.minute.toString().padLeft(2, '0')}'
                      : '',
                ),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _timeRestrictionEnd ?? const TimeOfDay(hour: 18, minute: 0),
                  );
                  if (time != null) {
                    setState(() {
                      _timeRestrictionEnd = time;
                    });
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Active Days'),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('Mon'),
              selected: _daysActive.contains('mon'),
              onSelected: (selected) {
                setState(() {
                  _daysActive = _updateDaySelection('mon', selected);
                });
              },
            ),
            FilterChip(
              label: const Text('Tue'),
              selected: _daysActive.contains('tue'),
              onSelected: (selected) {
                setState(() {
                  _daysActive = _updateDaySelection('tue', selected);
                });
              },
            ),
            FilterChip(
              label: const Text('Wed'),
              selected: _daysActive.contains('wed'),
              onSelected: (selected) {
                setState(() {
                  _daysActive = _updateDaySelection('wed', selected);
                });
              },
            ),
            FilterChip(
              label: const Text('Thu'),
              selected: _daysActive.contains('thu'),
              onSelected: (selected) {
                setState(() {
                  _daysActive = _updateDaySelection('thu', selected);
                });
              },
            ),
            FilterChip(
              label: const Text('Fri'),
              selected: _daysActive.contains('fri'),
              onSelected: (selected) {
                setState(() {
                  _daysActive = _updateDaySelection('fri', selected);
                });
              },
            ),
            FilterChip(
              label: const Text('Sat'),
              selected: _daysActive.contains('sat'),
              onSelected: (selected) {
                setState(() {
                  _daysActive = _updateDaySelection('sat', selected);
                });
              },
            ),
            FilterChip(
              label: const Text('Sun'),
              selected: _daysActive.contains('sun'),
              onSelected: (selected) {
                setState(() {
                  _daysActive = _updateDaySelection('sun', selected);
                });
              },
            ),
          ],
        ),
      ],
    );
  }
  
  String _updateDaySelection(String day, bool selected) {
    final days = _daysActive.split(',');
    if (selected && !days.contains(day)) {
      days.add(day);
    } else if (!selected) {
      days.remove(day);
    }
    return days.where((d) => d.isNotEmpty).join(',');
  }
  
  void _updateAvailableConditionTypes() {
    if (_selectedDeviceId == null) return;
    
    // Find the selected device's type from all possible sources
    String? deviceType;
    
    // Use the stored provider reference instead of accessing through context
    // Check if it's a regular device
    final regularDevice = _securityProvider.devices.firstWhere(
      (d) => d.deviceId == _selectedDeviceId,
      orElse: () => SecurityDeviceModel(
        deviceId: -1,
        deviceType: 'unknown',
        name: 'Unknown Device',
        status: 'offline',
        isActive: false,
        lastUpdated: DateTime.now(),
      ),
    );
    
    if (regularDevice.deviceId != -1) {
      deviceType = regularDevice.deviceType;
    }
    
    // Check if it's a sensor - also use the stored provider
    if (deviceType == null) {
      final sensor = _securityProvider.sensors.firstWhere(
        (s) => s.deviceId == _selectedDeviceId,
        orElse: () => SensorModel(
          sensorId: -1,
          deviceId: -1,
          sensorType: 'unknown',
          name: 'Unknown Sensor', 
          type: '', 
          unit: '', 
          minValue: 0, 
          maxValue: 0, 
          warningThreshold: 0, 
          updatedAt: DateTime.now(), 
          criticalThreshold: 0, 
          createdAt: DateTime.now(),
        ),
      );
      
      if (sensor.sensorId != -1) {
        deviceType = 'sensor';
      }
    }
    
    // Check if it's a camera - also use the stored provider
    if (deviceType == null) {
      final camera = _securityProvider.cameras.firstWhere(
        (c) => c.deviceId == _selectedDeviceId,
        orElse: () => CameraModel(
          cameraId: -1,
          deviceId: -1,
          name: 'Unknown Sensor',
          streamUrl: '', 
          motionDetectionEnabled: false,
        ),
      );
      
      if (camera.cameraId != -1) {
        deviceType = 'camera';
      }
    }
    
    // Default to most common condition type if we couldn't determine the device type
    if (deviceType == null) {
      setState(() {
        _conditionType = 'threshold';
      });
      return;
    }
    
    // Set appropriate condition type based on device type
    setState(() {
      switch (deviceType!.toLowerCase()) {
        case 'sensor':
          _conditionType = 'threshold';
          break;
        case 'camera':
          _conditionType = 'motion_detected';
          break;
        case 'door':
        case 'window':
          _conditionType = 'status_change';
          break;
        default:
          _conditionType = 'threshold';
      }
    });
  }
}

IconData _getDeviceIcon(String deviceType) {
  switch (deviceType.toLowerCase()) {
    case 'sensor':
      return Icons.sensors;
    case 'camera':
      return Icons.videocam;
    case 'actuator':
      return Icons.flash_on;
    case 'motion':
      return Icons.motion_photos_on;
    case 'door':
      return Icons.sensor_door;
    case 'window':
      return Icons.window;
    case 'temperature':
      return Icons.thermostat;
    default:
      return Icons.devices_other;
  }
}