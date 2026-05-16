import 'package:flutter/material.dart';
import '../../models/poll_model.dart';
import '../../models/candidate_model.dart';
import '../../services/supabase_service.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final SupabaseService _supabaseService = SupabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Poll Results')),
      body: FutureBuilder<List<PollModel>>(
        future: _supabaseService.getExpiredPolls(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final polls = snapshot.data ?? [];

          if (polls.isEmpty) {
            return const Center(child: Text('No completed polls'));
          }

          return ListView.builder(
            itemCount: polls.length,
            itemBuilder: (context, index) {
              final poll = polls[index];
              return FutureBuilder<Map<String, int>>(
                future: _supabaseService.getPollResults(poll.id),
                builder: (context, resultsSnapshot) {
                  if (resultsSnapshot.connectionState == ConnectionState.waiting) {
                    return const Card(
                      margin: EdgeInsets.all(8.0),
                      child: ListTile(
                        title: Text('Loading...'),
                      ),
                    );
                  }

                  final results = resultsSnapshot.data ?? {};
                  final totalVotes = results.values.fold(0, (sum, votes) => sum + votes);

                  // Find winner
                  String winner = 'No votes yet';
                  int maxVotes = 0;
                  results.forEach((candidateId, votes) {
                    if (votes > maxVotes) {
                      maxVotes = votes;
                      final candidate = poll.candidates.firstWhere(
                        (c) => c.id == candidateId,
                        orElse: () => CandidateModel(id: '', name: 'Unknown', pollId: poll.id),
                      );
                      winner = candidate.name;
                    }
                  });

                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: ExpansionTile(
                      title: Text(poll.title),
                      subtitle: Text('Winner: $winner ($maxVotes votes)'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Votes: $totalVotes'),
                              const SizedBox(height: 8),
                              ...results.entries.map((entry) {
                                final candidate = poll.candidates.firstWhere(
                                  (c) => c.id == entry.key,
                                  orElse: () => CandidateModel(id: '', name: 'Unknown', pollId: poll.id),
                                );
                                final percentage = totalVotes > 0 ? (entry.value / totalVotes * 100).round() : 0;
                                return Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: Text(candidate.name)),
                                        Text('${entry.value} votes ($percentage%)'),
                                      ],
                                    ),
                                    LinearProgressIndicator(
                                      value: totalVotes > 0 ? entry.value / totalVotes : 0,
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                );
                              }),
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
        },
      ),
    );
  }
}