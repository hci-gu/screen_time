import 'package:flutter/material.dart';

class TotalUsageText extends StatelessWidget {
  final double totalMins;
  const TotalUsageText({Key? key, required this.totalMins}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Text('Total: ${totalMins.toStringAsFixed(1)} mins',
        style: Theme.of(context).textTheme.bodyLarge);
  }
}
