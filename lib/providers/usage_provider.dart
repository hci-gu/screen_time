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
          hasPermission: Platform.isAndroid,
          isLoading: Platform.isAndroid,
        )) {
    if (Platform.isAndroid) {
      checkUsageStatsPermission();
      _loadLastUpdate();
    }
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
      state =
          state.copyWith(hasPermission: false, isLoading: false, usageData: {});
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
    if (!isAndroid) {
      return;
    }
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
      state = state.copyWith(usageData: {});
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
      return false;
    }

    try {
      print("uploadData.before Screentime.getUsageStats");
      final Map<String, int> entries = await Screentime().getUsageStats(
        state.date,
      );
      print("uploadData.after Screentime.getUsageStats: $entries");

      await saveTodayUsageToLocal();

      final List<Map<String, dynamic>> entriesList = [];
      entries.forEach((key, value) {
        entriesList.add({
          'date': state.date,
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

  Future<void> autoUploadIfNeeded(String userId) async {
    final now = DateTime.now();
    final timeSinceLastUpdate = now.difference(lastUpdate);

    if (timeSinceLastUpdate.inMinutes > 30) {
      try {
        await uploadData(userId);
        print('Auto-upload completed at ${now.toIso8601String()}');
      } catch (e) {
        print('Auto-upload failed: $e');
      }
    }
  }

  Future<bool> uploadLast7Days(String userId) async {
    if (!isAndroid || !state.hasPermission) {
      return false;
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
