import 'package:go_router/go_router.dart';

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
  ],
);
