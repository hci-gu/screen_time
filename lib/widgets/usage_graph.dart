import 'package:flutter/material.dart';
import 'package:screen_time/theme/app_theme.dart';
import 'graph_bar.dart';

class UsageGraph extends StatelessWidget {
  final Map<String, int> usageData;
  const UsageGraph({Key? key, required this.usageData}) : super(key: key);

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final actualMaxValue = usageData.values.isEmpty
        ? 3600
        : usageData.values.reduce((a, b) => a > b ? a : b);
    final maxValue = actualMaxValue < 1800 ? 3600 : actualMaxValue * 1.2;
    final sortedEntries = usageData.entries.toList()
      ..sort((a, b) => int.parse(a.key).compareTo(int.parse(b.key)));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Skärmtid per timme',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableHeight = constraints.maxHeight - 40;
                  final graphHeight = availableHeight.clamp(150.0, 250.0);

                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          SizedBox(
                            width: 40,
                            height: graphHeight,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(_formatDuration(maxValue.round()),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: AppTheme.primary
                                                .withValues(alpha: 0.7))),
                                Text(_formatDuration((maxValue * 0.75).round()),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: AppTheme.primary
                                                .withValues(alpha: 0.7))),
                                Text(_formatDuration((maxValue * 0.5).round()),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: AppTheme.primary
                                                .withValues(alpha: 0.7))),
                                Text(_formatDuration((maxValue * 0.25).round()),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: AppTheme.primary
                                                .withValues(alpha: 0.7))),
                                Text('0',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: AppTheme.primary
                                                .withValues(alpha: 0.7))),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: graphHeight,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: sortedEntries.map((entry) {
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 1),
                                      child: GraphBar(
                                        usage: entry.value,
                                        maxUsage: maxValue.round(),
                                        hour: entry.key,
                                        maxHeight: graphHeight - 20,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const SizedBox(width: 48),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('00',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: AppTheme.primary
                                                .withValues(alpha: 0.7))),
                                Text('06',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: AppTheme.primary
                                                .withValues(alpha: 0.7))),
                                Text('12',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: AppTheme.primary
                                                .withValues(alpha: 0.7))),
                                Text('18',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: AppTheme.primary
                                                .withValues(alpha: 0.7))),
                                Text('23',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            color: AppTheme.primary
                                                .withValues(alpha: 0.7))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: AppTheme.primary.withValues(alpha: 0.7)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tryck på en stapel för att se exakt tid',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.primary.withValues(alpha: 0.7),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
