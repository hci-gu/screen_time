import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_time/widgets/date_button.dart';
import 'package:screen_time/widgets/date_display.dart';
import '../providers/usage_provider.dart';

class DateSelector extends ConsumerWidget {
  const DateSelector({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageState = ref.watch(usageProvider);
    final usageNotifier = ref.read(usageProvider.notifier);
    final totalMins =
        usageState.usageData.values.fold(0, (a, b) => a + b) / 60.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        DateButton(
          icon: Icons.chevron_left,
          onPressed: () {
            final prevDate = DateTime.parse(usageState.date)
                .subtract(const Duration(days: 1));
            final newDate =
                "${prevDate.year}-${prevDate.month.toString().padLeft(2, '0')}-${prevDate.day.toString().padLeft(2, '0')}";
            usageNotifier.updateDate(newDate);
          },
        ),
        DateDisplay(date: usageState.date, totalMins: totalMins),
        DateButton(
          icon: Icons.chevron_right,
          onPressed: () {
            final nextDate = DateTime.parse(usageState.date)
                .add(const Duration(days: 1));
            final newDate =
                "${nextDate.year}-${nextDate.month.toString().padLeft(2, '0')}-${nextDate.day.toString().padLeft(2, '0')}";
            usageNotifier.updateDate(newDate);
          },
        ),
      ],
    );
  }
}
