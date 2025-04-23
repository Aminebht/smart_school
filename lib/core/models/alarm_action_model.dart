import 'package:flutter/material.dart';

class AlarmActionModel {
  final int actionId;
  final int alarmId;
  final int ruleId;
  final String actionType; // 'notify', 'actuate', 'record', 'external'
  final int? actuatorId;
  final String? targetState;
  final String? notificationSeverity; // 'info', 'warning', 'critical'
  final String? notificationMessage;
  final List<int>? notifyUserIds;
  final String? externalWebhookUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  AlarmActionModel({
    required this.actionId,
    required this.alarmId,
    required this.ruleId,
    required this.actionType,
    this.actuatorId,
    this.targetState,
    this.notificationSeverity,
    this.notificationMessage,
    this.notifyUserIds,
    this.externalWebhookUrl,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory AlarmActionModel.fromJson(Map<String, dynamic> json) {
    return AlarmActionModel(
      actionId: json['action_id'],
      alarmId: json['alarm_id'],
      ruleId: json['rule_id'],
      actionType: json['action_type'],
      actuatorId: json['actuator_id'],
      targetState: json['target_state'],
      notificationSeverity: json['notification_severity'],
      notificationMessage: json['notification_message'],
      notifyUserIds: json['notify_user_ids'] != null 
          ? List<int>.from(json['notify_user_ids'])
          : null,
      externalWebhookUrl: json['external_webhook_url'],
      isActive: json['is_active'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'action_id': actionId,
      'alarm_id': alarmId,
      'rule_id': ruleId,
      'action_type': actionType,
      'actuator_id': actuatorId,
      'target_state': targetState,
      'notification_severity': notificationSeverity,
      'notification_message': notificationMessage,
      'notify_user_ids': notifyUserIds,
      'external_webhook_url': externalWebhookUrl,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
  
  IconData get actionIcon {
    switch (actionType) {
      case 'notify':
        return Icons.notifications;
      case 'actuate':
        return Icons.touch_app;
      case 'record':
        return Icons.videocam;
      case 'external':
        return Icons.cloud_upload;
      default:
        return Icons.settings;
    }
  }
  
  Color get severityColor {
    switch (notificationSeverity?.toLowerCase()) {
      case 'info':
        return Colors.blue;
      case 'warning':
        return Colors.orange;
      case 'critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  String get actionDescription {
    switch (actionType) {
      case 'notify':
        return 'Send ${notificationSeverity ?? ''} notification';
      case 'actuate':
        return 'Set actuator to ${targetState ?? 'on'}';
      case 'record':
        return 'Start recording';
      case 'external':
        return 'Call external service';
      default:
        return actionType;
    }
  }

  IconData get icon {
    switch (actionType) {
      case 'notify':
        return Icons.notifications;
      case 'actuate':
        return Icons.touch_app;
      case 'record':
        return Icons.videocam;
      case 'external':
        return Icons.link;
      default:
        return Icons.flash_on;
    }
  }

  Color get color {
    if (actionType == 'notify' && notificationSeverity != null) {
      switch (notificationSeverity) {
        case 'critical':
          return Colors.red;
        case 'warning':
          return Colors.orange;
        case 'info':
        default:
          return Colors.blue;
      }
    } else if (actionType == 'actuate') {
      return Colors.green;
    } else if (actionType == 'record') {
      return Colors.purple;
    } else if (actionType == 'external') {
      return Colors.teal;
    } else {
      return Colors.grey;
    }
  }
}