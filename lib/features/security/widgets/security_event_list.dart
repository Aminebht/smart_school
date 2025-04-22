import 'package:flutter/material.dart';
import '../../../core/models/security_event_model.dart';
import '../../../core/constants/app_constants.dart';

class SecurityEventList extends StatelessWidget {
  final List<SecurityEventModel> events;
  final Function(int) onAcknowledge;
  final bool compact;
  final int? maxEvents;
  
  const SecurityEventList({
    super.key, 
    required this.events,
    required this.onAcknowledge,
    this.compact = false,
    this.maxEvents,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return _buildEmptyState();
    }
    
    final displayEvents = maxEvents != null && events.length > maxEvents!
        ? events.sublist(0, maxEvents)
        : events;
        
    return ListView.builder(
      shrinkWrap: true,
      physics: compact
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      itemCount: displayEvents.length,
      itemBuilder: (context, index) {
        final event = displayEvents[index];
        return _buildEventItem(context, event);
      },
    );
  }
  
  Widget _buildEventItem(BuildContext context, SecurityEventModel event) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: event.eventColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: event.eventColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            event.eventIcon,
            color: event.eventColor,
            size: 20,
          ),
        ),
        title: Text(
          _formatEventType(event.eventType),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.description,
              maxLines: compact ? 1 : 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${event.deviceName}${event.classroomName != null ? ' (${event.classroomName})' : ''}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              event.timeAgo,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            if (!event.isAcknowledged && !compact)
              TextButton(
                onPressed: () => onAcknowledge(event.eventId),
                child: const Text('Acknowledge'),
              ),
            if (event.isAcknowledged)
              const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 16,
              ),
          ],
        ),
        onTap: compact
            ? () {
                if (!event.isAcknowledged) {
                  onAcknowledge(event.eventId);
                }
              }
            : null,
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note,
            size: 64,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            'No security events found',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatEventType(String eventType) {
    return eventType
        .split('_')
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}