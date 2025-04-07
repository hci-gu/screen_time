import 'package:flutter/material.dart';
import 'graph_bar.dart';

class UsageGraph extends StatelessWidget {
  final Map<String, int> usageData;
  const UsageGraph({Key? key, required this.usageData}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final maxValue = 60 * 60;
    return Card(
      child: Container(
        height: 250,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Hourly Usage',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: usageData.entries.map((entry) {
                        return GraphBar(
                            usage: entry.value, maxUsage: maxValue);
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('00:00',
                          style: Theme.of(context).textTheme.bodySmall),
                      Text('12:00',
                          style: Theme.of(context).textTheme.bodySmall),
                      Text('23:00',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
