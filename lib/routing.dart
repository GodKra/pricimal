import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pricimal/basket.dart';
import 'package:pricimal/home.dart';

final GoRouter router = GoRouter(
  initialLocation: '/basket',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return HomeLayout(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/basket',
              builder: (context, state) => const Scaffold(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/shops',
              builder: (context, state) => const Scaffold(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/deals',
              builder: (context, state) => const Scaffold(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/history',
              builder: (context, state) => const Scaffold(),
            ),
          ],
        ),
      ],
    ),
  ],
);