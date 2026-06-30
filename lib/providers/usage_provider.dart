import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:screen_time/api.dart' as api;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screentime/screentime.dart';
import 'package:screen_time/utils/platform_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

final usageProvider = StateNotifierProvider<UsageNotifier, UsageState>(
  (ref) => UsageNotifier(),
);

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
  Future<void> saveUsageToLocal({
    String? date,
    Map<String, int>? usageData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final usageDate = date ?? state.date;
    final usage = usageData ?? state.usageData;
    final raw = prefs.getString('screenTimeLocal') ?? '{}';
    final Map<String, dynamic> allData = jsonDecode(raw);
    final existingForDate = allData[usageDate] is Map
        ? Map<String, dynamic>.from(allData[usageDate] as Map)
        : <String, dynamic>{};

    allData[usageDate] = usage.map((key, value) {
      final storedValue = existingForDate[key] is int
          ? existingForDate[key] as int
          : int.tryParse(existingForDate[key]?.toString() ?? '') ?? 0;
      final highestValue = storedValue > value ? storedValue : value;

      return MapEntry(key, highestValue);
    });
    await prefs.setString('screenTimeLocal', jsonEncode(allData));
  }

  Future<void> saveTodayUsageToLocal() => saveUsageToLocal();

  // Hämta all sparad skärmtid från localstorage
  Future<Map<String, Map<String, int>>> getAllLocalUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('screenTimeLocal') ?? '{}';
    final Map<String, dynamic> allData = jsonDecode(raw);
    return allData.map(
      (date, usage) => MapEntry(date, Map<String, int>.from(usage)),
    );
  }

  // Rensa all sparad skärmtid från localstorage
  Future<void> clearLocalUsage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('screenTimeLocal');
  }

  bool get isAndroid => PlatformUtils.isAndroid;
  DateTime lastUpdate = DateTime(1900, 1, 1);
  late final Future<void> _lastUpdateLoaded;

  UsageNotifier()
    : super(
        UsageState(
          date: _currentDate(),
          usageData: {},
          hasPermission: PlatformUtils.isAndroid,
          isLoading: PlatformUtils.isAndroid,
        ),
      ) {
    if (PlatformUtils.isAndroid) {
      _lastUpdateLoaded = _loadLastUpdate();
      checkUsageStatsPermission();
    } else {
      _lastUpdateLoaded = Future.value();
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
      state = state.copyWith(
        hasPermission: false,
        isLoading: false,
        usageData: {},
      );
      return;
    }
    try {
      final bool permitted = await Screentime().hasPermission();
      state = state.copyWith(hasPermission: permitted, isLoading: false);
      if (permitted) {
        await getUsageStats();
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
        await getUsageStats();
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

    String date = state.date;

    try {
      Map<String, int> usage = {};
      final now = DateTime.now();

      // Fetch usage for today and the previous 9 days (10 days total)
      for (int i = 0; i < 10; i++) {
        final day = now.subtract(Duration(days: i));
        final dateStr =
            "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
        try {
          final Map<String, int> result = await Screentime().getUsageStats(
            dateStr,
          );
          state = state.copyWith(date: dateStr, usageData: result);
          await saveUsageToLocal(date: dateStr, usageData: result);

          if (dateStr == date) {
            usage = result;
          }
        } catch (_) {}
      }

      // Update state. If the current state.date wasn't among fetched days,
      // fall back to an empty map.
      state = state.copyWith(date: date, usageData: usage);
    } on PlatformException catch (e) {
      print("getUsageStats error: ${e.message}");
    }
  }

  Future<void> updateDate(String newDate) async {
    state = state.copyWith(date: newDate);
    await getUsageStats();
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

      await saveUsageToLocal(date: state.date, usageData: entries);

      final List<Map<String, dynamic>> entriesList = [];
      entries.forEach((key, value) {
        entriesList.add({'date': state.date, 'hour': key, 'seconds': value});
      });

      final Map<String, dynamic> result = {'screenTimeEntries': entriesList};

      print("before api.uploadData: $result");

      bool success = await api.uploadData(userId, result);

      if (success) {
        await _saveLastUpdate();
        return true;
      }
    } on PlatformException catch (_) {}

    return false;
  }

  Future<void> autoUploadIfNeeded(String userId) async {
    await _lastUpdateLoaded;

    final now = DateTime.now();
    final timeSinceLastUpdate = now.difference(lastUpdate);

    if (timeSinceLastUpdate.inMinutes > 30) {
      try {
        final uploaded = await uploadData(userId);
        if (uploaded) {
          print('Auto-upload completed at ${now.toIso8601String()}');
        } else {
          print('Auto-upload skipped or failed at ${now.toIso8601String()}');
        }
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
          entriesList.add({'date': date, 'hour': hour, 'seconds': seconds});
        });
      });
      final Map<String, dynamic> result = {'screenTimeEntries': entriesList};
      bool success = await api.uploadData(userId, result);
      if (success) {
        await clearLocalUsage();
        await _saveLastUpdate();
        return true;
      }
    } catch (e) {
      print('uploadLast7Days error: $e');
    }
    return false;
  }
}
