import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/language_provider.dart';

// Core imports
import 'core/constants/app_colors.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/poll_provider.dart';

// Screens
import 'screens/auth/login_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/user/user_home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://cjmeptdliyxgwmkplvrx.supabase.co',
    publishableKey: 'sb_publishable_7U5SKCaXUpUR8b3PC2KaeA_t9fsS5XS',
  );

  runApp(const SecureVoteApp());
}

class SecureVoteApp extends StatelessWidget {
  const SecureVoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthStateProvider()),
        ChangeNotifierProvider(create: (_) => PollProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()), // ADDED: Language Provider
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, langProvider, child) {
          return MaterialApp(
            title: 'Secure Voting',
            debugShowCheckedModeBanner: false,
            
            // ADDED: Binds the app language dynamically to the provider
            locale: langProvider.currentLocale, 
            
            // Automatically switch between light and dark based on the device's system settings
            themeMode: ThemeMode.system, 
            
            // Light Theme Configuration
            theme: ThemeData(
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                surface: AppColors.background,
                brightness: Brightness.light,
              ),
              textTheme: GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme),
              scaffoldBackgroundColor: AppColors.background,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.textPrimary,
                elevation: 0,
                centerTitle: false,
              ),
              cardTheme: CardThemeData(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
                color: Colors.white,
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            
            // Dark Theme Configuration
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.primary,
                surface: const Color(0xFF121212), // Deep dark surface
                brightness: Brightness.dark,
              ),
              textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).apply(
                bodyColor: Colors.white70,
                displayColor: Colors.white,
              ),
              scaffoldBackgroundColor: const Color(0xFF121212), // Deep dark background
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1E1E1E), // Slightly elevated dark color
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              cardColor: const Color(0xFF1E1E1E),
            ),
            
            home: const AuthWrapper(), 
          );
        }
      ),
    );
  }
}

/// This widget listens to the AuthStateProvider and routes the user.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthStateProvider>(context);

    // 1. Show loading screen while checking session
    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // 2. Not logged in? Show Login Screen
    final user = authProvider.currentUser;
    if (user == null) {
      return const LoginScreen();
    }

    // 3. Admin Bypass: If the user is ANY type of admin, route immediately to Admin Dashboard
    if (user.role == 'admin' || user.role == 'system_admin') {
      return const AdminDashboard();
    }

    // 4. Regular User Check: Are they still pending? Block access.
    if (user.status == 'pending') {
      return const PendingScreen();
    }

    // 5. User is approved! Route to Voter panel
    return const UserHomeScreen();
  }
}

/// A simple screen to block users who haven't been approved by the admin yet
class PendingScreen extends StatelessWidget {
  const PendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Account Pending', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            onPressed: () => Provider.of<AuthStateProvider>(context, listen: false).logout(),
          )
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.hourglass_top_rounded, size: 90, color: Colors.white),
                SizedBox(height: 24),
                Text(
                  'Awaiting Approval',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 12),
                Text(
                  'Your account has been created. An administrator must approve it before you can participate in polls.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, height: 1.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}