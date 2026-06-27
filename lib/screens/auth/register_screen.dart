import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/supabase_service.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';

// Assuming you have a screen that handles the camera/ML Kit logic 
// and pops back with a List<double> representing the face embedding.
import '../user/face_register_screen.dart'; 

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // NEW: Store the captured biometric data
  List<double>? _faceEmbedding; 
  
  bool _isLoading = false;
  final _service = SupabaseService();

  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // NEW: Navigate to the camera screen to capture face biometrics
  Future<void> _captureFaceData() async {
    // Expected to return the embedding array after successful scan
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FaceRegisterScreen()), 
    );

    if (result != null && result is List<double>) {
      setState(() {
        _faceEmbedding = result;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Face data captured successfully!'), backgroundColor: AppColors.success),
        );
      }
    }
  }

  void _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match!'), backgroundColor: AppColors.error),
      );
      return;
    }

    // NEW: Enforce Face Registration before creating the account
    if (_faceEmbedding == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometric verification is required. Please register your Face ID.'), 
          backgroundColor: AppColors.warning
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // UPDATED: Pass the face embedding to the database service
      await _service.registerUser(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _nameController.text.trim(),
        faceEmbedding: _faceEmbedding, // Ensure your SupabaseService accepts this parameter
      );
      
      if (!mounted) return; // Linter fix for async gap
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success),
              SizedBox(width: 8),
              Text('Registered!'),
            ],
          ),
          content: const Text('Registration successful! Awaiting admin approval.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // ── Branding ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white30, width: 2),
                ),
                child: const Icon(Icons.how_to_vote_rounded, size: 42, color: Colors.white),
              ),
              const SizedBox(height: 10),
              const Text('Join SecureVote', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.8)),
              const Text('Create your voter account', style: TextStyle(fontSize: 13, color: Colors.white70)),
              const SizedBox(height: 24),

              // ── Form Card ────────────────────────────────────────
              Expanded(
                child: SlideTransition(
                  position: _slideAnim,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                    ),
                    padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Text('Create Account', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            ),
                            const Center(
                              child: Text('Fill in the details below', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            ),
                            const SizedBox(height: 28),
                            
                            _label('Full Name'),
                            const SizedBox(height: 6),
                            CustomTextField(hintText: 'Enter your full name', controller: _nameController, prefixIcon: Icons.person_outline, validator: (v) => v!.isEmpty ? 'Name is required' : null),
                            const SizedBox(height: 16),
                            
                            _label('Email Address'),
                            const SizedBox(height: 6),
                            CustomTextField(hintText: 'Enter your email', controller: _emailController, prefixIcon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: (v) => v!.contains('@') ? null : 'Enter a valid email'),
                            const SizedBox(height: 16),
                            
                            _label('Password'),
                            const SizedBox(height: 6),
                            CustomTextField(hintText: 'Create a password', controller: _passwordController, prefixIcon: Icons.lock_outline, isPassword: true, validator: (v) => v!.length >= 6 ? null : 'Minimum 6 characters'),
                            const SizedBox(height: 16),
                            
                            _label('Confirm Password'),
                            const SizedBox(height: 6),
                            CustomTextField(hintText: 'Repeat your password', controller: _confirmPasswordController, prefixIcon: Icons.lock_clock_outlined, isPassword: true, validator: (v) => v!.isEmpty ? 'Please confirm your password' : null),
                            const SizedBox(height: 24),

                            // NEW: Biometric Registration UI
                            _label('Biometric Security'),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: _captureFaceData,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _faceEmbedding == null ? Colors.grey.shade300 : AppColors.success,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  color: _faceEmbedding == null ? Colors.transparent : AppColors.success.withValues(alpha: 0.05),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _faceEmbedding == null ? Icons.face : Icons.check_circle, 
                                      color: _faceEmbedding == null ? AppColors.primary : AppColors.success,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _faceEmbedding == null ? 'Register Face ID' : 'Face ID Secured', 
                                            style: TextStyle(
                                              color: _faceEmbedding == null ? AppColors.textPrimary : AppColors.success, 
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            )
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _faceEmbedding == null ? 'Required to cast secure votes' : 'Biometric data ready for matching', 
                                            style: TextStyle(
                                              color: _faceEmbedding == null ? AppColors.textSecondary : AppColors.success.withValues(alpha: 0.8), 
                                              fontSize: 12,
                                            )
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_faceEmbedding == null)
                                      const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textHint),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),

                            CustomButton(text: 'Create Account', isLoading: _isLoading, onPressed: _handleRegistration),
                            const SizedBox(height: 20),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Already have an account? ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: const Text('Log In', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ],
                            ),
                          ],
                        ),
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

  Widget _label(String text) =>
      Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary));
}