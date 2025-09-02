import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:screen_time/router.dart';
import 'package:screen_time/theme/app_theme.dart';
import 'package:screen_time/services/foreground_service.dart';
import 'providers/user_provider.dart';
import 'providers/usage_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();
  ForegroundService.instance.init();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends HookConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userIdProvider);
    final router = ref.watch(
      routerProvider(
        RouterProps(
          loggedIn: userState.userId != null,
        ),
      ),
    );

    WidgetsBinding.instance.addObserver(_AppLifecycleObserver(ref));

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Skärmtidstracker',
      theme: AppTheme.themeData,
      routerConfig: router,
    );
  }
}

class _AppLifecycleObserver extends WidgetsBindingObserver {
  final WidgetRef _ref;

  _AppLifecycleObserver(this._ref);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      _triggerAutoUpload();
    }
  }

  void _triggerAutoUpload() async {
    try {
      final userState = _ref.read(userIdProvider);
      if (userState.userId != null) {
        final usageNotifier = _ref.read(usageProvider.notifier);
        await usageNotifier.autoUploadIfNeeded(userState.userId!);
      }
    } catch (e) {
      print('App lifecycle auto-upload failed: $e');
    }
  }
}
