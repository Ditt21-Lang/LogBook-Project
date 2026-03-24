import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logbook_app_001/features/logbook/models/log_model.dart';
import 'package:logbook_app_001/features/onboarding/onboarding_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart'; 
import 'package:logbook_app_001/features/auth/login_view.dart';
import 'package:intl/date_symbol_data_local.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  //Load .env
  await dotenv.load(fileName: ".env");

  //Inisialisas HIVE
  await Hive.initFlutter();
  Hive.registerAdapter(LogModelAdapter());
  Hive.registerAdapter(LogCategoryAdapter());
  await Hive.openBox<LogModel>(
    'offline_logs',
  );
  await Hive.openBox('pending_ops');

  final prefs = await SharedPreferences.getInstance();
  final bool isOnboardingDone = prefs.getBool("isOnboardingDone") ?? false;

  runApp(MyApp(isOnboardingDone: isOnboardingDone));
}

class MyApp extends StatelessWidget {
  final bool isOnboardingDone;

  const MyApp({super.key, required this.isOnboardingDone});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Logbook App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: isOnboardingDone ? const LoginView() : OnboardingView(),
    );
  }
}
