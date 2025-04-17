import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:screen_time/providers/user_provider.dart';
import 'package:screen_time/screens/Home.dart';
import 'package:screen_time/screens/Login.dart';

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<String?>(
      userIdProvider,
      (_, __) => notifyListeners(),
    );
  }

  String? _redirectLogic(BuildContext context, GoRouterState state) {
    final userId = _ref.read(userIdProvider);
    print("User ID: $userId");
    if (userId != null) {
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
        routes: <RouteBase>[
          GoRoute(
            path: 'login',
            builder: (BuildContext context, GoRouterState state) {
              return const LoginPage();
            },
          ),
        ],
      ),
    ],
    refreshListenable: routerNotifier,
    redirect: routerNotifier._redirectLogic,
  );
});
