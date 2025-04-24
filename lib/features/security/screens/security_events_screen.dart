import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_school/core/models/security_event_model.dart';
import '../providers/security_provider.dart';
import '../widgets/security_event_list.dart';
import '../../../core/constants/app_constants.dart';

class SecurityEventsScreen extends StatefulWidget {
  const SecurityEventsScreen({super.key});

  @override
  State<SecurityEventsScreen> createState() => _SecurityEventsScreenState();
}

class _SecurityEventsScreenState extends State<SecurityEventsScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Unacknowledged'];
  
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure we're not in a build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvents();
    });
  }

  Future<void> _loadEvents() async {
    final provider = Provider.of<SecurityProvider>(context, listen: false);
    await provider.loadSecurityEvents(limit: 50);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Events'),
      ),
      body: Column(
        children: [
          // Filters
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = filter == _selectedFilter;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),
          
          // Events list
          Expanded(
            child: Consumer<SecurityProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.errorMessage != null && provider.events.isEmpty) {
                  return _buildErrorView(provider);
                }

                final events = _filterEvents(provider);
                
                if (events.isEmpty) {
                  return const Center(
                    child: Text('No events match the current filter'),
                  );
                }
                
                return SecurityEventList(
                  events: _filterEvents(provider),
                  onAcknowledge: (eventId) {
                    // Return void instead of Future
                    provider.acknowledgeSecurityEvent(eventId);
                    // Optional: refresh the list after a short delay
                    Future.delayed(const Duration(milliseconds: 1000), () {
                      if (mounted) _loadEvents();
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  List<SecurityEventModel> _filterEvents(SecurityProvider provider) {
    final events = provider.events;
    
    switch (_selectedFilter) {
      case 'Unacknowledged':
        return events.where((e) => !e.isAcknowledged).toList();
      default:
        return events;
    }
  }
  
  Widget _buildErrorView(SecurityProvider provider) {
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
            onPressed: () {
              Future.microtask(() {
                _loadEvents();
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}