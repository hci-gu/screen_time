import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:io';
import 'package:screen_time/router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/usage_provider.dart';
import 'package:background_fetch/background_fetch.dart';

bool isAndroid = false; //Platform.isAndroid;

@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  String taskId = task.taskId;
  bool isTimeout = task.timeout;
  if (isTimeout) {
    BackgroundFetch.finish(taskId);
    return;
  }
  final notifier = UsageNotifier();
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString("userId");

  if (userId == null) {
    return BackgroundFetch.finish(taskId);
  }
  await notifier.uploadData(userId);
  BackgroundFetch.finish(taskId);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ProviderScope(child: MyApp()));

  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
}

class MyApp extends HookConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      BackgroundFetch.configure(
          BackgroundFetchConfig(
            minimumFetchInterval: 30,
            stopOnTerminate: false,
            startOnBoot: true,
            enableHeadless: true,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresStorageNotLow: false,
            requiresDeviceIdle: false,
            requiredNetworkType: NetworkType.ANY,
          ), (String taskId) async {
        final notifier = UsageNotifier();
        final prefs = await SharedPreferences.getInstance();
        final userId = prefs.getString("userId");

        if (userId == null) {
          return BackgroundFetch.finish(taskId);
        }
        await notifier.uploadData(userId);
        BackgroundFetch.finish(taskId);
      });

      return () {};
    }, []);

    final router = ref.watch(
      routerProvider(
        RouterProps(
          loggedIn: false,
        ),
      ),
    );

    return MaterialApp.router(
      title: 'Screen Time Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
        cardTheme: const CardTheme(
          elevation: 2,
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      routerConfig: router,
    );
  }
}
