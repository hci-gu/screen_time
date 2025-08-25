import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:screen_time/api.dart' as api;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screentime/screentime.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:io';

final usageProvider =
    StateNotifierProvider<UsageNotifier, UsageState>((ref) => UsageNotifier());

class UsageState {
  final String date;
  final Map<String, int> usageData;
  final bool hasPermission;
  final bool isLoading;
  const UsageState({
    required this.date,
    required this.usageData,
    required this.hasPermission,
    this.isLoading = false,
  });
  UsageState copyWith({
    String? date,
    Map<String, int>? usageData,
    bool? hasPermission,
    bool? isLoading,
  }) {
    return UsageState(
      date: date ?? this.date,
      usageData: usageData ?? this.usageData,
      hasPermission: hasPermission ?? this.hasPermission,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class UsageNotifier extends StateNotifier<UsageState> {
  bool get isAndroid => Platform.isAndroid;
  DateTime lastUpdate = DateTime(1900, 1, 1);

  UsageNotifier()
      : super(UsageState(
          date: _currentDate(),
          usageData: {},
          hasPermission: !Platform.isAndroid, // auto-true if non-android
          isLoading: Platform.isAndroid, // loading only on Android
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
      state = state.copyWith(hasPermission: true, isLoading: false);
      getUsageStats();
      return;
    }
    try {
      final bool permitted = await Screentime().hasPermission();
      state = state.copyWith(hasPermission: permitted, isLoading: false);
      if (permitted) {
        getUsageStats();
      }
    } on PlatformException catch (e) {
      print("checkUsageStatsPermission error: [31m${e.message}[0m");
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> requestUsageStatsPermission() async {
    try {
      await Screentime().requestUsageStatsPermission();
      final bool permitted = await Screentime().hasPermission();
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
      final Map<String, int> result =
          await Screentime().getUsageStats(state.date);
      state = state.copyWith(usageData: result);
    } on PlatformException catch (e) {
      print("getUsageStats error: ${e.message}");
    }
  }

  Future<void> updateDate(String newDate) async {
    state = state.copyWith(date: newDate);
    getUsageStats();
  }

  Future<bool> uploadData(String userId) async {
    try {
      Map<String, int> entries;
      
      if (!isAndroid) {
        // For iOS, use the data from state (which contains mock data)
        entries = state.usageData;
        print("uploadData.iOS using state data: $entries");
      } else {
        print("uploadData.before Screentime.getUsageStats");
        entries = await Screentime().getUsageStats(state.date);
        print("uploadData.after Screentime.getUsageStats: $entries");
      }
      
      // convert to list of maps
      final List<Map<String, dynamic>> entriesList = [];
      entries.forEach((key, value) {
        entriesList.add({
          'hour': key,
          'seconds': value,
        });
      });

      final Map<String, dynamic> result = {
        'screenTimeEntries': entriesList,
      };

      print("before api.uploadData: $result");

      bool success = await api.uploadData(userId, result);

      if (success) {
        _saveLastUpdate();
        return true;
      }
    } on PlatformException catch (_) {}

    return false;
  }

  Future<bool> uploadLast7Days(String userId) async {
    if (!state.hasPermission) {
      print('Permission not granted, aborting upload.');
      return false;
    }
    
    try {
      final List<Map<String, dynamic>> allEntries = [];
      
      if (!isAndroid) {
        // For iOS, generate mock data for the last 7 days
        for (int i = 1; i <= 7; i++) {
          final date = DateTime.now().subtract(Duration(days: i));
          final dateString =
              "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
          
          // Use similar mock data as in getUsageStats but vary it slightly for each day
          final mockData = {
            "0": (1 + i) * 60,
            "1": (2 + i) * 60,
            "2": (30 + i) * 60,
            "3": (4 + i) * 60,
            "4": (33 + i) * 60,
            "5": (6 + i) * 60,
            "6": (7 + i) * 60,
            "7": (8 + i) * 60,
            "8": (9 + i) * 60,
            "9": (10 + i) * 60,
            "10": (11 + i) * 60,
            "11": (12 + i) * 60,
            "12": (13 + i) * 60,
            "13": (14 + i) * 60,
            "14": (15 + i) * 60,
            "15": (16 + i) * 60,
            "16": (17 + i) * 60,
            "17": (18 + i) * 60,
            "18": (19 + i) * 60,
            "19": (20 + i) * 60,
            "20": (21 + i) * 60,
            "21": (22 + i) * 60,
            "22": (23 + i) * 60,
            "23": (24 + i) * 60,
          };
          
          mockData.forEach((key, value) {
            allEntries.add({
              'date': dateString,
              'hour': key,
              'seconds': value,
            });
          });
        }
      } else {
        // For Android, use real screen time data
        for (int i = 1; i <= 7; i++) {
          final date = DateTime.now().subtract(Duration(days: i));
          final dateString =
              "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
          final Map<String, int> entries =
              await Screentime().getUsageStats(dateString);
          entries.forEach((key, value) {
            allEntries.add({
              'date': dateString,
              'hour': key,
              'seconds': value,
            });
          });
        }
      }

      final Map<String, dynamic> result = {
        'screenTimeEntries': allEntries,
      };

      bool success = await api.uploadData(userId, result);

      if (success) {
        _saveLastUpdate();
        return true;
      }
    } on PlatformException catch (_) {}

    return false;
  }
}
