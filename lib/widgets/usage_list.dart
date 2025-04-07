import 'package:flutter/material.dart';
import 'usage_list_item.dart';

class UsageList extends StatelessWidget {
  final Map<String, int> usageData;
  const UsageList({Key? key, required this.usageData}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: usageData.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final entry = usageData.entries.elementAt(index);
          return UsageListItem(hour: entry.key, usage: entry.value);
        },
      ),
    );
  }
}
