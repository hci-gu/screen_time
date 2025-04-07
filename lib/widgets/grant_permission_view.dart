import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/usage_provider.dart';

class GrantPermissionView extends ConsumerWidget {
  const GrantPermissionView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageNotifier = ref.read(usageProvider.notifier);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Please grant usage stats permission"),
          const SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: () {
              usageNotifier.requestUsageStatsPermission();
            },
            child: const Text("Grant Permission"),
          ),
        ],
      ),
    );
  }
}
