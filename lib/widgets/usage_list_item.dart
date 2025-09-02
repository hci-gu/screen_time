import 'package:flutter/material.dart';
import 'package:screen_time/theme/app_theme.dart';

class UsageListItem extends StatelessWidget {
  final String hour;
  final int usage;

  const UsageListItem({
    Key? key,
    required this.hour,
    required this.usage,
  }) : super(key: key);

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  Color _getUsageColor() {
    if (usage == 0) return AppTheme.primary.withValues(alpha: 0.3);
    return AppTheme.primary;
  }

  IconData _getUsageIcon() {
    if (usage == 0) return Icons.phone_disabled;
    return Icons.phone_android;
  }

  @override
  Widget build(BuildContext context) {
    final timeString = '${int.parse(hour).toString().padLeft(2, '0')}:00';
    final timeEndString =
        '${(int.parse(hour) + 1).toString().padLeft(2, '0')}:00';
    final usageColor = _getUsageColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: usageColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getUsageIcon(),
              color: usageColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$timeString - $timeEndString',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                ),
                if (usage > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    _formatDuration(usage),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primary.withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                usage > 0 ? _formatDuration(usage) : 'Ingen användning',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: usageColor,
                    ),
              ),
              if (usage > 0) ...[
                const SizedBox(height: 2),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
