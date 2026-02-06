import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:positive_phill/screens/home_screen.dart';
import 'package:positive_phill/screens/session_flow_screen.dart';
import 'package:positive_phill/screens/settings_screen.dart';
import 'package:positive_phill/screens/webview_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (context, state) => NoTransitionPage(
          child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.session,
        name: 'session',
        pageBuilder: (context, state) => MaterialPage(
          child: const SessionFlowScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        pageBuilder: (context, state) => MaterialPage(
          child: const SettingsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.webview,
        name: 'webview',
        pageBuilder: (context, state) => MaterialPage(
          child: const WebViewScreen(),
        ),
      ),
    ],
  );
}

class AppRoutes {
  static const String home = '/';
  static const String session = '/session';
  static const String settings = '/settings';
  static const String webview = '/webview';
}
