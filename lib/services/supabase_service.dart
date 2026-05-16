import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../models/poll_model.dart';
import '../models/candidate_model.dart';
import '../models/vote_model.dart';

class SupabaseService {
  final SupabaseClient client = Supabase.instance.client;

  // User operations
  Future<UserModel?> getCurrentUserProfile() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    final response = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return UserModel.fromJson(response);
  }

  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await client
        .from('profiles')
        .update(updates)
        .eq('id', user.id);
  }

  Future<List<UserModel>> getPendingUsers() async {
    final response = await client
        .from('profiles')
        .select()
        .eq('approved', false)
        .order('created_at');

    return response.map((json) => UserModel.fromJson(json)).toList();
  }

  Future<List<UserModel>> getAllUsers() async {
    final response = await client
        .from('profiles')
        .select()
        .order('created_at');

    return response.map((json) => UserModel.fromJson(json)).toList();
  }

  Future<void> approveUser(String userId, bool approved) async {
    await client
        .from('profiles')
        .update({'approved': approved})
        .eq('id', userId);
  }

  Future<void> setUserAsAdmin(String userId, bool isAdmin) async {
    await client
        .from('profiles')
        .update({'is_admin': isAdmin})
        .eq('id', userId);
  }

  Future<void> setUserAsAdminByEmail(String email, bool isAdmin) async {
    await client
        .from('profiles')
        .update({'is_admin': isAdmin})
        .eq('email', email);
  }

  // Poll operations
  Future<List<PollModel>> getActivePolls() async {
    final now = DateTime.now().toIso8601String();
    final response = await client
        .from('polls')
        .select('*, candidates(*)')
        .lte('start_date', now)
        .gte('end_date', now)
        .order('start_date');

    return response.map((json) => PollModel.fromJson(json)).toList();
  }

  Future<List<PollModel>> getUpcomingPolls() async {
    final now = DateTime.now().toIso8601String();
    final response = await client
        .from('polls')
        .select('*, candidates(*)')
        .gt('start_date', now)
        .order('start_date');

    return response.map((json) => PollModel.fromJson(json)).toList();
  }

  Future<List<PollModel>> getExpiredPolls() async {
    final now = DateTime.now().toIso8601String();
    final response = await client
        .from('polls')
        .select('*, candidates(*)')
        .lt('end_date', now)
        .order('end_date', ascending: false);

    return response.map((json) => PollModel.fromJson(json)).toList();
  }

  Future<PollModel> createPoll(PollModel poll) async {
    final response = await client
        .from('polls')
        .insert(poll.toJson())
        .select()
        .single();

    return PollModel.fromJson(response);
  }

  Future<void> updatePoll(String pollId, Map<String, dynamic> updates) async {
    await client
        .from('polls')
        .update(updates)
        .eq('id', pollId);
  }

  Future<void> deletePoll(String pollId) async {
    await client
        .from('polls')
        .delete()
        .eq('id', pollId);
  }

  // Candidate operations
  Future<void> addCandidate(CandidateModel candidate) async {
    await client
        .from('candidates')
        .insert(candidate.toJson());
  }

  Future<void> updateCandidate(String candidateId, Map<String, dynamic> updates) async {
    await client
        .from('candidates')
        .update(updates)
        .eq('id', candidateId);
  }

  Future<void> deleteCandidate(String candidateId) async {
    await client
        .from('candidates')
        .delete()
        .eq('id', candidateId);
  }

  // Vote operations
  Future<bool> hasUserVoted(String pollId, String userId) async {
    final response = await client
        .from('votes')
        .select()
        .eq('poll_id', pollId)
        .eq('user_id', userId)
        .limit(1);

    return response.isNotEmpty;
  }

  Future<VoteModel?> getUserVote(String pollId, String userId) async {
    final response = await client
        .from('votes')
        .select()
        .eq('poll_id', pollId)
        .eq('user_id', userId)
        .single();

    return VoteModel.fromJson(response);
  }

  Future<void> castVote(VoteModel vote) async {
    await client
        .from('votes')
        .insert(vote.toJson());
  }

  Future<Map<String, int>> getPollResults(String pollId) async {
    final response = await client
        .from('votes')
        .select('candidate_id')
        .eq('poll_id', pollId);

    final results = <String, int>{};
    for (final vote in response) {
      final candidateId = vote['candidate_id'] as String;
      results[candidateId] = (results[candidateId] ?? 0) + 1;
    }

    return results;
  }

  Future<List<Map<String, dynamic>>> getPollVoters(String pollId) async {
    final response = await client
        .from('votes')
        .select('*, profiles(name, email), candidates(name)')
        .eq('poll_id', pollId);

    return response;
  }

  // Private poll operations
  Future<bool> canAccessPrivatePoll(String pollId, String userId, String code) async {
    final pollResponse = await client
        .from('polls')
        .select('security_code')
        .eq('id', pollId)
        .single();

    if (pollResponse['security_code'] != code) return false;

    final invitedResponse = await client
        .from('invited_users')
        .select()
        .eq('poll_id', pollId)
        .eq('user_id', userId)
        .limit(1);

    return invitedResponse.isNotEmpty;
  }

  Future<void> inviteUserToPoll(String pollId, String userId) async {
    await client
        .from('invited_users')
        .insert({
          'poll_id': pollId,
          'user_id': userId,
        });
  }
}