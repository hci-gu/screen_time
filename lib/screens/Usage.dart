import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:screen_time/providers/usage_provider.dart';
import 'package:screen_time/services/foreground_service.dart';
import 'package:screen_time/widgets/date_selector.dart';
import 'package:screen_time/widgets/grant_permission_view.dart';
import 'package:screen_time/widgets/upload_button.dart';
import 'package:screen_time/widgets/usage_graph.dart';
import 'package:screen_time/widgets/usage_list.dart';

class UsagePage extends HookConsumerWidget {
  const UsagePage({super.key});

  void _startForeGroundService() async {
    try {
      if (await ForegroundService.instance.isRunningService) {
        return;
      }

      ForegroundService.instance.start();
    } catch (e) {
      print("Error starting foreground service: $e");
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      _startForeGroundService();
      return () {};
    }, []);

    final usageState = ref.watch(usageProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Screen time tracker"),
      ),
      body: !usageState.hasPermission
          ? const GrantPermissionView()
          : Column(
              children: [
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: DateSelector(),
                  ),
                ),
                UsageGraph(usageData: usageState.usageData),
                Expanded(child: UsageList(usageData: usageState.usageData)),
              ],
            ),
      floatingActionButton:
          !usageState.hasPermission ? null : const UploadButton(),
    );
  }
}
