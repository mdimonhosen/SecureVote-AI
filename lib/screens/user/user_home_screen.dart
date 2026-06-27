import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/poll_provider.dart';
import '../../providers/language_provider.dart';
import '../../models/poll_model.dart';
import '../../models/candidate_model.dart';
import 'profile_screen.dart';
import 'cast_vote_screen.dart';
import '../../../main.dart' show AuthWrapper;

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _profileImageUrl;
  Set<String> _votedPollIds = {};
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PollProvider>(context, listen: false).fetchAllPolls();
      NotificationService().startInAppNotifications(context);
      _loadUserExtras();
    });
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) Provider.of<PollProvider>(context, listen: false).fetchAllPolls();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserExtras() async {
    final db = Supabase.instance.client;
    final uid = db.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final userRow = await db.from('users').select('image_url').eq('id', uid).maybeSingle();
      final voteRows = await db.from('votes').select('poll_id').eq('voter_id', uid);
      if (!mounted) return;
      setState(() {
        _profileImageUrl = (userRow)?['image_url'] as String?;
        _votedPollIds = {for (final v in voteRows) v['poll_id'] as String};
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthStateProvider>(context);
    final pollProvider = Provider.of<PollProvider>(context);
    final lang = Provider.of<LanguageProvider>(context);
    final user = auth.currentUser;
    final now = DateTime.now();
    final all = pollProvider.polls;
    final ongoing =
        all.where((p) => p.startDate.isBefore(now) && p.endDate.isAfter(now)).toList();
    final upcoming = all.where((p) => p.startDate.isAfter(now)).toList();
    final expired = all.where((p) => p.endDate.isBefore(now)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      // ── AppBar ──────────────────────────────────────────────────
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Container(
          decoration: const BoxDecoration(gradient: AppColors.heroGradient),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${lang.t('hello')}, ${user?.fullName.split(' ').first ?? 'Voter'} 👋',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(lang.t('review_ballots'),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                  // Profile photo avatar
                  InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProfileScreen()),
                      );
                      if (mounted) _loadUserExtras();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white54, width: 2),
                      ),
                      child: CircleAvatar(
                        backgroundColor: Colors.white24,
                        radius: 22,
                        backgroundImage: _profileImageUrl != null
                            ? NetworkImage(_profileImageUrl!)
                            : null,
                        child: _profileImageUrl == null
                            ? const Icon(Icons.person,
                                color: Colors.white, size: 24)
                            : null,
                      ),
                    ),
                  ),
                  // Logout
                  IconButton(
                    icon: const Icon(Icons.logout,
                        color: Colors.white70, size: 22),
                    tooltip: lang.t('logout'),
                    onPressed: () async {
                      final nav = Navigator.of(context);
                      await auth.logout();
                      if (!mounted) return;
                      nav.pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (_) => const AuthWrapper()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      // ── TabBar below AppBar ──────────────────────────────────────
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(text: lang.t('all')),
                Tab(text: lang.t('current')),
                _upcomingTab(upcoming.length, lang.t('upcoming')),
                Tab(text: lang.t('expired')),
              ],
            ),
          ),
          Expanded(
            child: pollProvider.isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary))
                : RefreshIndicator(
                    onRefresh: () async {
                      await pollProvider.fetchAllPolls();
                      await _loadUserExtras();
                    },
                    color: AppColors.primary,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildList(all, lang),
                        _buildList(ongoing, lang),
                        _buildList(upcoming, lang),
                        _buildList(expired, lang),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _upcomingTab(int count, String label) => Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8)),
                child: Text('$count',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      );

  Widget _buildList(List<PollModel> polls, LanguageProvider lang) {
    if (polls.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                  color: AppColors.primaryLight, shape: BoxShape.circle),
              child: Icon(Icons.inbox_outlined,
                  size: 48,
                  color: AppColors.primary.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 16),
            Text(lang.t('no_polls'),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 15)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: polls.length,
      itemBuilder: (context, i) => _buildPollCard(polls[i], lang),
    );
  }

  Widget _buildPollCard(PollModel poll, LanguageProvider lang) {
    final dateFormat = DateFormat('MMM dd, yyyy – hh:mm a');
    final now = DateTime.now();
    final isOngoing =
        poll.startDate.isBefore(now) && poll.endDate.isAfter(now);
    final isUpcoming = poll.startDate.isAfter(now);
    final isExpired = poll.endDate.isBefore(now);
    final hasVoted = _votedPollIds.contains(poll.id);

    final pollProvider =
        Provider.of<PollProvider>(context, listen: false);
    final candidates = pollProvider.getCandidatesForPoll(poll.id);
    final totalVotes = candidates.fold(0, (s, c) => s + c.voteCount);

    final Color themeColor = isUpcoming
        ? Colors.indigo
        : isOngoing
            ? AppColors.primary
            : Colors.blueGrey.shade600;

    final String actionLabel = isUpcoming
        ? 'View Details'
        : isOngoing
            ? (hasVoted
                ? lang.t('view_results')
                : lang.t('cast_vote'))
            : lang.t('view_results');

    final IconData actionIcon = isUpcoming
        ? Icons.info_outline_rounded
        : isOngoing
            ? (hasVoted
                ? Icons.bar_chart_rounded
                : Icons.how_to_vote_rounded)
            : Icons.bar_chart_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top colour strip
          Container(
            height: 6,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [themeColor, themeColor.withValues(alpha: 0.4)]),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(poll.title,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _badge(
                          poll.isPrivate ? '🔒 Private' : '🌐 Public',
                          poll.isPrivate ? Colors.amber : Colors.green,
                        ),
                        if (hasVoted) ...[
                          const SizedBox(height: 4),
                          _badge('✓ Voted', Colors.teal),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(poll.description,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                // Stats chips
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _statChip(Icons.people_outline,
                        '${candidates.length} candidates', themeColor),
                    _statChip(Icons.how_to_vote_outlined,
                        '$totalVotes votes', themeColor),
                    if (isUpcoming)
                      _statChip(
                          Icons.schedule,
                          'Starts ${DateFormat('MMM dd').format(poll.startDate)}',
                          Colors.indigo),
                  ],
                ),
                const SizedBox(height: 14),
                // Candidates / winner preview
                if (isExpired && candidates.isNotEmpty) ...[
                  Text(lang.t('declared_winner'),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade500)),
                  const SizedBox(height: 8),
                  _winnerRow(candidates, lang),
                ] else ...[
                  Text(lang.t('nominated_candidates'),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade500)),
                  const SizedBox(height: 8),
                  Row(
                    children: candidates
                        .take(8)
                        .map((c) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: CircleAvatar(
                                radius: 15,
                                backgroundColor: AppColors.primaryLight,
                                backgroundImage: c.imageUrl != null
                                    ? NetworkImage(c.imageUrl!)
                                    : null,
                                child: c.imageUrl == null
                                    ? const Icon(Icons.person,
                                        size: 14, color: AppColors.primary)
                                    : null,
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          // Footer tap row
          InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => CastVoteScreen(poll: poll)),
              );
              if (mounted) _loadUserExtras();
            },
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.06),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 13, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        isUpcoming
                            ? 'Starts: ${dateFormat.format(poll.startDate)}'
                            : 'Ends: ${dateFormat.format(poll.endDate)}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(actionLabel,
                          style: TextStyle(
                              color: themeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                      const SizedBox(width: 4),
                      Icon(actionIcon, size: 16, color: themeColor),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _badge(String label, Color color) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color.withValues(alpha: 0.9))),
      );

  Widget _winnerRow(List<CandidateModel> candidates, LanguageProvider lang) {
    final winner =
        candidates.reduce((a, b) => a.voteCount > b.voteCount ? a : b);
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.goldLight,
          backgroundImage: winner.imageUrl != null
              ? NetworkImage(winner.imageUrl!)
              : null,
          child: winner.imageUrl == null
              ? const Icon(Icons.emoji_events_rounded, color: AppColors.gold)
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(winner.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold,
                      fontSize: 14)),
              Text('${winner.voteCount} ${lang.t('votes_received')}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
        const Icon(Icons.emoji_events_rounded,
            color: AppColors.gold, size: 28),
      ],
    );
  }
}
