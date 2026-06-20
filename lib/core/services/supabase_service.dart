import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_model.dart';
import '../../models/poll_model.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // ==========================================
  // AUTHENTICATION
  // ==========================================

  // Get current session user ID
  String? get currentUserId => _client.auth.currentUser?.id;

  // Register a new user
  Future<AuthResponse> registerUser({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'role': 'user',
        'status': 'pending', // Starts as pending admin approval 
        'face_registered': false,
      },
    );
  }

  // Normal Email/Password Login
  Future<AuthResponse> loginWithEmail(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Logout
  Future<void> logout() async {
    await _client.auth.signOut();
  }

  // Fetch current user's database profile 
  Future<UserModel?> getUserProfile(String uid) async {
    final response = await _client
        .from('users')
        .select()
        .eq('id', uid)
        .maybeSingle();
    
    if (response == null) return null;
    return UserModel.fromMap(response);
  }

  // ==========================================
  // POLLS & VOTING
  // ==========================================

  // Fetch all polls 
  Future<List<PollModel>> getPolls() async {
    final response = await _client
        .from('polls')
        .select()
        .order('start_date', ascending: false);
    
    return (response as List).map((map) => PollModel.fromMap(map)).toList();
  }

  // Cast a vote
  Future<void> castVote({
    required String pollId,
    required String candidateId,
  }) async {
    final uid = currentUserId;
    if (uid == null) throw Exception('User not logged in');

    // Because we set up a UNIQUE(poll_id, voter_id) constraint in PostgreSQL,
    // and an AFTER INSERT trigger to update the candidate count, 
    // this single insert handles duplicate-prevention AND counting securely! 
    await _client.from('votes').insert({
      'poll_id': pollId,
      'voter_id': uid,
      'candidate_id': candidateId,
    });
  }

  // Utility: Hash Access Code for Private Polls 
  String hashAccessCode(String rawCode) {
    var bytes = utf8.encode(rawCode);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }
}