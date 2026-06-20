import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Grab the current user's data from our provider
    final authProvider = Provider.of<AuthStateProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Voter Profile', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Avatar
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(Icons.person, size: 50, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Name and Role
                  Text(
                    user.fullName,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      'STATUS: ${user.status.toUpperCase()}',
                      style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // User Details List
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Registration Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                  const SizedBox(height: 16),

                  _buildProfileCard(Icons.email_outlined, 'Email Address', user.email),
                  _buildProfileCard(Icons.badge_outlined, 'Role', user.role.toUpperCase()),
                  _buildProfileCard(
                    user.faceRegistered ? Icons.face_retouching_natural : Icons.warning_amber_rounded, 
                    'Biometric Status', 
                    user.faceRegistered ? 'Face ID Registered & Active' : 'Face ID Not Registered',
                    iconColor: user.faceRegistered ? Colors.green : Colors.orange,
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // Helper widget to build the data rows neatly
  Widget _buildProfileCard(IconData icon, String title, String value, {Color iconColor = AppColors.primary}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ),
    );
  }
}