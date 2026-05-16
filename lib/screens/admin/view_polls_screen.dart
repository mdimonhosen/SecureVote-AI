import 'package:flutter/material.dart';
import '../../models/poll_model.dart';
import '../../models/candidate_model.dart';
import '../../services/supabase_service.dart';

class ViewPollsScreen extends StatefulWidget {
  const ViewPollsScreen({super.key});

  @override
  State<ViewPollsScreen> createState() => _ViewPollsScreenState();
}

class _ViewPollsScreenState extends State<ViewPollsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseService _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Polls'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Current'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Expired'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPollsTab('current'),
          _buildPollsTab('upcoming'),
          _buildPollsTab('expired'),
        ],
      ),
    );
  }

  Widget _buildPollsTab(String type) {
    return FutureBuilder<List<PollModel>>(
      future: _getPollsByType(type),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final polls = snapshot.data ?? [];

        if (polls.isEmpty) {
          return Center(child: Text('No $type polls'));
        }

        return ListView.builder(
          itemCount: polls.length,
          itemBuilder: (context, index) {
            final poll = polls[index];
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ExpansionTile(
                title: Text(poll.title),
                subtitle: Text('${poll.candidates.length} candidates'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Description: ${poll.description ?? 'N/A'}'),
                        Text('Start: ${poll.startDate}'),
                        Text('End: ${poll.endDate}'),
                        const SizedBox(height: 8),
                        const Text('Candidates:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ...poll.candidates.map((candidate) => Text('- ${candidate.name}')),
                        const SizedBox(height: 8),
                        if (type == 'expired')
                          ElevatedButton(
                            onPressed: () => _showResults(poll),
                            child: const Text('View Results'),
                          ),
                        ElevatedButton(
                          onPressed: () => _showVoters(poll),
                          child: const Text('View Voters'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<List<PollModel>> _getPollsByType(String type) {
    switch (type) {
      case 'current':
        return _supabaseService.getActivePolls();
      case 'upcoming':
        return _supabaseService.getUpcomingPolls();
      case 'expired':
        return _supabaseService.getExpiredPolls();
      default:
        return Future.value([]);
    }
  }

  void _showResults(PollModel poll) async {
    try {
      final results = await _supabaseService.getPollResults(poll.id);
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Results for ${poll.title}'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: results.entries.map((entry) {
                final candidate = poll.candidates.firstWhere(
                  (c) => c.id == entry.key,
                  orElse: () => CandidateModel(id: '', name: 'Unknown', pollId: poll.id),
                );
                return ListTile(
                  title: Text(candidate.name),
                  trailing: Text('${entry.value} votes'),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading results: $e')),
      );
    }
  }

  void _showVoters(PollModel poll) async {
    try {
      final voters = await _supabaseService.getPollVoters(poll.id);
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Voters for ${poll.title}'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: voters.map((vote) {
                final voter = vote['profiles'] as Map<String, dynamic>?;
                final candidate = vote['candidates'] as Map<String, dynamic>?;
                return ListTile(
                  title: Text(voter?['name'] ?? 'Unknown'),
                  subtitle: Text('Voted for: ${candidate?['name'] ?? 'Unknown'}'),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading voters: $e')),
      );
    }
  }
}