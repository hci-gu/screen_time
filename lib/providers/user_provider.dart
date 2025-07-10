import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

final userIdProvider =
    StateNotifierProvider<UserIdNotifier, String?>((ref) => UserIdNotifier());

class UserIdNotifier extends StateNotifier<String?> {
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  UserIdNotifier() : super(null) {
    _loadFromSharedPreferences();
  }

  Future<void> _loadFromSharedPreferences() async {
    _isLoading = true;
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('userId');
    _isLoading = false;
    state = state;
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
