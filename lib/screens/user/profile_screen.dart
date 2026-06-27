import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import 'face_register_screen.dart';
import '../../../main.dart' show AuthWrapper;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _db = Supabase.instance.client;
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return;
      final data = await _db.from('users').select().eq('id', uid).single();
      if (mounted) setState(() { _profile = data; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file == null) return;

    setState(() => _isUploading = true);
    try {
      final uid = _db.auth.currentUser!.id;
      final ext = file.name.split('.').last;
      final fileName = 'user_${uid}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final bytes = await file.readAsBytes();
      await _db.storage.from('user_images').uploadBinary(
        fileName, bytes,
        fileOptions: FileOptions(contentType: 'image/$ext'),
      );
      final url = _db.storage.from('user_images').getPublicUrl(fileName);
      await _db.from('users').update({'image_url': url}).eq('id', uid);
      await _loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: AppColors.error),
        );
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _showEditDialog() async {
    final nameCtrl    = TextEditingController(text: _profile?['name'] ?? '');
    final phoneCtrl   = TextEditingController(text: _profile?['phone'] ?? '');
    final addressCtrl = TextEditingController(text: _profile?['address'] ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _dialogField(nameCtrl, 'Full Name', Icons.person_outline),
            const SizedBox(height: 12),
            _dialogField(phoneCtrl, 'Phone Number', Icons.phone_outlined,
                type: TextInputType.phone),
            const SizedBox(height: 12),
            _dialogField(addressCtrl, 'Address', Icons.location_on_outlined,
                maxLines: 2),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                await _db.from('users').update({
                  'name': nameCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'address': addressCtrl.text.trim(),
                }).eq('id', _db.auth.currentUser!.id);
                await _loadProfile();
                messenger.showSnackBar(const SnackBar(
                    content: Text('Profile updated!'),
                    backgroundColor: AppColors.success));
              } catch (e) {
                messenger.showSnackBar(SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: AppColors.error));
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthStateProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);
    final user = auth.currentUser;
    final imageUrl = _profile?['image_url'] as String?;

    return Scaffold(
      backgroundColor: AppColors.background,
      // ── AppBar ────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Profile',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white70),
            tooltip: 'Edit Profile',
            onPressed: _showEditDialog,
          ),
        ],
      ),
      body: _isLoading && _profile == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              child: Column(
                children: [
                  // ── Hero section ────────────────────────────────────
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(gradient: AppColors.heroGradient),
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white54, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 16)
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 52,
                                backgroundColor: Colors.white24,
                                backgroundImage:
                                    imageUrl != null ? NetworkImage(imageUrl) : null,
                                child: imageUrl == null
                                    ? const Icon(Icons.person_rounded,
                                        size: 52, color: Colors.white)
                                    : null,
                              ),
                            ),
                            GestureDetector(
                              onTap: _isUploading ? null : _pickAndUploadPhoto,
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                                child: _isUploading
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                            color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.camera_alt,
                                        color: Colors.white, size: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _profile?['name'] ?? user?.fullName ?? 'Voter',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.3),
                        ),
                        const SizedBox(height: 6),
                        _statusBadge(user?.status ?? 'pending'),
                      ],
                    ),
                  ),

                  // ── Info + Actions ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel(lang.t('reg_details')),
                        const SizedBox(height: 12),
                        _infoCard(Icons.email_outlined, lang.t('email_addr'),
                            user?.email ?? ''),
                        if ((_profile?['phone'] as String?)?.isNotEmpty == true)
                          _infoCard(Icons.phone_outlined, 'Phone',
                              _profile!['phone'] as String),
                        if ((_profile?['address'] as String?)?.isNotEmpty == true)
                          _infoCard(Icons.location_on_outlined, 'Address',
                              _profile!['address'] as String),
                        _infoCard(Icons.badge_outlined, lang.t('role'),
                            (user?.role ?? 'user').toUpperCase()),
                        _infoCard(
                          user?.faceRegistered == true
                              ? Icons.face_retouching_natural
                              : Icons.warning_amber_rounded,
                          lang.t('biometric_status'),
                          user?.faceRegistered == true
                              ? lang.t('face_active')
                              : lang.t('face_missing'),
                          valueColor: user?.faceRegistered == true
                              ? AppColors.success
                              : AppColors.warning,
                          iconColor: user?.faceRegistered == true
                              ? AppColors.success
                              : AppColors.warning,
                        ),

                        const SizedBox(height: 28),
                        _sectionLabel('Actions'),
                        const SizedBox(height: 12),

                        if (user?.faceRegistered != true) ...[
                          _actionButton(
                            icon: Icons.face,
                            label: 'Register Face ID',
                            color: Colors.orange.shade700,
                            bgColor: Colors.orange.shade50,
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const FaceRegisterScreen())),
                          ),
                          const SizedBox(height: 12),
                        ],

                        _actionButton(
                          icon: Icons.language_rounded,
                          label: lang.t('change_lang'),
                          color: AppColors.primary,
                          bgColor: AppColors.primaryLight,
                          onTap: () => lang.toggleLanguage(),
                        ),
                        const SizedBox(height: 12),

                        // Logout button
                        _actionButton(
                          icon: Icons.logout_rounded,
                          label: lang.t('logout'),
                          color: AppColors.error,
                          bgColor: AppColors.error.withValues(alpha: 0.06),
                          borderColor: AppColors.error.withValues(alpha: 0.3),
                          onTap: () async {
                            await auth.logout();
                            // FIXED: Using context.mounted because context is the local parameter of build()
                            if (!context.mounted) return;
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (_) => const AuthWrapper()),
                              (route) => false,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  static Widget _statusBadge(String status) {
    final isApproved = status == 'approved';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: isApproved
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.orange.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white38),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2),
      ),
    );
  }

  static Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary),
      );

  static Widget _infoCard(
    IconData icon,
    String title,
    String value, {
    Color iconColor = AppColors.primary,
    Color? valueColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: valueColor ?? AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    Color? borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor ?? color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded,
                color: color.withValues(alpha: 0.5), size: 14),
          ],
        ),
      ),
    );
  }
}