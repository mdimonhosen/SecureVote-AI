import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import 'manage_users_screen.dart';
import 'create_poll_screen.dart';
import 'manage_polls_screen.dart';
import 'admin_profile_screen.dart'; 

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  // Fetches live metrics from the database
  Future<Map<String, int>> _fetchDashboardMetrics() async {
    final supabase = Supabase.instance.client;
    final now = DateTime.now().toIso8601String();

    try {
      final users = await supabase.from('users').select('id');
      final pending = await supabase.from('users').select('id').eq('status', 'pending');
      final polls = await supabase.from('polls').select('id').gte('end_date', now);
      final votes = await supabase.from('votes').select('id');

      return {
        'totalUsers': users.length,
        'pendingUsers': pending.length,
        'activePolls': polls.length,
        'totalVotes': votes.length,
      };
    } catch (e) {
      debugPrint('Error fetching metrics: $e');
      return {'totalUsers': 0, 'pendingUsers': 0, 'activePolls': 0, 'totalVotes': 0};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // PREMIUM ADMIN AVATAR (Replaces the basic logout button)
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProfileScreen()));
              },
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: const CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  radius: 16,
                  child: Icon(Icons.admin_panel_settings, color: AppColors.primary, size: 20),
                ),
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            
            // LIVE METRICS GRID
            FutureBuilder<Map<String, int>>(
              future: _fetchDashboardMetrics(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final metrics = snapshot.data ?? {'totalUsers': 0, 'pendingUsers': 0, 'activePolls': 0, 'totalVotes': 0};

                return GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatCard(
                      context: context,
                      title: 'Total Users', 
                      count: metrics['totalUsers'].toString(), 
                      icon: Icons.people_outline,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageUsersScreen())),
                    ),
                    _buildStatCard(
                      context: context,
                      title: 'Pending', 
                      count: metrics['pendingUsers'].toString(), 
                      icon: Icons.assignment_ind_outlined,
                      color: metrics['pendingUsers']! > 0 ? Colors.orange.shade100 : AppColors.primaryLight,
                      iconColor: metrics['pendingUsers']! > 0 ? Colors.orange.shade800 : AppColors.primary,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageUsersScreen())),
                    ),
                    _buildStatCard(
                      context: context,
                      title: 'Active Polls', 
                      count: metrics['activePolls'].toString(), 
                      icon: Icons.how_to_vote_outlined,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagePollsScreen())),
                    ),
                    _buildStatCard(
                      context: context,
                      title: 'Total Votes', 
                      count: metrics['totalVotes'].toString(), 
                      icon: Icons.groups_outlined,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagePollsScreen())),
                    ),
                  ],
                );
              }
            ),
            
            const SizedBox(height: 32),
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context,
              title: 'Manage Users',
              subtitle: 'Approve, reject or view all users',
              icon: Icons.manage_accounts,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageUsersScreen())),
            ),
            const SizedBox(height: 12),
            _buildActionCard(
              context,
              title: 'Manage Polls',
              subtitle: 'Create, view or delete polls',
              icon: Icons.poll_outlined,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagePollsScreen())),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePollScreen()),
          ).then((_) {
            // Forces the dashboard to refresh the numbers when you come back
            if (context.mounted) {
              (context as Element).markNeedsBuild();
            }
          });
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title, 
    required String count, 
    required IconData icon, 
    required VoidCallback onTap,
    Color? color,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color ?? AppColors.primaryLight,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor ?? AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(count, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}