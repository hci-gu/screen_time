import 'package:flutter/material.dart';
import 'package:screen_time/theme/app_theme.dart';

class GraphBar extends StatelessWidget {
  final int usage;
  final int maxUsage;
  final String hour;
  final double maxHeight;

  const GraphBar({
    Key? key,
    required this.usage,
    required this.maxUsage,
    required this.hour,
    this.maxHeight = 200.0,
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

  Color _getBarColor(int usage) {
    if (usage == 0) return AppTheme.primary.withValues(alpha: 0.2);
    return AppTheme.primary.withValues(alpha: 0.7);
  }

  @override
  Widget build(BuildContext context) {
    final double heightPercentage = maxUsage == 0 ? 0 : usage / maxUsage;
    final timeString = '${int.parse(hour).toString().padLeft(2, '0')}:00';

    return GestureDetector(
      onTap: () {
        if (usage > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$timeString: ${_formatDuration(usage)}'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      },
      child: Tooltip(
        message: usage > 0
            ? '$timeString: ${_formatDuration(usage)}'
            : '$timeString: Ingen användning',
        child: Container(
          height: heightPercentage * maxHeight,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: _getBarColor(usage),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(3.0)),
            boxShadow: usage > 0
                ? [
                    BoxShadow(
                      color: _getBarColor(usage).withValues(alpha: 0.3),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: usage > 0 && heightPercentage > 0.1
              ? Center(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      _formatDuration(usage),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
