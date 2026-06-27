import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserModel {
  final String id;
  final String fullName; 
  final String email;
  final String role;
  final String status;
  final bool faceRegistered;
  final List<double>? faceEmbedding; // <-- ADDED THIS

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.status,
    required this.faceRegistered,
    this.faceEmbedding, // <-- ADDED THIS
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullName: json['display_name'] ?? 'Unknown User', 
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      status: json['status'] ?? 'pending',
      faceRegistered: json['face_registered'] ?? false,
      // <-- ADDED PARSER FOR FACE DATA
      faceEmbedding: json['face_embedding'] != null 
          ? List<double>.from(json['face_embedding'] as List<dynamic>) 
          : null,
    );
  }
}

class AuthStateProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  UserModel? _currentUser;
  bool _isLoading = true;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  AuthStateProvider() {
    _initializeAuthListener();
  }

  void _initializeAuthListener() {
    _supabase.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.initialSession) {
        if (session != null) {
          await _fetchUserProfile(session.user.id);
        } else {
          _currentUser = null;
          _isLoading = false;
          notifyListeners();
        }
      } else if (event == AuthChangeEvent.signedOut) {
        _currentUser = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> _fetchUserProfile(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        _currentUser = UserModel.fromJson(response);
      } else {
        // Fallback user if database trigger is slightly delayed
        _currentUser = UserModel(
          id: userId,
          fullName: _supabase.auth.currentUser?.userMetadata?['full_name'] ?? 'Unknown User',
          email: _supabase.auth.currentUser?.email ?? '',
          role: 'user',
          status: 'pending',
          faceRegistered: false,
        );
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _supabase.auth.signInWithPassword(email: email, password: password);

      if (response.session != null) {
        await _fetchUserProfile(response.session!.user.id);
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signUp(String email, String password, String fullName) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      if (response.session != null) {
        await Future.delayed(const Duration(seconds: 1));
        await _fetchUserProfile(response.session!.user.id);
      } else {
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();
      await _supabase.auth.signOut();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }
}