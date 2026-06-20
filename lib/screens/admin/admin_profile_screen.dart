import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Fetches live user data from the database
  Future<void> _loadUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final data = await _supabase.from('users').select().eq('id', user.id).single();
        if (mounted) {
          setState(() {
            _userProfile = data;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // FEATURE: Upload Profile Picture
  Future<void> _updateProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile == null) return;

    setState(() => _isLoading = true);
    try {
      final fileExt = pickedFile.name.split('.').last;
      final fileName = 'user_${_supabase.auth.currentUser!.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final imageBytes = await pickedFile.readAsBytes();

      // Upload to user_images bucket
      await _supabase.storage.from('user_images').uploadBinary(
        fileName, 
        imageBytes,
        fileOptions: FileOptions(contentType: 'image/$fileExt'),
      );
      
      final imageUrl = _supabase.storage.from('user_images').getPublicUrl(fileName);

      // Save URL to users table
      await _supabase.from('users').update({'image_url': imageUrl}).eq('id', _supabase.auth.currentUser!.id);
      
      await _loadUserProfile(); // Refresh data
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated!'), backgroundColor: AppColors.success));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      setState(() => _isLoading = false);
    } 
  }

  // FEATURE: Edit Profile (Pre-fills with existing data)
  Future<void> _showEditProfileDialog() async {
    final nameController = TextEditingController(text: _userProfile?['name'] ?? '');
    final phoneController = TextEditingController(text: _userProfile?['phone'] ?? '');
    final addressController = TextEditingController(text: _userProfile?['address'] ?? '');
    
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Information'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: addressController, maxLines: 2, decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(dialogContext);
              
              setState(() => _isLoading = true);
              try {
                await _supabase.from('users').update({
                  'name': nameController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'address': addressController.text.trim(),
                }).eq('id', _supabase.auth.currentUser!.id);
                
                await _loadUserProfile(); // Refresh UI
                messenger.showSnackBar(const SnackBar(content: Text('Profile updated!'), backgroundColor: AppColors.success));
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
                setState(() => _isLoading = false);
              } 
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // FEATURE: Strict Change Password (Requires Old Password)
  Future<void> _showChangePasswordDialog() async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Secure Password Change'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: oldPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'Current Password', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: newPasswordController, obscureText: true, decoration: const InputDecoration(labelText: 'New Password (min 6 chars)', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              if (newPasswordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New password must be at least 6 characters.'), backgroundColor: AppColors.error));
                return;
              }
              
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(dialogContext);
              setState(() => _isLoading = true);
              
              try {
                // 1. Verify old password by attempting to sign in
                await _supabase.auth.signInWithPassword(
                  email: _supabase.auth.currentUser!.email!, 
                  password: oldPasswordController.text
                );
                
                // 2. If successful, update to the new password
                await _supabase.auth.updateUser(UserAttributes(password: newPasswordController.text));
                messenger.showSnackBar(const SnackBar(content: Text('Password updated securely!'), backgroundColor: AppColors.success));
              } catch (e) {
                messenger.showSnackBar(const SnackBar(content: Text('Failed. Ensure your current password is correct.'), backgroundColor: AppColors.error));
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;
    final authProvider = Provider.of<AuthStateProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Admin Profile', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading || _userProfile == null
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // PREMIUM HEADER WITH IMAGE AND EMAIL
                Center(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 55,
                            backgroundColor: AppColors.primaryLight,
                            backgroundImage: _userProfile?['image_url'] != null ? NetworkImage(_userProfile!['image_url']) : null,
                            child: _userProfile?['image_url'] == null ? const Icon(Icons.person, size: 50, color: AppColors.primary) : null,
                          ),
                          GestureDetector(
                            onTap: _updateProfileImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(_userProfile?['name'] ?? 'Admin User', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(user?.email ?? '', style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.stars, size: 16, color: Colors.orange.shade800),
                            const SizedBox(width: 4),
                            Text('SYSTEM ADMIN', style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // ACCOUNT SETTINGS
                const Align(alignment: Alignment.centerLeft, child: Text('Account Settings', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person_outline, color: AppColors.primary),
                        title: const Text('Edit Profile Data'),
                        subtitle: Text('${_userProfile?['phone'] ?? 'No Phone'} • ${_userProfile?['address'] ?? 'No Address'}', maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _showEditProfileDialog,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.lock_outline, color: AppColors.primary),
                        title: const Text('Secure Password Change'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _showChangePasswordDialog,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // SYSTEM MANAGEMENT SECTION
                const Align(alignment: Alignment.centerLeft, child: Text('System Management', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
                  child: ListTile(
                    leading: const Icon(Icons.admin_panel_settings_outlined, color: Colors.orange),
                    title: const Text('Manage Administrators'),
                    subtitle: const Text('View, grant, or revoke admin access'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageAdminsScreen()));
                    },
                  ),
                ),
                const SizedBox(height: 40),

                // LOGOUT BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Secure Logout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    onPressed: () => authProvider.logout(),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

// ============================================================================
// NEW SCREEN: DEDICATED MANAGE ADMINS INTERFACE
// ============================================================================

class ManageAdminsScreen extends StatefulWidget {
  const ManageAdminsScreen({super.key});

  @override
  State<ManageAdminsScreen> createState() => _ManageAdminsScreenState();
}

class _ManageAdminsScreenState extends State<ManageAdminsScreen> {
  final _supabase = Supabase.instance.client;
  final _emailController = TextEditingController();
  List<Map<String, dynamic>> _admins = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAdmins();
  }

  // Fetch everyone who has the 'admin' role
  Future<void> _fetchAdmins() async {
    try {
      final data = await _supabase.from('users').select().eq('role', 'admin').order('name', ascending: true);
      if (mounted) {
        setState(() {
          _admins = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching admins: $e');
    }
  }

  // Promote a standard user to admin via email
  Future<void> _makeAdmin() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    
    try {
      // Find the user first
      final userSearch = await _supabase.from('users').select().eq('email', email);
      if (userSearch.isEmpty) {
        messenger.showSnackBar(const SnackBar(content: Text('User not found. Check email.'), backgroundColor: AppColors.error));
      } else {
        await _supabase.from('users').update({'role': 'admin'}).eq('email', email);
        _emailController.clear();
        await _fetchAdmins();
        messenger.showSnackBar(const SnackBar(content: Text('Successfully promoted to Admin!'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Reject / Revoke Admin Privileges
  Future<void> _revokeAdmin(String id, String email) async {
    if (id == _supabase.auth.currentUser!.id) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You cannot demote yourself!'), backgroundColor: AppColors.error));
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isLoading = true);
    try {
      await _supabase.from('users').update({'role': 'user'}).eq('id', id);
      await _fetchAdmins();
      messenger.showSnackBar(SnackBar(content: Text('$email demoted to standard user.'), backgroundColor: AppColors.success));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error revoking access: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Manage Admins', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          // ADD NEW ADMIN BAR
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Enter user email to promote',
                      prefixIcon: const Icon(Icons.person_add, color: AppColors.primary),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  onPressed: _makeAdmin,
                  child: const Text('Promote', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          
          // LIST OF CURRENT ADMINS
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _admins.length,
                  itemBuilder: (context, index) {
                    final admin = _admins[index];
                    final isMe = admin['id'] == _supabase.auth.currentUser!.id;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primaryLight,
                          backgroundImage: admin['image_url'] != null ? NetworkImage(admin['image_url']) : null,
                          child: admin['image_url'] == null ? const Icon(Icons.admin_panel_settings, color: AppColors.primary) : null,
                        ),
                        title: Text(admin['name'] ?? 'Unknown Admin', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(admin['email'], style: const TextStyle(fontSize: 12)),
                        trailing: isMe 
                          ? Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(12)),
                              child: const Text('YOU', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                            )
                          : IconButton(
                              icon: const Icon(Icons.remove_moderator, color: AppColors.error),
                              tooltip: 'Revoke Admin Access',
                              onPressed: () => _revokeAdmin(admin['id'], admin['email']),
                            ),
                      ),
                    );
                  },
                ),
          )
        ],
      ),
    );
  }
}