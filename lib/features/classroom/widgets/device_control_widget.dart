import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/device_model.dart';
import '../../../core/models/actuator_model.dart';
import '../../../core/models/sensor_model.dart';

class DeviceControlWidget extends StatelessWidget {
  final dynamic device; // Can be DeviceModel, SensorModel, or ActuatorModel
  final Function(bool)? onToggle;
  final Function(double)? onValueChanged;

  const DeviceControlWidget({
    super.key,
    required this.device,
    this.onToggle,
    this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDevice = device is DeviceModel;
    final isSensor = device is SensorModel;
    final isActuator = device is ActuatorModel;
    
    // Get common properties based on device type
    final String name = isDevice ? device.name : 
                        isSensor ? device.name : 
                        isActuator ? device.name : 'Unknown Device';
    
    final String type = isDevice ? device.deviceType : 
                       isSensor ? device.type : 
                       isActuator ? device.type : 'unknown';
    
    final bool isToggleable = isDevice ? device.isToggleable : 
                             isActuator ? true : false;
    
    final bool isAdjustable = isDevice ? device.isAdjustable :
                              isActuator ? device.type == 'fan' || device.type == 'ac' : false;
    
    final bool isOn = isDevice ? device.isOnline : 
                     isActuator ? device.isOn : false;
    
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Device name and icon
            Row(
              children: [
                Icon(
                  _getDeviceIcon(type, isOn),
                  size: 24,
                  color: isOn ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        _getDeviceTypeDisplayName(type),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Toggle switch for controllable devices
                if (isToggleable && onToggle != null)
                  Switch(
                    value: isOn,
                    onChanged: onToggle,
                    activeColor: AppColors.primary,
                  ),
              ],
            ),
            
            // Slider for adjustable devices (like fan speed, thermostat)
            if (isAdjustable && onValueChanged != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Intensity',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${_getSliderValue()}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _getSliderValue(),
                      min: 0,
                      max: 100,
                      divisions: 10,
                      activeColor: AppColors.primary,
                      inactiveColor: AppColors.primary.withOpacity(0.3),
                      onChanged: isOn ? (value) {
                        onValueChanged!(value);
                      } : null,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getDeviceIcon(String type, bool isOn) {
    switch (type) {
      case 'light':
        return isOn ? Icons.lightbulb : Icons.lightbulb_outline;
      case 'fan':
        return isOn ? Icons.air : Icons.air_outlined;
      case 'door':
        return isOn ? Icons.meeting_room : Icons.meeting_room_outlined;
      case 'window':
        return isOn ? Icons.window : Icons.window_outlined;
      case 'ac':
        return isOn ? Icons.ac_unit : Icons.ac_unit_outlined;
      case 'temperature':
        return Icons.thermostat;
      case 'humidity':
        return Icons.water_drop;
      case 'gas':
        return Icons.cloud;
      case 'motion':
        return Icons.motion_photos_on;
      default:
        return Icons.device_unknown;
    }
  }

  String _getDeviceTypeDisplayName(String type) {
    switch (type) {
      case 'light':
        return 'Light';
      case 'fan':
        return 'Fan';
      case 'door':
        return 'Door';
      case 'window':
        return 'Window';
      case 'ac':
        return 'Air Conditioner';
      case 'temperature':
        return 'Temperature Sensor';
      case 'humidity':
        return 'Humidity Sensor';
      case 'gas':
        return 'Air Quality Sensor';
      case 'motion':
        return 'Motion Sensor';
      default:
        return type.substring(0, 1).toUpperCase() + type.substring(1);
    }
  }

  double _getSliderValue() {
    if (device is DeviceModel && device.isAdjustable) {
      // For actual implementation, we'd need to get the current value
      // from the device model and normalize it to 0-100 scale
      return 50; // Default value for example
    } else if (device is ActuatorModel && 
        (device.type == 'fan' || device.type == 'ac')) {
      // Similar to above, we'd need the actual value
      return 50; // Default value for example
    }
    return 0;
  }
} 