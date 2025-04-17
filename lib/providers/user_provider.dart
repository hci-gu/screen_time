import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

final userIdProvider =
    StateNotifierProvider<UserIdNotifier, String?>((ref) => UserIdNotifier());

class UserIdNotifier extends StateNotifier<String?> {
  UserIdNotifier() : super(null) {
    _loadFromSharedPreferences();
  }

  Future<void> _loadFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('userId');
  }

  Future<void> setUserId(String? userId) async {
    state = userId;
    final prefs = await SharedPreferences.getInstance();
    if (userId != null) {
      await prefs.setString('userId', userId);
    } else {
      await prefs.remove('userId');
    }
  }
}
