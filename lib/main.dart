import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:positive_phill/providers/theme_provider.dart';
import 'package:positive_phill/providers/user_provider.dart';
import 'package:positive_phill/theme.dart';
import 'package:positive_phill/nav.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Mobile Ads only on supported platforms (Android/iOS). Skip on web.
  if (!kIsWeb) {
    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      debugPrint('MobileAds initialization skipped or failed: $e');
    }
  } else {
    debugPrint('Running on web: Google Mobile Ads is disabled.');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: 'Positive Phill',
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
