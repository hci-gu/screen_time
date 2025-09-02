import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'usage_provider.dart';

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

final userIdProvider = StateNotifierProvider<UserIdNotifier, UserState>(
    (ref) => UserIdNotifier(ref));

class UserIdNotifier extends StateNotifier<UserState> {
  final Ref _ref;

  UserIdNotifier(this._ref) : super(const UserState(isLoading: true)) {
    _loadFromSharedPreferences();
  }

  Future<void> _loadFromSharedPreferences() async {
    state = state.copyWith(isLoading: true);
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    state = UserState(userId: userId, isLoading: false);

    if (userId != null) {
      _autoUploadData(userId);
    }
  }

  Future<void> setUserId(String? userId) async {
    state = state.copyWith(userId: userId);
    final prefs = await SharedPreferences.getInstance();
    if (userId != null) {
      await prefs.setString('userId', userId);
      _autoUploadData(userId);
    } else {
      await prefs.clear();
    }
  }

  Future<void> _autoUploadData(String userId) async {
    try {
      final usageNotifier = _ref.read(usageProvider.notifier);

      await usageNotifier.uploadLast7Days(userId);

      await usageNotifier.uploadData(userId);

      print('Auto-upload completed for user: $userId');
    } catch (e) {
      print('Auto-upload failed: $e');
    }
  }

  Future<bool> uploadUserData() async {
    final userId = state.userId;
    if (userId == null) return false;

    try {
      final usageNotifier = _ref.read(usageProvider.notifier);
      return await usageNotifier.uploadLast7Days(userId);
    } catch (e) {
      print('Manual upload failed: $e');
      return false;
    }
  }
}
