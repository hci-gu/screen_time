import 'package:flutter/material.dart';

class GraphBar extends StatelessWidget {
  final int usage;
  final int maxUsage;
  const GraphBar({Key? key, required this.usage, required this.maxUsage})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    final double heightPercentage = maxUsage == 0 ? 0 : usage / maxUsage;
    return Expanded(
      child: Container(
        height: heightPercentage * 150,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4.0)),
        ),
      ),
    );
  }
}
