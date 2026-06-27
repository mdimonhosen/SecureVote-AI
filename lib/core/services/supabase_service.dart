import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_model.dart';
import '../../models/poll_model.dart';
import 'package:flutter/foundation.dart'; // FIX: Added for debugPrint

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // ==========================================
  // AUTHENTICATION
  // ==========================================

  String? get currentUserId => _client.auth.currentUser?.id;

  // UPDATED: Now accepts faceEmbedding for registration
  Future<AuthResponse> registerUser({
    required String email,
    required String password,
    required String fullName,
    List<double>? faceEmbedding, 
  }) async {
    // 1. Create the Auth User
    final authResponse = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
      },
    );

    // 2. Insert user profile into 'users' table
    if (authResponse.user != null) {
      await _client.from('users').insert({
        'id': authResponse.user!.id,
        'email': email,
        'name': fullName,
        'role': 'user',
        'status': 'pending', 
        'face_registered': faceEmbedding != null,
        'face_embedding': faceEmbedding, // Now saved to DB
      });
    }
    
    return authResponse;
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

  // ==========================================
  // AUDIT LOGGING
  // ==========================================
  Future<void> logAdminAction(String actionType, String description) async {
    final uid = currentUserId;
    if (uid == null) return;
    try {
      await _client.from('audit_logs').insert({
        'admin_id': uid,
        'action_type': actionType,
        'description': description,
      });
    } catch (e) {
      debugPrint('Audit Log Error: $e');
    }
  }
}