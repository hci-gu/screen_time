import 'package:flutter/material.dart';
import 'time_icon.dart';

class UsageListItem extends StatelessWidget {
  final String hour;
  final int usage;
  const UsageListItem({Key? key, required this.hour, required this.usage})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    final timeString = '${int.parse(hour).toString().padLeft(2, '0')}:00';
    return ListTile(
      leading: const TimeIcon(),
      title: Text(timeString),
      trailing: Text(
        '${(usage / 60.0).toStringAsFixed(1)} mins',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
