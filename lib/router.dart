import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:screen_time/providers/user_provider.dart';
import 'package:screen_time/screens/Home.dart';
import 'package:screen_time/screens/Login.dart';
import 'package:screen_time/screens/Usage.dart';
import 'package:screen_time/screens/Splash.dart';
import 'package:screen_time/providers/usage_provider.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<String?>(
      userIdProvider,
      (_, __) => notifyListeners(),
    );
    _ref.listen<UsageState>(
      usageProvider,
      (_, __) => notifyListeners(),
    );
  }

  String? _redirectLogic(BuildContext context, GoRouterState state) {
    final userId = _ref.read(userIdProvider);
    final userIdNotifier = _ref.read(userIdProvider.notifier);
    final usageState = _ref.read(usageProvider);

    if ((userId == null && userIdNotifier.isLoading) ||
        (userId == null && usageState.isLoading)) {
      return '/splash';
    }

    if (userId == null) {
      return '/login';
    }

    if (!usageState.hasPermission) {
      if (state.uri.toString() != '/usage') {
        return '/usage';
      }
      return null;
    }

    if ((state.uri.toString() == '/login' ||
            state.uri.toString() == '/usage') &&
        usageState.hasPermission) {
      return '/';
    }
    return null;
  }
}

class RouterProps {
  final bool loggedIn;

  RouterProps({this.loggedIn = false});
}

final routerProvider = Provider.family<GoRouter, RouterProps>((ref, props) {
  final routerNotifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: props.loggedIn ? '/' : '/login',
    routes: [
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return const HomePage();
        },
      ),
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) {
          return const LoginPage();
        },
      ),
      GoRoute(
        path: '/usage',
        builder: (BuildContext context, GoRouterState state) {
          return const UsagePage();
        },
      ),
      GoRoute(
        path: '/splash',
        builder: (BuildContext context, GoRouterState state) {
          return const SplashPage();
        },
      ),
    ],
    refreshListenable: routerNotifier,
    redirect: routerNotifier._redirectLogic,
  );
});
