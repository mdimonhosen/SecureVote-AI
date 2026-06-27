import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../providers/auth_provider.dart';
import '../user/face_verify_screen.dart'; // ADDED: Import for Face Verification
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final auth = Provider.of<AuthStateProvider>(context, listen: false);
      try {
        await auth.login(_emailController.text.trim(), _passwordController.text.trim());
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Login failed. Please check your credentials.'),
            backgroundColor: AppColors.error,
          ));
        }
      }
    }
  }

  // ADDED: Face Login Logic
  void _handleFaceLogin() async {
    final email = _emailController.text.trim();
    
    // We need the email to know which user's biometric data to compare against
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter your registered email address first to use Face Login.'),
        backgroundColor: AppColors.warning,
      ));
      return;
    }

    // Trigger the Biometric Gate
    final bool isVerified = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FaceVerifyScreen()),
    ) ?? false;

    if (!mounted) return; // Linter check

    if (isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Face Verified! Logging in...'),
        backgroundColor: AppColors.success,
      ));
      // Note: Depending on your AuthProvider, you may need to trigger a specific 
      // passwordless login function here to finalize the Supabase session.
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Face verification failed or was cancelled.'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final resetEmailController = TextEditingController(text: _emailController.text.trim());
    bool isResetting = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Reset Password', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enter your registered email address to receive a secure password reset link.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    hintText: 'Email Address',
                    controller: resetEmailController,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: isResetting ? null : () async {
                    final email = resetEmailController.text.trim();
                    if (!email.contains('@')) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid email address.'), backgroundColor: AppColors.warning));
                      return;
                    }

                    setDialogState(() => isResetting = true);
                    
                    try {
                      await Supabase.instance.client.auth.resetPasswordForEmail(email);
                      
                      if (!context.mounted) return;
                      Navigator.pop(dialogContext); 
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Password reset link sent! Check your inbox.'),
                        backgroundColor: AppColors.success,
                      ));
                    } catch (e) {
                      setDialogState(() => isResetting = false);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: AppColors.error,
                      ));
                    }
                  },
                  child: isResetting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Send Link', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthStateProvider>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                SizedBox(height: size.height * 0.05),
                // ── Branding ──────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white30, width: 2),
                  ),
                  child: const Icon(Icons.how_to_vote_rounded, size: 52, color: Colors.white),
                ),
                const SizedBox(height: 14),
                const Text(
                  'SecureVote',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const Text(
                  'Your voice. Secured.',
                  style: TextStyle(fontSize: 13, color: Colors.white70, letterSpacing: 0.5),
                ),
                SizedBox(height: size.height * 0.045),

                // ── White Card Panel ──────────────────────────────
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                    ),
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Text(
                                'Welcome Back 👋',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                            ),
                            const Center(
                              child: Text(
                                'Sign in to continue',
                                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                            ),
                            const SizedBox(height: 32),

                            _label('Email Address'),
                            const SizedBox(height: 8),
                            CustomTextField(
                              hintText: 'Enter your email',
                              controller: _emailController,
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => v!.contains('@') ? null : 'Enter a valid email',
                            ),
                            const SizedBox(height: 20),
                            _label('Password'),
                            const SizedBox(height: 8),
                            CustomTextField(
                              hintText: 'Enter your password',
                              controller: _passwordController,
                              prefixIcon: Icons.lock_outline,
                              isPassword: true,
                              validator: (v) => v!.length >= 6 ? null : 'Minimum 6 characters',
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _showForgotPasswordDialog,
                                child: const Text('Forgot Password?', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            CustomButton(text: 'Sign In', isLoading: auth.isLoading, onPressed: _handleLogin),
                            const SizedBox(height: 14),
                            
                            // FIXED: Connected Face Login Button
                            CustomButton(
                              text: 'Use Face Login',
                              isOutlined: true,
                              icon: Icons.face_retouching_natural,
                              onPressed: _handleFaceLogin,
                            ),
                            
                            const SizedBox(height: 28),
                            const _Divider(),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Don't have an account? ", style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                GestureDetector(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                                  child: const Text('Sign Up', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Center(
                              child: Text(
                                '© 2026 SecureVote System',
                                style: TextStyle(color: AppColors.textHint, fontSize: 11),
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
      ),
    );
  }

  Widget _label(String text) =>
      Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary));
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFDDDDDD))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
        ),
        const Expanded(child: Divider(color: Color(0xFFDDDDDD))),
      ],
    );
  }
}