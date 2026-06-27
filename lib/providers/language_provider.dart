import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('en'); // Default to English
  bool _isLoading = true;

  Locale get currentLocale => _currentLocale;
  bool get isBengali => _currentLocale.languageCode == 'bn';

  LanguageProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('language_code') ?? 'en';
    _currentLocale = Locale(langCode);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    final newLang = isBengali ? 'en' : 'bn';
    _currentLocale = Locale(newLang);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', newLang);
    notifyListeners();
  }

  // The Translation Function
  String t(String key) {
    if (_isLoading) return ''; // Prevents flickering on boot
    return _dictionary[_currentLocale.languageCode]?[key] ?? key;
  }

  // ==========================================
  // APP DICTIONARY (English & Bangla)
  // ==========================================
  static const Map<String, Map<String, String>> _dictionary = {
    'en': {
      'voter_portal': 'Voter Portal',
      'hello': 'Hello',
      'review_ballots': 'Review operational ballots or monitor live status checks below.',
      'all': 'All',
      'current': 'Current',
      'upcoming': 'Upcoming',
      'expired': 'Expired',
      'winners': 'Winners',
      'cast_vote': 'Cast Vote / Live Status',
      'view_results': 'View Final Results',
      'declared_winner': 'Declared Winner',
      'nominated_candidates': 'Nominated Candidates',
      'no_polls': 'No updates available here.',
      'private_poll': 'PRIVATE POLL',
      'public_poll': 'PUBLIC POLL',
      'votes_received': 'Votes Received',
      'terminus': 'Terminus:',
      'logout': 'Secure Logout',
      'profile': 'Voter Profile',
      'reg_details': 'Registration Details',
      'email_addr': 'Email Address',
      'role': 'Role',
      'biometric_status': 'Biometric Status',
      'face_active': 'Face ID Registered & Active',
      'face_missing': 'Face ID Not Registered',
      'change_lang': 'Switch to Bangla',
    },
    'bn': {
      'voter_portal': 'ভোটার পোর্টাল',
      'hello': 'হ্যালো',
      'review_ballots': 'নীচে আপনার সক্রিয় ব্যালট পর্যালোচনা করুন বা লাইভ স্ট্যাটাস দেখুন।',
      'all': 'সব',
      'current': 'বর্তমান',
      'upcoming': 'আসন্ন',
      'expired': 'মেয়াদোত্তীর্ণ',
      'winners': 'বিজয়ী',
      'cast_vote': 'ভোট দিন / লাইভ স্ট্যাটাস',
      'view_results': 'চূড়ান্ত ফলাফল দেখুন',
      'declared_winner': 'ঘোষিত বিজয়ী',
      'nominated_candidates': 'মনোনীত প্রার্থী',
      'no_polls': 'এখানে কোনো আপডেট নেই।',
      'private_poll': 'প্রাইভেট পোল',
      'public_poll': 'পাবলিক পোল',
      'votes_received': 'ভোট পেয়েছেন',
      'terminus': 'শেষ সময়:',
      'logout': 'নিরাপদ লগআউট',
      'profile': 'ভোটার প্রোফাইল',
      'reg_details': 'নিবন্ধন বিবরণ',
      'email_addr': 'ইমেইল ঠিকানা',
      'role': 'ভূমিকা',
      'biometric_status': 'বায়োমেট্রিক স্ট্যাটাস',
      'face_active': 'ফেস আইডি নিবন্ধিত এবং সক্রিয়',
      'face_missing': 'ফেস আইডি নিবন্ধিত নয়',
      'change_lang': 'Switch to English',
    }
  };
}