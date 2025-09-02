import 'package:flutter/material.dart';
import 'package:screen_time/theme/app_theme.dart';
import 'date_text.dart';

class DateDisplay extends StatelessWidget {
  final String date;
  final double totalMins;
  const DateDisplay({Key? key, required this.date, required this.totalMins})
      : super(key: key);

  bool _isToday(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final isToday = _isToday(date);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isToday
            ? AppTheme.primary.withValues(alpha: 0.1)
            : AppTheme.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday
              ? AppTheme.primary.withValues(alpha: 0.3)
              : AppTheme.cardBorder,
        ),
      ),
      child: Column(
        children: [
          if (isToday) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'IDAG',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          DateText(date: date),
          if (totalMins > 0) ...[
            const SizedBox(height: 4),
            Text(
              '${totalMins.round()} minuter',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.primary.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
