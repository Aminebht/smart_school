import 'package:flutter/material.dart';
import '../../../core/models/security_event_model.dart';

class SecurityEventList extends StatelessWidget {
  final List<SecurityEventModel> events;
  final Function(int)? onAcknowledge;
  final bool compact;  // Added this parameter
  final int? maxEvents;  // Added this parameter
  
  const SecurityEventList({
    Key? key, 
    required this.events,
    this.onAcknowledge,
    this.compact = false,  // Default to false
    this.maxEvents,  // Default to null (no limit)
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Apply maxEvents if specified
    final displayEvents = maxEvents != null && maxEvents! < events.length
        ? events.take(maxEvents!).toList()
        : events;
    
    return ListView.builder(
      // Make it non-scrollable in compact mode if inside another scrollable
      shrinkWrap: compact,
      physics: compact ? const NeverScrollableScrollPhysics() : null,
      itemCount: displayEvents.length,
      itemBuilder: (context, index) {
        final event = displayEvents[index];
        return _buildEventCard(context, event);
      },
    );
  }
  
  Widget _buildEventCard(BuildContext context, SecurityEventModel event) {
    // Get the severity color
    
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: 16, 
        vertical: compact ? 4 : 8, // Smaller margins in compact mode
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 8.0 : 16.0), // Smaller padding in compact mode
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // First row: Title and timestamp
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    event.eventType,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: compact ? 14 : 16, // Smaller font in compact mode
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _formatTimestamp(event.timestamp),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: compact ? 10 : 12, // Smaller font in compact mode
                  ),
                ),
              ],
            ),
            
            SizedBox(height: compact ? 4 : 8), // Smaller spacing in compact mode
            
            // Location and device info
            Text(
              '${event.deviceName}',
              style: TextStyle(fontSize: compact ? 12 : 14), // Smaller font in compact mode
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            // Only show description in non-compact mode
            if (!compact) ...[
              const SizedBox(height: 8),
              Text(
                event.description,
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            
            SizedBox(height: compact ? 4 : 8), // Smaller spacing in compact mode
            
            // Last row: Severity indicator and acknowledge button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 6 : 8, 
                    vertical: compact ? 2 : 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
  
                ),
                
                // Acknowledged indicator or button
                if (event.isAcknowledged)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, 
                           size: compact ? 14 : 16, 
                           color: Colors.green),
                      SizedBox(width: compact ? 2 : 4),
                      Text(
                        'ACKNOWLEDGED',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: compact ? 10 : 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                else if (onAcknowledge != null)
                  TextButton(
                    onPressed: () {
                      // Show a small loading indicator when acknowledging
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                      
                      // Call the acknowledge method without expecting a Future return
                      onAcknowledge!(event.eventId);
                      
                      // Close the loading indicator after a short delay
                      Future.delayed(const Duration(milliseconds: 500), () {
                        // Check if dialog is still showing before popping
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 4 : 8,
                      ),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'ACKNOWLEDGE', 
                      style: TextStyle(
                        fontSize: compact ? 10 : 12,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatTimestamp(DateTime timestamp) {
    // Simple formatter for the timestamp
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
  }
}