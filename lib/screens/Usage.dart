import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:screen_time/providers/usage_provider.dart';
import 'package:screen_time/services/foreground_service.dart';
import 'package:screen_time/widgets/grant_permission_view.dart';
import 'package:go_router/go_router.dart';

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
    final usageState = ref.watch(usageProvider);

    useEffect(() {
      _startForeGroundService();
      final observer = _UsageLifecycleObserver(ref);
      WidgetsBinding.instance.addObserver(observer);
      return () {
        WidgetsBinding.instance.removeObserver(observer);
      };
    }, []);

    useEffect(() {
      if (usageState.hasPermission) {
        Future.microtask(() {
          if (ModalRoute.of(context)?.settings.name == '/usage' || true) {
            if (Navigator.canPop(context)) {
              Navigator.popUntil(context, (route) => route.isFirst);
            }
            try {
              // ignore: invalid_use_of_visible_for_testing_member
              // ignore: invalid_use_of_protected_member
              // ignore: unnecessary_cast
              (GoRouter.of(context) as dynamic).go('/');
            } catch (_) {}
          }
        });
      }
      return null;
    }, [usageState.hasPermission]);

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text("Screen time tracker"),
        ),
        body: const GrantPermissionView());
  }
}

class _UsageLifecycleObserver extends WidgetsBindingObserver {
  final WidgetRef ref;
  _UsageLifecycleObserver(this.ref);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(usageProvider);
    }
  }
}
