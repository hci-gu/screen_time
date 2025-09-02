import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_time/providers/usage_provider.dart';
import 'package:screen_time/providers/user_provider.dart';
import 'package:screen_time/theme/app_theme.dart';
import 'package:screen_time/widgets/total_usage_text.dart';
import 'dart:io';

class ScreentimeViewPage extends ConsumerWidget {
  const ScreentimeViewPage({super.key});

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    final months = [
      'januari',
      'februari',
      'mars',
      'april',
      'maj',
      'juni',
      'juli',
      'augusti',
      'september',
      'oktober',
      'november',
      'december'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _getWeekday(String dateString) {
    final date = DateTime.parse(dateString);
    final weekdays = [
      'måndag',
      'tisdag',
      'onsdag',
      'torsdag',
      'fredag',
      'lördag',
      'söndag'
    ];
    return weekdays[date.weekday - 1];
  }

  bool _isToday(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  void _changeDate(WidgetRef ref, int dayOffset) {
    final usageState = ref.read(usageProvider);
    final currentDate = DateTime.parse(usageState.date);
    final newDate = currentDate.add(Duration(days: dayOffset));
    final newDateString =
        "${newDate.year}-${newDate.month.toString().padLeft(2, '0')}-${newDate.day.toString().padLeft(2, '0')}";
    ref.read(usageProvider.notifier).updateDate(newDateString);
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Platform.isAndroid) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.background,
          title: const Text(
            'Skärmtid',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
          centerTitle: true,
          elevation: 0.5,
          shadowColor: Colors.transparent,
          iconTheme: const IconThemeData(color: AppTheme.primary),
        ),
        body: const Center(
          child: Text(
            'Skärmtidsdata är endast tillgänglig på Android',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final usageState = ref.watch(usageProvider);
    final usageNotifier = ref.read(usageProvider.notifier);
    final userState = ref.watch(userIdProvider);
    final userId = userState.userId;

    final totalSeconds = usageState.usageData.values.fold(0, (a, b) => a + b);
    final isToday = _isToday(usageState.date);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: const Text(
          'Skärmtid',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.primary,
          ),
        ),
        centerTitle: true,
        elevation: 0.5,
        shadowColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppTheme.primary),
        actions: [
          if (usageNotifier.isAndroid)
            IconButton(
              icon: const Icon(Icons.cloud_upload),
              onPressed: () async {
                if (userId != null && userId.isNotEmpty) {
                  final success = await usageNotifier.uploadLast7Days(userId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success
                            ? 'Data uppladdad!'
                            : 'Uppladdning misslyckades.'),
                      ),
                    );
                  }
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: AppTheme.background,
              border: Border(
                bottom: BorderSide(color: AppTheme.cardBorder, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => _changeDate(ref, -1),
                  icon: const Icon(Icons.chevron_left),
                  color: AppTheme.primary,
                ),
                Expanded(
                  child: Column(
                    children: [
                      if (isToday) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'IDAG',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        _formatDate(usageState.date),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                      ),
                      Text(
                        _getWeekday(usageState.date),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.primary.withValues(alpha: 0.7),
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: isToday ? null : () => _changeDate(ref, 1),
                  icon: const Icon(Icons.chevron_right),
                  color: isToday
                      ? AppTheme.primary.withValues(alpha: 0.3)
                      : AppTheme.primary,
                ),
              ],
            ),
          ),
          Expanded(
            child: usageState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.phone_android,
                                  size: 48,
                                  color:
                                      AppTheme.primary.withValues(alpha: 0.7),
                                ),
                                const SizedBox(height: 16),
                                if (totalSeconds > 0) ...[
                                  TotalUsageText(
                                      totalMins: totalSeconds / 60.0),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Total skärmtid',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          color: AppTheme.primary
                                              .withValues(alpha: 0.7),
                                        ),
                                  ),
                                ] else ...[
                                  Text(
                                    'Ingen användning',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primary,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Ingen skärmtid registrerad',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          color: AppTheme.primary
                                              .withValues(alpha: 0.7),
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (totalSeconds > 0) ...[
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  'Mest aktiv timme',
                                  _getMostActiveHour(usageState.usageData),
                                  Icons.schedule,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  'Första användning',
                                  _getFirstUsage(usageState.usageData),
                                  Icons.wb_sunny,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      BuildContext context, String label, String value, IconData icon) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon,
                color: AppTheme.primary.withValues(alpha: 0.7), size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primary.withValues(alpha: 0.7),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getMostActiveHour(Map<String, int> usageData) {
    if (usageData.isEmpty) return '--';
    final maxEntry =
        usageData.entries.reduce((a, b) => a.value > b.value ? a : b);
    final hour = int.parse(maxEntry.key);
    final timeString = '${hour.toString().padLeft(2, '0')}:00';
    return '$timeString\n${_formatDuration(maxEntry.value)}';
  }

  String _getFirstUsage(Map<String, int> usageData) {
    if (usageData.isEmpty) return '--';
    final sortedEntries = usageData.entries
        .where((entry) => entry.value > 0)
        .toList()
      ..sort((a, b) => int.parse(a.key).compareTo(int.parse(b.key)));

    if (sortedEntries.isEmpty) return '--';

    final hour = int.parse(sortedEntries.first.key);
    return '${hour.toString().padLeft(2, '0')}:00';
  }
}
