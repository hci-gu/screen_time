import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'dart:io';

bool isAndroid = false; //Platform.isAndroid;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // check that it is not web

  print('${isAndroid}');

  if (isAndroid) {
    await AndroidAlarmManager.initialize();
  }

  runApp(const MyApp());
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

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const platform = MethodChannel("com.example.screen_time/usage");
  Map<String, int> usageData = <String, int>{};
  String date = "2025-01-17";
  bool hasPermission = false;

  @override
  void initState() {
    super.initState();
    // set date to today
    final DateTime now = DateTime.now();
    date =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    checkUsageStatsPermission();
    // scheduleDailyUpload();
  }

  Future<void> requestUsageStatsPermission() async {
    try {
      await platform.invokeMethod("requestUsageStatsPermission");
      hasPermission = await platform.invokeMethod("hasUsageStatsPermission");
      setState(() {});
      if (hasPermission) {
        getUsageStats();
      }
    } on PlatformException catch (e) {
      print("Failed to request usage stats permission: ${e.message}");
    }
  }

  Future<void> checkUsageStatsPermission() async {
    // if not android device then just return true
    if (!isAndroid) {
      hasPermission = true;
      getUsageStats();
      return;
    }
    try {
      hasPermission = await platform.invokeMethod("hasUsageStatsPermission");
      setState(() {});
      if (hasPermission) {
        getUsageStats();
      }
    } on PlatformException catch (e) {
      print("Failed to check or request usage stats permission: ${e.message}");
    }
  }

  Future<void> getUsageStats() async {
    // if not android then return mock data
    if (!isAndroid) {
      setState(() {
        usageData = {
          "0": 1 * 60,
          "1": 2 * 60,
          "2": 30 * 60,
          "3": 4 * 60,
          "4": 33 * 60,
          "5": 6 * 60,
          "6": 7 * 60,
          "7": 8 * 60,
          "8": 9 * 60,
          "9": 10 * 60,
          "10": 11 * 60,
          "11": 12 * 60,
          "12": 13 * 60,
          "13": 14 * 60,
          "14": 15 * 60,
          "15": 16 * 60,
          "16": 17 * 60,
          "17": 18 * 60,
          "18": 19 * 60,
          "19": 20 * 60,
          "20": 21 * 60,
          "21": 22 * 60,
          "22": 23 * 60,
          "23": 24 * 60,
        };
      });
      return;
    }
    try {
      final Map<dynamic, dynamic> result =
          await platform.invokeMethod("getHourlyUsage", {"date": date});
      setState(() {
        usageData =
            result.map((key, value) => MapEntry(key as String, value as int));
      });
    } on PlatformException catch (e) {
      print("Failed to get usage stats: ${e.message}");
    }
  }

  void scheduleDailyUpload() {
    // only do this on android
    if (Theme.of(context).platform != TargetPlatform.android) {
      return;
    }
    AndroidAlarmManager.periodic(
      const Duration(hours: 24),
      0,
      uploadPreviousDayData,
      startAt: DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day, 1),
      exact: true,
      wakeup: true,
    );
  }

  Future<void> uploadPreviousDayData() async {
    // if not android then return
    if (Theme.of(context).platform != TargetPlatform.android) {
      return;
    }
    final DateTime now = DateTime.now();
    final DateTime prevDay = now.subtract(const Duration(days: 1));
    final String date =
        "${prevDay.year}-${prevDay.month.toString().padLeft(2, '0')}-${prevDay.day.toString().padLeft(2, '0')}";

    try {
      await platform.invokeMethod("postScreenTime", {
        "date": date,
      });
    } on PlatformException catch (e) {
      print("Failed to upload data: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!hasPermission) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title + " (No Permission)"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Please grant usage stats permission"),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  requestUsageStatsPermission();
                },
                child: const Text("Grant Permission"),
              ),
            ],
          ),
        ),
      );
    }

    var totalTime = 0;
    usageData.forEach((key, value) {
      totalTime += value;
      print('key: $key, value: $value');
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title + (hasPermission ? "" : " (No Permission)")),
      ),
      body: Column(children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: () {
                    final DateTime prevDay =
                        DateTime.parse(date).subtract(const Duration(days: 1));
                    setState(() {
                      date =
                          "${prevDay.year}-${prevDay.month.toString().padLeft(2, '0')}-${prevDay.day.toString().padLeft(2, '0')}";
                    });
                    getUsageStats();
                  },
                  icon: const Icon(Icons.chevron_left),
                ),
                Column(
                  children: [
                    Text(
                      date,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Total: ${(totalTime / 60).toStringAsFixed(1)} mins',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () {
                    final DateTime nextDay =
                        DateTime.parse(date).add(const Duration(days: 1));
                    setState(() {
                      date =
                          "${nextDay.year}-${nextDay.month.toString().padLeft(2, '0')}-${nextDay.day.toString().padLeft(2, '0')}";
                    });
                    getUsageStats();
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ),
        UsageGraph(usageData: usageData),
        Expanded(
          child: Card(
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: usageData.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final entry = usageData.entries.elementAt(index);
                final hour = int.parse(entry.key);
                final timeString = '${hour.toString().padLeft(2, '0')}:00';
                return ListTile(
                  leading: Icon(
                    Icons.access_time,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(timeString),
                  trailing: Text(
                    '${(entry.value / 60.0).toStringAsFixed(1)} mins',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                );
              },
            ),
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadData,
        tooltip: 'Upload Data',
        child: const Icon(Icons.cloud_upload),
      ),
    );
  }

  void _uploadData() async {
    try {
      await platform.invokeMethod("postScreenTime", {
        "date": date,
      });
    } on PlatformException catch (e) {
      print("Failed to upload data: ${e.message}");
    }
  }
}

class UsageGraph extends StatelessWidget {
  const UsageGraph({super.key, required this.usageData});

  final Map<String, int> usageData;

  @override
  Widget build(BuildContext context) {
    // final maxValue = usageData.values
    //     .reduce((max, value) => value > max ? value : max)
    //     .toDouble();
    final maxValue = 60 * 60;

    return Card(
      child: Container(
        height: 250,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Hourly Usage',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Column(
                children: [
                  // Graph bars
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: usageData.entries.map((entry) {
                        final double heightPercentage =
                            maxValue == 0 ? 0 : entry.value / maxValue;
                        return Expanded(
                          child: Container(
                            height: heightPercentage * 150,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4.0),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  // X-axis labels
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '00:00',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '12:00',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '23:00',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
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
