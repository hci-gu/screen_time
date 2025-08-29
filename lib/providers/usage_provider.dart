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
  // Spara dagens skärmtid till localstorage
  Future<void> saveTodayUsageToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final date = state.date;
    final usage = state.usageData;
    final raw = prefs.getString('screenTimeLocal') ?? '{}';
    final Map<String, dynamic> allData = jsonDecode(raw);
    allData[date] = usage;
    await prefs.setString('screenTimeLocal', jsonEncode(allData));
  }

  // Hämta all sparad skärmtid från localstorage
  Future<Map<String, Map<String, int>>> getAllLocalUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('screenTimeLocal') ?? '{}';
    final Map<String, dynamic> allData = jsonDecode(raw);
    return allData
        .map((date, usage) => MapEntry(date, Map<String, int>.from(usage)));
  }

  // Rensa all sparad skärmtid från localstorage
  Future<void> clearLocalUsage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('screenTimeLocal');
  }

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
      // Spara till localstorage varje gång ny data hämtas
      await saveTodayUsageToLocal();
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

    try {
      print("uploadData.before Screentime.getUsageStats");
      final Map<String, int> entries = await Screentime().getUsageStats(
        state.date,
      );
      print("uploadData.after Screentime.getUsageStats: $entries");
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
    if (!isAndroid) {
      bool success = await api.uploadData(userId, {'screenTimeEntries': []});
      return success;
    }
    try {
      // Hämta all sparad skärmtid från localstorage
      final allData = await getAllLocalUsage();
      final List<Map<String, dynamic>> entriesList = [];
      allData.forEach((date, usage) {
        usage.forEach((hour, seconds) {
          entriesList.add({
            'date': date,
            'hour': hour,
            'seconds': seconds,
          });
        });
      });
      final Map<String, dynamic> result = {
        'screenTimeEntries': entriesList,
      };
      bool success = await api.uploadData(userId, result);
      if (success) {
        await clearLocalUsage();
        _saveLastUpdate();
        return true;
      }
    } catch (e) {
      print('uploadLast7Days error: $e');
    }
    return false;
  }
}
