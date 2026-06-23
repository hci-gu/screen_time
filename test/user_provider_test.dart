import 'package:flutter_test/flutter_test.dart';
import 'package:screen_time/providers/user_provider.dart';

void main() {
  test('UserState.copyWith handles nullable user id updates', () {
    const state = UserState(userId: '123-abc-456');

    final loggedOutState = state.copyWith(userId: null);
    final changedUserState = state.copyWith(userId: '987-xyz-654');
    final unchangedUserState = state.copyWith(isLoading: true);

    expect(loggedOutState.userId, isNull);
    expect(changedUserState.userId, '987-xyz-654');
    expect(unchangedUserState.userId, '123-abc-456');
    expect(unchangedUserState.isLoading, isTrue);
  });
}
