import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:positive_phill/models/rescue_intent.dart';
import 'package:positive_phill/screens/favorites_screen.dart';
import 'package:positive_phill/screens/home_screen.dart';
import 'package:positive_phill/screens/rescue_flow_screen.dart';
import 'package:positive_phill/screens/rescue_screen.dart';
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
      GoRoute(
        path: AppRoutes.favorites,
        name: 'favorites',
        pageBuilder: (context, state) => MaterialPage(
          child: const FavoritesScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.rescueFlow,
        name: 'rescueFlow',
        pageBuilder: (context, state) {
          final extra = state.extra;
          final intent =
              extra is RescueIntent ? extra : RescueIntent.calm;
          return MaterialPage(
            child: RescueFlowScreen(intent: intent),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.rescue,
        name: 'rescue',
        pageBuilder: (context, state) => MaterialPage(
          child: const RescueScreen(),
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
  static const String favorites = '/favorites';
  static const String rescue = '/rescue';
  static const String rescueFlow = '/rescue/flow';
}
