import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fuelsave/core/providers/car_provider.dart';
import 'package:fuelsave/core/providers/history_provider.dart';
import 'package:fuelsave/modules/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const FuelSaveApp());
}

class FuelSaveApp extends StatelessWidget {
  const FuelSaveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CarProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
      ],
      child: MaterialApp(
        title: 'FuelSave',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        darkTheme: _buildDarkTheme(),
        home: const SplashScreen(), // Definindo SplashScreen como tela inicial
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.green,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontWeight: FontWeight.bold),
        displayMedium: TextStyle(fontWeight: FontWeight.bold),
        titleLarge: TextStyle(fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontSize: 16.0),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}