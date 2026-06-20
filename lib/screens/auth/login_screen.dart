import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthStateProvider>(context, listen: false);
      
      try {
        // Try to log in. It returns void now, not a bool.
        await authProvider.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        // If it succeeds, the code gets here! 
        // We don't need to manually navigate because main.dart (AuthWrapper) will detect the login automatically.

      } catch (e) {
        // If login fails (wrong password, user not found), the code jumps here
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login failed. Please check your credentials.'), 
              backgroundColor: AppColors.error
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthStateProvider>(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF514BB7), AppColors.primary],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 30),
              // App Logo branding header matching wireframe
              const Icon(Icons.layers, size: 64, color: Colors.white),
              const SizedBox(height: 12),
              const Text(
                'Secure Voting',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Text(
                'Your voice matters',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 40),
              // White panel layout housing login fields
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  padding: const EdgeInsets.all(24.0),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          const Center(
                            child: Text(
                              'Welcome Back',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                          ),
                          const Center(
                            child: Text(
                              'Sign in to your account',
                              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(height: 30),
                          const Text('Email Address', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          CustomTextField(
                            hintText: 'Enter your email',
                            controller: _emailController,
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (val) => val!.contains('@') ? null : 'Provide a valid email address',
                          ),
                          const SizedBox(height: 20),
                          const Text('Password', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          CustomTextField(
                            hintText: 'Enter your password',
                            controller: _passwordController,
                            prefixIcon: Icons.lock_outline,
                            isPassword: true,
                            validator: (val) => val!.length >= 6 ? null : 'Password must exceed 5 characters',
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: const Text('Forgot Password?', style: TextStyle(color: AppColors.textSecondary)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          CustomButton(
                            text: 'Sign In',
                            isLoading: authProvider.isLoading,
                            onPressed: _handleLogin,
                          ),
                          const SizedBox(height: 16),
                          CustomButton(
                            text: 'Use Face Login',
                            isOutlined: true,
                            icon: Icons.face,
                            onPressed: () {
                              // Triggers biometric passport scanner routine
                            },
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Don't have an account? ", style: TextStyle(color: AppColors.textSecondary)),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                ),
                                child: const Text(
                                  'Sign Up',
                                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          const Center(
                            child: Text(
                              '© 2026 Secure Voting System',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}