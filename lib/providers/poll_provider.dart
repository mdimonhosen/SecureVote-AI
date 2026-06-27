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
  bool _isListeningToRealtime = false;

  List<PollModel> get polls => _polls;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<PollModel> get currentPolls => _polls.where((p) => p.currentStatus == 'Current').toList();
  List<PollModel> get upcomingPolls => _polls.where((p) => p.currentStatus == 'Upcoming').toList();
  List<PollModel> get expiredPolls => _polls.where((p) => p.currentStatus == 'Expired').toList();

  List<CandidateModel> getCandidatesForPoll(String pollId) {
    return _pollCandidates[pollId] ?? [];
  }

  // ADDITION 11.3: SUPABASE REALTIME WEB-SOCKETS
  void initializeRealtimeListeners() {
    if (_isListeningToRealtime) return;
    _isListeningToRealtime = true;

    // Listen to the 'votes' table for live result counting!
    _client.channel('public:votes').onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'votes',
      callback: (payload) {
        debugPrint('Live vote detected! Updating UI...');
        fetchAllPolls(isSilentRefresh: true);
      },
    ).subscribe();

    // Listen to the 'polls' table for newly created/edited polls
    _client.channel('public:polls').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'polls',
      callback: (payload) {
        debugPrint('Poll update detected! Updating UI...');
        fetchAllPolls(isSilentRefresh: true);
      },
    ).subscribe();
  }

  // Modified to support "Silent Refreshes" so the screen doesn't flicker during live updates
  Future<void> fetchAllPolls({bool isSilentRefresh = false}) async {
    if (!isSilentRefresh) {
      _isLoading = true;
      notifyListeners();
    }
    _errorMessage = null;

    try {
      _polls = await _supabaseService.getPolls();
      
      for (var poll in _polls) {
        final candidateData = await _client.from('candidates').select().eq('poll_id', poll.id);
        _pollCandidates[poll.id] = (candidateData as List).map((map) => CandidateModel.fromMap(map)).toList();
      }
      
      // Ensure listeners are active
      initializeRealtimeListeners();
      
    } catch (e) {
      _errorMessage = "Failed to load voting dashboard records.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> voteForCandidate(String pollId, String candidateId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _supabaseService.castVote(pollId: pollId, candidateId: candidateId);
      // We don't need to manually call fetchAllPolls() here anymore! 
      // The Supabase Realtime listener will automatically detect the insert and refresh!
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