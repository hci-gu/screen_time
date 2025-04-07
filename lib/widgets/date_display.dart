import 'package:flutter/material.dart';
import 'date_text.dart';
import 'total_usage_text.dart';

class DateDisplay extends StatelessWidget {
  final String date;
  final double totalMins;
  const DateDisplay({Key? key, required this.date, required this.totalMins})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DateText(date: date),
        TotalUsageText(totalMins: totalMins),
      ],
    );
  }
}
