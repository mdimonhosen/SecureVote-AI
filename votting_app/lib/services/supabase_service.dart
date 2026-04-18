import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  static Future<void> init() async {
    await Supabase.initialize(
      url: 'https://zyrjkmprgfhkdoqpgkxb.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp5cmprbXByZ2Zoa2RvcXBna3hiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYxMjk0MTgsImV4cCI6MjA5MTcwNTQxOH0.H18c3wj-4HxevI9zMzeB8qzqYi2I7aBNm82OQXiMyDU',
    );
  }

  // Voter operations
  Future<Map<String, dynamic>?> getVoter(String voterId) async {
    final response = await client
        .from('voters')
        .select()
        .eq('voter_id', voterId)
        .maybeSingle();
    return response;
  }

  Future<void> registerVoterFace(String voterId, List<double> embedding) async {
    await client.from('voters').update({
      'face_embedding': embedding,
      'face_registered': true,
    }).eq('voter_id', voterId);
  }

  Future<void> markVoted(String voterId) async {
    await client.from('voters').update({'has_voted': true}).eq('voter_id', voterId);
  }

  // Election operations
  Future<List<Map<String, dynamic>>> getActiveElections() async {
    final response = await client
        .from('elections')
        .select()
        .eq('is_active', true);
    return List<Map<String, dynamic>>.from(response);
  }

  // Candidate operations
  Future<List<Map<String, dynamic>>> getCandidates(String electionId) async {
    final response = await client
        .from('candidates')
        .select()
        .eq('election_id', electionId);
    return List<Map<String, dynamic>>.from(response);
  }

  // Voting
  Future<void> submitVote(String voterId, String candidateId, String electionId) async {
    await client.from('votes').insert({
      'voter_id': voterId,
      'candidate_id': candidateId,
      'election_id': electionId,
    });
    await markVoted(voterId);
  }

  // Results
  Future<List<Map<String, dynamic>>> getResults(String electionId) async {
    // This is a simple aggregate, in production you might use a RPC or View
    final response = await client
        .from('votes')
        .select('candidate_id, candidates(name)')
        .eq('election_id', electionId);
    
    // Process results into counts
    Map<String, int> counts = {};
    Map<String, String> names = {};
    for (var vote in response) {
      String id = vote['candidate_id'];
      counts[id] = (counts[id] ?? 0) + 1;
      names[id] = vote['candidates']['name'];
    }

    return counts.entries.map((e) => {
      'id': e.key,
      'name': names[e.key],
      'votes': e.value,
    }).toList();
  }
}
