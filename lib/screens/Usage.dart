import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:screen_time/providers/usage_provider.dart';
import 'package:screen_time/services/foreground_service.dart';
import 'package:screen_time/theme/app_theme.dart';
import 'package:screen_time/utils/platform_utils.dart';
import 'package:screen_time/widgets/grant_permission_view.dart';
import 'package:go_router/go_router.dart';

class UsagePage extends HookConsumerWidget {
  const UsagePage({super.key});

  Future<void> _startForegroundService() async {
    try {
      if (await ForegroundService.instance.isRunningService) {
        return;
      }

      await ForegroundService.instance.start();
    } catch (e) {
      debugPrint('Failed to start foreground service: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!PlatformUtils.isAndroid) {
      useEffect(() {
        Future.microtask(() {
          if (!context.mounted) {
            return;
          }
          context.go('/');
        });
        return null;
      }, []);

      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final usageState = ref.watch(usageProvider);

    useEffect(() {
      _startForegroundService();
      final observer = _UsageLifecycleObserver(ref);
      WidgetsBinding.instance.addObserver(observer);
      return () {
        WidgetsBinding.instance.removeObserver(observer);
      };
    }, []);

    useEffect(() {
      if (usageState.hasPermission) {
        Future.microtask(() {
          if (!context.mounted) {
            return;
          }
          if (Navigator.canPop(context)) {
            Navigator.popUntil(context, (route) => route.isFirst);
          }
          context.go('/');
        });
      }
      return null;
    }, [usageState.hasPermission]);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Container(
        color: AppTheme.background,
        child: const GrantPermissionView(),
      ),
    );
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
