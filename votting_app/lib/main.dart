import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'services/supabase_service.dart';
import 'services/localization_service.dart';
import 'services/face_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Services
  await SupabaseService.init();
  
  final localizationService = LocalizationService();
  await localizationService.init();

  final faceService = FaceService();
  await faceService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<LanguageProvider>(
          create: (_) => LanguageProvider(localizationService),
        ),
        Provider<SupabaseService>(create: (_) => SupabaseService()),
        Provider<FaceService>(create: (_) => faceService),
      ],
      child: const VotingApp(),
    ),
  );
}

class LanguageProvider extends ChangeNotifier {
  final LocalizationService _service;
  LanguageProvider(this._service) {
    _init();
  }

  String _currentLanguage = 'bn';
  String get currentLanguage => _currentLanguage;
  LocalizationService get service => _service;

  void _init() async {
    _currentLanguage = await _service.getLanguage();
    notifyListeners();
  }

  void setLanguage(String code) async {
    _currentLanguage = code;
    await _service.setLanguage(code);
    notifyListeners();
  }

  Future<String> getLanguage() => _service.getLanguage();
}

class VotingApp extends StatelessWidget {
  const VotingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secure Voting System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3C72)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
