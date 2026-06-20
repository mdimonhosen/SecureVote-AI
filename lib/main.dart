import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      ],
      child: MaterialApp(
        title: 'Secure Voting',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            surface: AppColors.background,
          ),
          textTheme: GoogleFonts.poppinsTextTheme(
            Theme.of(context).textTheme,
          ),
          scaffoldBackgroundColor: AppColors.background,
        ),
        // The AuthWrapper dynamically decides which screen to show
        home: const AuthWrapper(), 
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
      appBar: AppBar(
        title: const Text('Account Pending'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textPrimary),
            onPressed: () => Provider.of<AuthStateProvider>(context, listen: false).logout(),
          )
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.hourglass_empty, size: 80, color: AppColors.warning),
              SizedBox(height: 24),
              Text(
                'Awaiting Admin Approval',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              SizedBox(height: 12),
              Text(
                'Your account has been created successfully, but an administrator must approve it before you can participate in polls.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}