import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/views/debug/security_debug_page.dart';
import '../../presentation/views/home/home_page.dart';
import '../../presentation/views/main/main_page.dart';
import 'app_routes.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainPage(child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          name: 'home',
          builder: (context, state) => const HomePage(),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.debug,
      name: 'debug',
      redirect: (context, state) => _debugGuard(context, state),
      routes: [
        GoRoute(
          path: AppRoutes.securityDebug,
          name: 'securityDebug',
          builder: (context, state) => const SecurityDebugPage(),
        ),
      ],
    ),
  ],
);

String? _debugGuard(BuildContext context, GoRouterState state) {
  if (!kDebugMode) {
    return AppRoutes.home;
  }
  return null;
}
