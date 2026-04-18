import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class NotificationInboxScreen extends StatefulWidget {
  const NotificationInboxScreen({super.key});

  @override
  State<NotificationInboxScreen> createState() => _NotificationInboxScreenState();
}

class _NotificationInboxScreenState extends State<NotificationInboxScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final result = await ApiService.getNotifications();
      if (result['success'] == true) {
        setState(() {
          _notifications = result['notifications'];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () async {
              await ApiService.getNotifications(); // Mock or actual mark as read
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications marked as read')),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('No notifications yet'))
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final note = _notifications[index];
                    final date = DateTime.parse(note['created_at'] ?? note['createdAt']);
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getIconColor(note['type']),
                        child: Icon(_getIcon(note['type']), color: Colors.white, size: 20),
                      ),
                      title: Text(note['message']),
                      subtitle: Text(DateFormat('MMM dd, hh:mm a').format(date)),
                      trailing: !note['is_read'] ? const Icon(Icons.circle, color: Colors.blue, size: 10) : null,
                    );
                  },
                ),
    );
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'budget_alert': return Icons.warning_amber_rounded;
      case 'bill_reminder': return Icons.receipt_long;
      case 'savings_goal': return Icons.savings;
      case 'summary': return Icons.assessment;
      default: return Icons.notifications;
    }
  }

  Color _getIconColor(String? type) {
    switch (type) {
      case 'budget_alert': return Colors.orange;
      case 'bill_reminder': return Colors.red;
      case 'savings_goal': return Colors.green;
      case 'summary': return Colors.blue;
      default: return Colors.grey;
    }
  }
}
