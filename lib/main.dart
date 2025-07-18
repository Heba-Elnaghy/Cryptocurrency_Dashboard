import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'injection_container.dart' as di;
import 'presentation/bloc/bloc.dart';
import 'presentation/pages/dashboard_page.dart';
import 'core/performance/final_optimizations.dart';
import 'core/constants/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations for better UX
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Initialize dependency injection
  await di.init();

  // Run the app
  runApp(const CryptoDashboardApp());
}

class CryptoDashboardApp extends StatefulWidget {
  const CryptoDashboardApp({super.key});

  @override
  State<CryptoDashboardApp> createState() => _CryptoDashboardAppState();
}

class _CryptoDashboardAppState extends State<CryptoDashboardApp> {
  @override
  void dispose() {
    // Cleanup final optimizations
    FinalOptimizations.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.createLightTheme(),
      darkTheme: AppTheme.createDarkTheme(),
      themeMode: ThemeMode.system,
      home: BlocProvider(
        create: (context) => di.sl<CryptocurrencyBloc>(),
        child: const DashboardPage(),
      ),
    );
  }
}
