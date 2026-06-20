import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/supabase_service.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  final SupabaseService _supabaseService = SupabaseService();

  void _handleRegistration() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match!'), backgroundColor: AppColors.error),
        );
        return;
      }

      setState(() => _isLoading = true);
      try {
        await _supabaseService.registerUser(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          fullName: _nameController.text.trim(),
        );

        if (mounted) {
          // Success structural dialog block matching image expectations
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Registration Successful'),
              content: const Text('Registration successful! Awaiting admin approval.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close alert
                    Navigator.pop(context); // Return to login container flow
                  },
                  child: const Text('OK', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              const Icon(Icons.layers, size: 54, color: Colors.white),
              const SizedBox(height: 8),
              const Text(
                'Join Secure Vote',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Text(
                'Register to start voting',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 24),
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
                          const Center(
                            child: Text(
                              'Create Account',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                          ),
                          const Center(
                            child: Text(
                              'Join SecureVote today',
                              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text('Full Name', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          CustomTextField(
                            hintText: 'Enter your full name',
                            controller: _nameController,
                            prefixIcon: Icons.person_outline,
                            validator: (val) => val!.isEmpty ? 'Name cannot be empty' : null,
                          ),
                          const SizedBox(height: 16),
                          const Text('Email Address', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          CustomTextField(
                            hintText: 'Enter your email',
                            controller: _emailController,
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (val) => val!.contains('@') ? null : 'Provide a valid email address',
                          ),
                          const SizedBox(height: 16),
                          const Text('Password', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          CustomTextField(
                            hintText: 'Create a password',
                            controller: _passwordController,
                            prefixIcon: Icons.lock_outline,
                            isPassword: true,
                            validator: (val) => val!.length >= 6 ? null : 'Minimum 6 character requirement',
                          ),
                          const SizedBox(height: 16),
                          const Text('Confirm Password', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          CustomTextField(
                            hintText: 'Repeat password entry',
                            controller: _confirmPasswordController,
                            prefixIcon: Icons.lock_clock_outlined,
                            isPassword: true,
                            validator: (val) => val!.isEmpty ? 'Confirm your password entry' : null,
                          ),
                          const SizedBox(height: 30),
                          CustomButton(
                            text: 'Register',
                            isLoading: _isLoading,
                            onPressed: _handleRegistration,
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Already have an account? ', style: TextStyle(color: AppColors.textSecondary)),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Text(
                                  'Log In',
                                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
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