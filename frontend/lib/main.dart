import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));
  runApp(const PortfolioApp());
}

class PortfolioApp extends StatelessWidget {
  const PortfolioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        title: 'Kshitij Sharma',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const HomeScreen(),
        builder: (context, child) {
          return ScrollConfiguration(
            behavior: _SmoothScrollBehavior(),
            child: child!,
          );
        },
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0A0A14),
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF7C4DFF),
        secondary: const Color(0xFF00E5FF),
        surface: const Color(0xFF12121E),
        error: const Color(0xFFFF5252),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontFamily: 'sans-serif', color: Colors.white70),
      ),
      fontFamily: 'sans-serif',
      useMaterial3: true,
    );
  }
}

class _SmoothScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics();
  }
}
