import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/supabase_service.dart';
import '../models/poll_model.dart';
import '../models/candidate_model.dart';

class PollProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  final SupabaseClient _client = Supabase.instance.client;

  List<PollModel> _polls = [];
  final Map<String, List<CandidateModel>> _pollCandidates = {};
  bool _isLoading = false;
  String? _errorMessage;

  List<PollModel> get polls => _polls;
  bool get isLoading => _isLoading;
 String? get errorMessage => _errorMessage;

  // Filter lists based on lifecycle computed rules
  List<PollModel> get currentPolls => _polls.where((p) => p.currentStatus == 'Current').toList();
  List<PollModel> get upcomingPolls => _polls.where((p) => p.currentStatus == 'Upcoming').toList();
  List<PollModel> get expiredPolls => _polls.where((p) => p.currentStatus == 'Expired').toList();

  // Retrieve matching candidates for a chosen poll
  List<CandidateModel> getCandidatesForPoll(String pollId) {
    return _pollCandidates[pollId] ?? [];
  }

  // Load polls and candidates comprehensively from Supabase
  Future<void> fetchAllPolls() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _polls = await _supabaseService.getPolls();
      
      // Concurrently query candidates for all fetched polls
      for (var poll in _polls) {
        final candidateData = await _client
            .from('candidates')
            .select()
            .eq('poll_id', poll.id);
            
        _pollCandidates[poll.id] = (candidateData as List)
            .map((map) => CandidateModel.fromMap(map))
            .toList();
      }
    } catch (e) {
      _errorMessage = "Failed to load voting dashboard records.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Submit secure vote update transaction layer
  Future<bool> voteForCandidate(String pollId, String candidateId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _supabaseService.castVote(pollId: pollId, candidateId: candidateId);
      await fetchAllPolls(); // Refresh snapshot values live
      return true;
    } catch (e) {
      _errorMessage = "Voting transaction failed. Duplicate entries are blocked.";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}