import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class UserState {
  final String? userId;
  final bool isLoading;
  const UserState({this.userId, this.isLoading = false});

  UserState copyWith({String? userId, bool? isLoading}) {
    return UserState(
      userId: userId ?? this.userId,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final userIdProvider =
    StateNotifierProvider<UserIdNotifier, UserState>((ref) => UserIdNotifier());

class UserIdNotifier extends StateNotifier<UserState> {
  UserIdNotifier() : super(const UserState(isLoading: true)) {
    _loadFromSharedPreferences();
  }

  Future<void> _loadFromSharedPreferences() async {
    state = state.copyWith(isLoading: true);
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    state = UserState(userId: userId, isLoading: false);
  }

  Future<void> setUserId(String? userId) async {
    state = state.copyWith(userId: userId);
    final prefs = await SharedPreferences.getInstance();
    if (userId != null) {
      await prefs.setString('userId', userId);
    } else {
      await prefs.clear();
    }
  }
}
