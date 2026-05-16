import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  Map<String, dynamic>? _profile;
  bool _isLoadingProfile = false;
  int _profileLoadRetries = 0;
  static const int _maxRetries = 2;

  User? get user => _user;
  Map<String, dynamic>? get profile => _profile;
  bool get isLoadingProfile => _isLoadingProfile;

  AuthProvider() {
    _init();
  }

  void _init() {
    _user = Supabase.instance.client.auth.currentUser;
    if (_user != null) {
      _loadProfile();
    }
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      _user = event.session?.user;
      _profileLoadRetries = 0;
      if (_user != null) {
        _loadProfile();
      } else {
        _profile = null;
        _isLoadingProfile = false;
        notifyListeners();
      }
    });
  }

  Future<void> _loadProfile() async {
    if (_user == null) return;
    _isLoadingProfile = true;
    notifyListeners();
    
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', _user!.id)
          .maybeSingle();
      
      if (response != null) {
        _profile = response;
        _isLoadingProfile = false;
        _profileLoadRetries = 0;
        notifyListeners();
      } else {
        await _createProfile();
      }
    } catch (e) {
      print('Error loading profile (attempt ${_profileLoadRetries + 1}): $e');
      _isLoadingProfile = false;
      
      if (_profileLoadRetries < _maxRetries) {
        _profileLoadRetries++;
        await Future.delayed(const Duration(milliseconds: 500));
        await _loadProfile();
      } else {
        notifyListeners();
      }
    }
  }

  Future<void> _createProfile() async {
    if (_user == null) return;
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .insert({
            'id': _user!.id,
            'name': _user!.userMetadata?['name'] ?? _user!.email?.split('@').first ?? 'User',
            'email': _user!.email,
            'approved': false,
            'is_admin': false,
          })
          .select()
          .single();
      _profile = response;
      _isLoadingProfile = false;
      _profileLoadRetries = 0;
      notifyListeners();
    } catch (e) {
      print('Error creating profile: $e');
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
      _user = response.user;
      if (_user != null) {
        await _loadProfile();
      }
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _user = response.user;
      if (_user != null) {
        await _loadProfile();
      }
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    _user = null;
    _profile = null;
    _isLoadingProfile = false;
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    if (_user == null) return;
    try {
      await Supabase.instance.client
          .from('profiles')
          .update(updates)
          .eq('id', _user!.id);
      await _loadProfile();
    } catch (e) {
      rethrow;
    }
  }
}