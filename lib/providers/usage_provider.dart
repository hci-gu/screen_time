import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:screen_time/api.dart' as api;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:io';

final usageProvider =
    StateNotifierProvider<UsageNotifier, UsageState>((ref) => UsageNotifier());

class UsageState {
  final String date;
  final Map<String, int> usageData;
  final bool hasPermission;
  const UsageState({
    required this.date,
    required this.usageData,
    required this.hasPermission,
  });
  UsageState copyWith({
    String? date,
    Map<String, int>? usageData,
    bool? hasPermission,
  }) {
    return UsageState(
      date: date ?? this.date,
      usageData: usageData ?? this.usageData,
      hasPermission: hasPermission ?? this.hasPermission,
    );
  }
}

class UsageNotifier extends StateNotifier<UsageState> {
  final MethodChannel _platform =
      const MethodChannel("com.example.screen_time/usage");
  bool get isAndroid => Platform.isAndroid;
  DateTime lastUpdate = DateTime(1900, 1, 1);

  UsageNotifier()
      : super(UsageState(
          date: _currentDate(),
          usageData: {},
          hasPermission: !Platform.isAndroid, // auto-true if non-android
        )) {
    checkUsageStatsPermission();
    _loadLastUpdate();
  }

  Future<void> _loadLastUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString("lastUpdate");
    if (stored != null) {
      try {
        lastUpdate = DateTime.parse(stored);
      } catch (_) {
        lastUpdate = DateTime(1900, 1, 1);
      }
    }
  }

  Future<void> _saveLastUpdate() async {
    lastUpdate = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("lastUpdate", lastUpdate.toIso8601String());
  }

  static String _currentDate() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  Future<void> checkUsageStatsPermission() async {
    if (!isAndroid) {
      // on non-android, assume permission granted and load mock data
      state = state.copyWith(hasPermission: true);
      getUsageStats();
      return;
    }
    try {
      final bool permitted =
          await _platform.invokeMethod("hasUsageStatsPermission");
      state = state.copyWith(hasPermission: permitted);
      if (permitted) {
        getUsageStats();
      }
    } on PlatformException catch (e) {
      print("checkUsageStatsPermission error: ${e.message}");
    }
  }

  Future<void> requestUsageStatsPermission() async {
    try {
      await _platform.invokeMethod("requestUsageStatsPermission");
      final bool permitted =
          await _platform.invokeMethod("hasUsageStatsPermission");
      state = state.copyWith(hasPermission: permitted);
      if (permitted) {
        getUsageStats();
      }
    } on PlatformException catch (e) {
      print("requestUsageStatsPermission error: ${e.message}");
    }
  }

  Future<void> getUsageStats() async {
    if (!isAndroid) {
      state = state.copyWith(usageData: {
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
      });
      return;
    }
    try {
      final Map<dynamic, dynamic> result =
          await _platform.invokeMethod("getHourlyUsage", {"date": state.date});
      state = state.copyWith(
          usageData: result
              .map((key, value) => MapEntry(key as String, value as int)));
    } on PlatformException catch (e) {
      print("getUsageStats error: ${e.message}");
    }
  }

  Future<void> updateDate(String newDate) async {
    state = state.copyWith(date: newDate);
    getUsageStats();
  }

  Future<bool> uploadData(String userId) async {
    if (!isAndroid) {
      bool success = await api.uploadData(userId, {'screenTimeEntries': []});
      return success;
    }
    // has there been more than one hour since last update?
    // if (lastUpdate.isAfter(DateTime.now().subtract(const Duration(hours: 1)))) {
    //   return true;
    // }

    try {
      final jsonString =
          await _platform.invokeMethod("postScreenTime", {"date": state.date});
      final jsonData = jsonDecode(jsonString);
      bool success = await api.uploadData(userId, jsonData);

      if (success) {
        _saveLastUpdate();
        return true;
      }
    } on PlatformException catch (_) {}

    return false;
  }
}
