import 'package:flutter/material.dart';
import 'package:screen_time/theme/app_theme.dart';
import 'usage_list_item.dart';

class UsageList extends StatelessWidget {
  final Map<String, int> usageData;
  const UsageList({Key? key, required this.usageData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sortedEntries = usageData.entries.toList()
      ..sort((a, b) => int.parse(a.key).compareTo(int.parse(b.key)));

    final totalUsage = usageData.values.fold(0, (a, b) => a + b);
    final avgUsage = usageData.isNotEmpty ? totalUsage / usageData.length : 0;
    final maxUsage = usageData.values.isEmpty
        ? 0
        : usageData.values.reduce((a, b) => a > b ? a : b);
    final activeHours = usageData.values.where((usage) => usage > 60).length;

    return Column(
      children: [
        Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Sammanfattning',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        context,
                        'Totalt',
                        _formatDuration(totalUsage),
                        Icons.timer,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        'Snitt/timme',
                        _formatDuration(avgUsage.round()),
                        Icons.trending_up,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        context,
                        'Mest aktiv',
                        _formatDuration(maxUsage),
                        Icons.trending_up_outlined,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        'Aktiva timmar',
                        '$activeHours st',
                        Icons.access_time,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.05),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, color: AppTheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Timvis användning',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primary,
                                ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: sortedEntries.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: AppTheme.cardBorder,
                      indent: 16,
                      endIndent: 16,
                    ),
                    itemBuilder: (context, index) {
                      final entry = sortedEntries[index];

                      return UsageListItem(
                        hour: entry.key,
                        usage: entry.value,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
      BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: AppTheme.primary.withValues(alpha: 0.7)),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primary.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}
