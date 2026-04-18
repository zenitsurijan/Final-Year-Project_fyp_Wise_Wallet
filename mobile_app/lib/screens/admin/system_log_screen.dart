import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_card.dart';
import 'package:intl/intl.dart';

class SystemLogScreen extends StatefulWidget {
  const SystemLogScreen({super.key});

  @override
  State<SystemLogScreen> createState() => _SystemLogScreenState();
}

class _SystemLogScreenState extends State<SystemLogScreen> {
  String _filterLevel = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).fetchSystemLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = Provider.of<AdminProvider>(context);
    final allLogs = adminProvider.systemLogs;

    // Apply filter
    final logs = _filterLevel == 'all'
        ? allLogs
        : allLogs.where((l) => l['level'] == _filterLevel).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('System Audit Log'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryStart),
            onPressed: () => adminProvider.fetchSystemLogs(),
          ),
        ],
      ),
      body: adminProvider.isLoading && allLogs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter chips
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
                  color: Colors.white,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', 'all', Colors.grey),
                        const SizedBox(width: 8),
                        _buildFilterChip('Info', 'info', Colors.blue),
                        const SizedBox(width: 8),
                        _buildFilterChip('Warning', 'warning', Colors.orange),
                        const SizedBox(width: 8),
                        _buildFilterChip('Error', 'error', Colors.red),
                        const SizedBox(width: 8),
                        _buildFilterChip('Critical', 'critical', Colors.red.shade900),
                      ],
                    ),
                  ),
                ),
                // Count bar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.xs),
                  color: AppColors.background,
                  child: Text(
                    '${logs.length} events',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  child: logs.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.m),
                          itemCount: logs.length,
                          itemBuilder: (context, index) {
                            final log = logs[index];
                            final timestamp = DateTime.tryParse(log['timestamp'] ?? '') ?? DateTime.now();
                            final level = log['level'] ?? 'info';

                            // Show date separator
                            final showDate = index == 0 ||
                                DateFormat('yyyy-MM-dd').format(DateTime.tryParse(logs[index - 1]['timestamp'] ?? '') ?? DateTime.now()) !=
                                    DateFormat('yyyy-MM-dd').format(timestamp);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (showDate)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: AppSpacing.s, top: AppSpacing.s),
                                    child: Text(
                                      DateFormat('EEEE, MMM dd yyyy').format(timestamp),
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary.withOpacity(0.7)),
                                    ),
                                  ),
                                _buildLogItem(log, timestamp, level),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChip(String label, String level, Color color) {
    final isSelected = _filterLevel == level;
    return GestureDetector(
      onTap: () => setState(() => _filterLevel = level),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : Colors.grey.shade200),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No audit events found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            _filterLevel == 'all'
                ? 'System events will appear here as users interact with the app'
                : 'No $_filterLevel level events recorded yet',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => Provider.of<AdminProvider>(context, listen: false).fetchSystemLogs(),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem(dynamic log, DateTime timestamp, String level) {
    Color levelColor = AppColors.primaryStart;
    IconData icon = Icons.info_outline;

    if (level == 'warning') {
      levelColor = Colors.orange;
      icon = Icons.warning_amber_rounded;
    } else if (level == 'error') {
      levelColor = Colors.red;
      icon = Icons.error_outline;
    } else if (level == 'critical') {
      levelColor = Colors.red.shade900;
      icon = Icons.dangerous_outlined;
    }

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.m),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Timeline bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: levelColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: levelColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: levelColor, size: 18),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  log['event'] ?? 'SYSTEM_EVENT',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: levelColor,
                                    fontSize: 11,
                                    letterSpacing: 1.1,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.grey.shade200),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  DateFormat('HH:mm:ss').format(timestamp),
                                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontFamily: 'monospace'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            log['description'] ?? 'No detail provided',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          if (log['userId'] != null && log['userId'] is Map) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade100),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.person_outline, size: 12, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      '${log['userId']['name'] ?? 'Unknown'} (${log['userId']['email'] ?? ''})',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
