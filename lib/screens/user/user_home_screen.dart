import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/poll_provider.dart';
import '../../models/poll_model.dart';
import 'profile_screen.dart'; 

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Fetch the latest polls immediately on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PollProvider>(context, listen: false).fetchAllPolls();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthStateProvider>(context);
    final pollProvider = Provider.of<PollProvider>(context);
    final user = authProvider.currentUser;

    final allPolls = pollProvider.polls;
    final now = DateTime.now();

    // Categorized lists for the quick poll tabs
    final ongoingPolls = allPolls.where((p) => p.startDate.isBefore(now) && p.endDate.isAfter(now)).toList();
    final expiredPolls = allPolls.where((p) => p.endDate.isBefore(now)).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Voter Portal', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Extra Main Dashboard Logout Button requested
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            tooltip: 'Secure Logout',
            onPressed: () async {
              await authProvider.logout();
            },
          ),
          // User profile image wrapper
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 4.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
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
                  child: Icon(Icons.person, color: AppColors.primary, size: 20),
                ),
              ),
            ),
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Current'),
            Tab(text: 'Expired'),
            Tab(text: 'Winners'),
          ],
        ),
      ),
      body: pollProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: () => pollProvider.fetchAllPolls(),
              color: AppColors.primary,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPollTabList(context, allPolls, 'all', user?.fullName),
                  _buildPollTabList(context, ongoingPolls, 'current', user?.fullName),
                  _buildPollTabList(context, expiredPolls, 'expired', user?.fullName),
                  _buildPollTabList(context, expiredPolls, 'winners', user?.fullName),
                ],
              ),
            ),
    );
  }

  Widget _buildPollTabList(BuildContext context, List<PollModel> polls, String tabType, String? voterName) {
    if (polls.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No updates available here.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: polls.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0, left: 4.0, top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hello, ${voterName ?? 'Voter'} 👋', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                const Text('Review operational ballots or monitor live status checks below.', style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          );
        }
        return _buildDetailedPollCard(context, polls[index - 1], tabType);
      },
    );
  }

  Widget _buildDetailedPollCard(BuildContext context, PollModel poll, String tabType) {
    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');
    final now = DateTime.now();
    final isOngoing = poll.startDate.isBefore(now) && poll.endDate.isAfter(now);

    String actionLabel = 'Cast Vote';
    IconData actionIcon = Icons.how_to_vote;
    Color thematicColor = AppColors.primary;

    if (tabType == 'winners') {
      actionLabel = 'Declared Winner';
      actionIcon = Icons.emoji_events;
      thematicColor = Colors.amber.shade700;
    } else if (!isOngoing) {
      actionLabel = 'View Final Results';
      actionIcon = Icons.analytics_outlined;
      thematicColor = Colors.blueGrey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Access Scope Ribbon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(poll.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: poll.isPrivate ? Colors.amber.shade50 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        poll.isPrivate ? 'PRIVATE POLL' : 'PUBLIC POLL',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: poll.isPrivate ? Colors.amber.shade800 : Colors.green.shade800),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 6),
                Text(poll.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                
                const SizedBox(height: 16),
                const Text('Nominated Candidates & Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),

                // Simulated Candidate Roster with Detail metrics
                Row(
                  children: [
                    _buildCandidateAvatar('C1', Colors.blue.shade100, Colors.blue),
                    const SizedBox(width: 6),
                    _buildCandidateAvatar('C2', Colors.purple.shade100, Colors.purple),
                    const SizedBox(width: 6),
                    _buildCandidateAvatar('C3', Colors.teal.shade100, Colors.teal),
                    const Spacer(),
                    if (isOngoing)
                      Row(
                        children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          const Text('LIVE VOTE STATUS', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      )
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Actions Area Layout
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Route handling initialized for: $actionLabel')));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: thematicColor.withValues(alpha: 0.04),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Terminus: ${dateFormat.format(poll.endDate)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  Row(
                    children: [
                      Text(actionLabel, style: TextStyle(color: thematicColor, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 4),
                      Icon(actionIcon, size: 16, color: thematicColor),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCandidateAvatar(String shortLabel, Color bg, Color textC) {
    return CircleAvatar(
      radius: 14,
      backgroundColor: bg,
      child: Text(shortLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textC)),
    );
  }
}