import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import 'manage_users_screen.dart';
import 'create_poll_screen.dart';
import 'manage_polls_screen.dart';
import 'admin_profile_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _db = Supabase.instance.client;
  Map<String, int> _metrics = {'totalUsers': 0, 'pendingUsers': 0, 'activePolls': 0, 'totalVotes': 0};
  String? _adminImageUrl;
  bool _metricsLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadAll();
    // Refresh metrics every 30 seconds for live updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchMetrics());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([_fetchMetrics(), _fetchAdminPhoto()]);
  }

  Future<void> _fetchAdminPhoto() async {
    try {
      final uid = _db.auth.currentUser?.id;
      if (uid == null) return;
      final data = await _db.from('users').select('image_url').eq('id', uid).maybeSingle();
      if (mounted) setState(() => _adminImageUrl = data?['image_url']);
    } catch (_) {}
  }

  Future<void> _fetchMetrics() async {
    final now = DateTime.now().toIso8601String();
    try {
      final results = await Future.wait([
        _db.from('users').select('id'),
        _db.from('users').select('id').eq('status', 'pending'),
        _db.from('polls').select('id').gte('end_date', now),
        _db.from('votes').select('id'),
      ]);
      if (mounted) {
        setState(() {
          _metrics = {
            'totalUsers': (results[0] as List).length,
            'pendingUsers': (results[1] as List).length,
            'activePolls': (results[2] as List).length,
            'totalVotes': (results[3] as List).length,
          };
          _metricsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _metricsLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 130,
            pinned: true,
            backgroundColor: const Color(0xFF1A237E),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.adminGradient),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Admin Command Center',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3)),
                          SizedBox(height: 4),
                          Text('System overview & controls',
                              style: TextStyle(fontSize: 12, color: Colors.white60)),
                        ],
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminProfileScreen()),
                      ).then((_) => _fetchAdminPhoto()),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white38, width: 2),
                        ),
                        child: CircleAvatar(
                          backgroundColor: Colors.white24,
                          radius: 22,
                          backgroundImage: _adminImageUrl != null ? NetworkImage(_adminImageUrl!) : null,
                          child: _adminImageUrl == null
                              ? const Icon(Icons.admin_panel_settings, color: Colors.white, size: 24)
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: RefreshIndicator(
          onRefresh: _loadAll,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Live Metrics ──────────────────────────────────────
                Row(
                  children: [
                    _sectionTitle('Live Metrics'),
                    const SizedBox(width: 8),
                    const Icon(Icons.circle, size: 8, color: Colors.green),
                    const SizedBox(width: 4),
                    const Text('Live', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 14),
                _metricsLoading
                  ? const SizedBox(height: 160, child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
                  : GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.05,
                      children: [
                        _statCard(context,
                          title: 'Total Users',
                          count: '${_metrics['totalUsers']}',
                          icon: Icons.people_alt_rounded,
                          gradient: AppColors.cardGradient,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageUsersScreen())),
                        ),
                        _statCard(context,
                          title: 'Pending',
                          count: '${_metrics['pendingUsers']}',
                          icon: Icons.assignment_ind_outlined,
                          gradient: LinearGradient(colors: [
                            _metrics['pendingUsers']! > 0 ? const Color(0xFFE65100) : AppColors.primary,
                            _metrics['pendingUsers']! > 0 ? const Color(0xFFFF8F00) : AppColors.primaryDark,
                          ]),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageUsersScreen())),
                        ),
                        _statCard(context,
                          title: 'Active Polls',
                          count: '${_metrics['activePolls']}',
                          icon: Icons.how_to_vote_rounded,
                          gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF1976D2)]),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagePollsScreen())).then((_) => _fetchMetrics()),
                        ),
                        _statCard(context,
                          title: 'Total Votes',
                          count: '${_metrics['totalVotes']}',
                          icon: Icons.stacked_bar_chart_rounded,
                          gradient: const LinearGradient(colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)]),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagePollsScreen())).then((_) => _fetchMetrics()),
                        ),
                      ],
                    ),
                const SizedBox(height: 32),

                // ── Quick Actions ─────────────────────────────────────
                _sectionTitle('Quick Actions'),
                const SizedBox(height: 14),
                _actionTile(context,
                  title: 'Manage Users',
                  subtitle: 'Approve, reject or view all registered voters',
                  icon: Icons.manage_accounts_rounded,
                  iconBg: AppColors.primaryLight,
                  iconColor: AppColors.primary,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageUsersScreen())).then((_) => _fetchMetrics()),
                ),
                const SizedBox(height: 12),
                _actionTile(context,
                  title: 'Manage Polls',
                  subtitle: 'Create, edit or close election polls',
                  icon: Icons.poll_rounded,
                  iconBg: const Color(0xFFE3F2FD),
                  iconColor: const Color(0xFF1565C0),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManagePollsScreen())).then((_) => _fetchMetrics()),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        elevation: 6,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreatePollScreen()),
        ).then((_) => _fetchMetrics()),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Poll', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: 0.2),
  );

  Widget _statCard(BuildContext context, {
    required String title,
    required String count,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: gradient.colors.first.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const Spacer(),
            Text(count, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textHint, size: 14),
          ],
        ),
      ),
    );
  }
}
