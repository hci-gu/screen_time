import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'providers/usage_provider.dart';
import 'widgets/date_selector.dart';
import 'widgets/usage_graph.dart';
import 'widgets/usage_list.dart';
import 'widgets/grant_permission_view.dart';
import 'widgets/upload_button.dart';

bool isAndroid = false; //Platform.isAndroid;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // check that it is not web

  print('${isAndroid}');

  if (isAndroid) {
    await AndroidAlarmManager.initialize();
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      home: const MyHomePage(title: 'Screen Time Tracker'),
    );
  }
}

class MyHomePage extends ConsumerWidget {
  final String title;
  const MyHomePage({super.key, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageState = ref.watch(usageProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(!usageState.hasPermission ? "$title (No Permission)" : title),
      ),
      body: !usageState.hasPermission
          ? const GrantPermissionView()
          : Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: const DateSelector(),
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
