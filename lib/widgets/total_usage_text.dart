import 'package:flutter/material.dart';
import 'package:screen_time/theme/app_theme.dart';

class TotalUsageText extends StatelessWidget {
  final double totalMins;
  const TotalUsageText({Key? key, required this.totalMins}) : super(key: key);

  String _formatDuration(double minutes) {
    if (minutes < 60) {
      return '${minutes.round()} min';
    }
    final hours = minutes ~/ 60;
    final mins = (minutes % 60).round();
    if (mins == 0) {
      return '${hours}h';
    }
    return '${hours}h ${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: _formatDuration(totalMins),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
          ),
        ],
      ),
    );
  }
}
