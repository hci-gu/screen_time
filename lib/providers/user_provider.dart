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
    try {
      state = state.copyWith(isLoading: true);
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      print('Loading user from SharedPreferences: $userId');

      state = UserState(userId: userId, isLoading: false);

      if (userId != null) {
        _autoUploadData(userId);
      }
    } catch (e) {
      print('Error loading user from SharedPreferences: $e');
      state = const UserState(userId: null, isLoading: false);
    }
  }

  Future<void> setUserId(String? userId) async {
    try {
      state = state.copyWith(userId: userId);
      final prefs = await SharedPreferences.getInstance();
      if (userId != null) {
        await prefs.setString('userId', userId);
        print('User ID saved to SharedPreferences: $userId');
        _autoUploadData(userId);
      } else {
        await prefs.remove('userId');
        print('User ID removed from SharedPreferences');
      }
    } catch (e) {
      print('Error setting user ID: $e');
      final prefs = await SharedPreferences.getInstance();
      final savedUserId = prefs.getString('userId');
      state = state.copyWith(userId: savedUserId);
    }
  }

  Future<void> logout() async {
    state = state.copyWith(userId: null);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');

    print('User logged out successfully');
  }

  Future<bool> isUserPersisted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUserId = prefs.getString('userId');
      final currentUserId = state.userId;

      print(
          'Checking user persistence - Current: $currentUserId, Saved: $savedUserId');

      return savedUserId != null && savedUserId == currentUserId;
    } catch (e) {
      print('Error checking user persistence: $e');
      return false;
    }
  }

  Future<void> validateUserState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUserId = prefs.getString('userId');

      if (savedUserId != state.userId) {
        print(
            'User state mismatch detected! Current: ${state.userId}, Saved: $savedUserId');
        state = state.copyWith(userId: savedUserId);
      }
    } catch (e) {
      print('Error validating user state: $e');
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
