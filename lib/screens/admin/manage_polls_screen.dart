import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/poll_provider.dart';
import '../../models/poll_model.dart';
import 'package:intl/intl.dart';

class ManagePollsScreen extends StatefulWidget {
  const ManagePollsScreen({super.key});

  @override
  State<ManagePollsScreen> createState() => _ManagePollsScreenState();
}

class _ManagePollsScreenState extends State<ManagePollsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PollProvider>(context, listen: false).fetchAllPolls();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _deletePoll(String pollId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Poll?'),
        content: const Text('This will permanently delete the poll and all associated votes.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client.from('polls').delete().eq('id', pollId);
        if (mounted) Provider.of<PollProvider>(context, listen: false).fetchAllPolls();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete poll')));
      }
    }
  }

  void _showResultsDialog(PollModel poll) {
    final candidates = Provider.of<PollProvider>(context, listen: false).getCandidatesForPoll(poll.id);
    final totalVotes = candidates.fold(0, (sum, c) => sum + c.voteCount);
    
    final sortedCandidates = List.from(candidates)..sort((a, b) => b.voteCount.compareTo(a.voteCount));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(poll.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              poll.isPrivate ? 'Private Poll Registration' : 'Public Poll Registration',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Registered Candidates:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: sortedCandidates.length,
                  itemBuilder: (context, idx) {
                    final c = sortedCandidates[idx];
                    final percentage = totalVotes > 0 ? (c.voteCount / totalVotes * 100).toStringAsFixed(0) : '0';
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: c.imageUrl != null && c.imageUrl!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(7),
                                    child: Image.network(
                                      c.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.grey),
                                    ),
                                  )
                                : const Icon(Icons.person, color: Colors.grey),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                if (c.description != null && c.description!.isNotEmpty)
                                  Text(
                                    c.description!,
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${c.voteCount} ($percentage%)', style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Ballots Cast: $totalVotes', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                  if (poll.isPrivate)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        'Code: ${poll.accessCode ?? "N/A"}',
                        style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pollProvider = Provider.of<PollProvider>(context);
    
    // LIVE FILTERING LOGIC: This guarantees the tabs are 100% accurate based on the exact current time
    final now = DateTime.now();
    final allPolls = pollProvider.polls;
    
    final currentPolls = allPolls.where((p) => p.startDate.isBefore(now) && p.endDate.isAfter(now)).toList();
    final upcomingPolls = allPolls.where((p) => p.startDate.isAfter(now)).toList();
    final expiredPolls = allPolls.where((p) => p.endDate.isBefore(now) || p.endDate.isAtSameMomentAs(now)).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Manage Polls', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Current'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Expired'),
          ],
        ),
      ),
      body: pollProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPollList(allPolls),
                _buildPollList(currentPolls),
                _buildPollList(upcomingPolls),
                _buildPollList(expiredPolls),
              ],
            ),
    );
  }

  Widget _buildPollList(List<PollModel> polls) {
    if (polls.isEmpty) return const Center(child: Text('No polls found.', style: TextStyle(color: AppColors.textSecondary)));

    final now = DateTime.now();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: polls.length,
      itemBuilder: (context, index) {
        final poll = polls[index];
        final dateFormat = DateFormat('MMM dd, yyyy');
        final candidates = Provider.of<PollProvider>(context).getCandidatesForPoll(poll.id);

        // Determine Poll Status for the Badge
        String statusText;
        Color statusColor;
        Color statusBgColor;

        if (poll.startDate.isAfter(now)) {
          statusText = 'UPCOMING';
          statusColor = Colors.blue.shade700;
          statusBgColor = Colors.blue.shade50;
        } else if (poll.endDate.isBefore(now) || poll.endDate.isAtSameMomentAs(now)) {
          statusText = 'EXPIRED';
          statusColor = Colors.red.shade700;
          statusBgColor = Colors.red.shade50;
        } else {
          statusText = 'ACTIVE';
          statusColor = Colors.green.shade700;
          statusBgColor = Colors.green.shade50;
        }

        return GestureDetector(
          onTap: () => _showResultsDialog(poll),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(poll.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    
                    // NEW: Dynamic Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(poll.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                
                // Show Private Access Code if it exists
                if (poll.isPrivate) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.lock, size: 14, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        'Code: ${poll.accessCode ?? "N/A"}',
                        style: TextStyle(color: Colors.orange.shade900, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('${dateFormat.format(poll.startDate)} - ${dateFormat.format(poll.endDate)}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.people_outline, size: 16, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text('${candidates.length} candidates', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _deletePoll(poll.id),
                    )
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}