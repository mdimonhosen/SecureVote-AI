import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/services/supabase_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/poll_provider.dart';
import '../../models/poll_model.dart';
import '../../models/candidate_model.dart';
import 'face_verify_screen.dart';

class CastVoteScreen extends StatefulWidget {
  final PollModel poll;
  const CastVoteScreen({super.key, required this.poll});

  @override
  State<CastVoteScreen> createState() => _CastVoteScreenState();
}

class _CastVoteScreenState extends State<CastVoteScreen> with SingleTickerProviderStateMixin {
  bool _isAccessCodeVerified = false;
  final _accessCodeController = TextEditingController();
  String? _selectedCandidateId;
  bool _isVoting = false;
  bool _isCheckingVoteStatus = true;
  bool _hasAlreadyVoted = false;
  String? _votedCandidateId;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    if (!widget.poll.isPrivate) _isAccessCodeVerified = true;
    _checkIfUserAlreadyVoted();
  }

  @override
  void dispose() {
    _animController.dispose();
    _accessCodeController.dispose();
    super.dispose();
  }

  Future<void> _checkIfUserAlreadyVoted() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final response = await Supabase.instance.client
          .from('votes')
          .select('id, candidate_id')
          .eq('poll_id', widget.poll.id)
          .eq('voter_id', userId)
          .maybeSingle();
      if (response != null && mounted) {
        setState(() {
          _hasAlreadyVoted = true;
          _votedCandidateId = response['candidate_id'] as String?;
        });
      }
    } catch (e) {
      debugPrint('Error checking vote status: $e');
    } finally {
      if (mounted) {
        setState(() => _isCheckingVoteStatus = false);
        _animController.forward();
      }
    }
  }

  void _verifyAccessCode() {
    final inputText = _accessCodeController.text.trim();
    final inputHash = SupabaseService().hashAccessCode(inputText);
    if (inputHash == widget.poll.accessCodeHash || inputText == widget.poll.accessCodeHash) {
      setState(() => _isAccessCodeVerified = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Access Code'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _handleVote() async {
    if (_selectedCandidateId == null) return;

    final bool isVerified = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FaceVerifyScreen()),
    ) ?? false;

    if (!mounted) return;

    if (!isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Vote aborted: Biometric verification failed or was cancelled.'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    setState(() => _isVoting = true);
    final success = await Provider.of<PollProvider>(context, listen: false)
        .voteForCandidate(widget.poll.id, _selectedCandidateId!);

    if (!mounted) return;
    setState(() => _isVoting = false);

    if (success) {
      setState(() {
        _hasAlreadyVoted = true;
        _votedCandidateId = _selectedCandidateId;
      });
      _animController.forward(from: 0);

      final candidate = Provider.of<PollProvider>(context, listen: false)
          .getCandidatesForPoll(widget.poll.id)
          .firstWhere((c) => c.id == _selectedCandidateId);

      final token = SupabaseService()
          .hashAccessCode('${widget.poll.id}_${_selectedCandidateId}_${DateTime.now().toIso8601String()}')
          .substring(0, 12)
          .toUpperCase();

      _showVoteReceipt(candidate.name, token);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error processing vote.'), backgroundColor: AppColors.error),
      );
    }
  }

  void _showVoteReceipt(String candidateName, String token) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.verified_user, color: AppColors.success, size: 28),
            SizedBox(width: 8),
            Text('Vote Receipt', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your encrypted ballot has been securely recorded.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            _receiptRow('Poll:', widget.poll.title),
            _receiptRow('Voted for:', candidateName),
            _receiptRow('Time:', DateFormat('MMM dd, yyyy – hh:mm a').format(DateTime.now())),
            const Divider(height: 24),
            const Text('Cryptographic Token:', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(token,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 3, color: AppColors.primary)),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Acknowledge', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 80, child: Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy – hh:mm a');
    final isExpired = widget.poll.endDate.isBefore(DateTime.now());
    final showResults = _hasAlreadyVoted || isExpired;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          showResults ? 'Election Results' : 'Cast Your Vote',
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isCheckingVoteStatus
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poll info card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.heroGradient,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(widget.poll.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isExpired ? 'ENDED' : 'ACTIVE',
                                style: TextStyle(
                                  color: isExpired ? Colors.red.shade200 : Colors.greenAccent,
                                  fontWeight: FontWeight.bold, fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(widget.poll.description,
                            style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 14, color: Colors.white60),
                            const SizedBox(width: 6),
                            Text(
                              isExpired
                                  ? 'Ended: ${dateFormat.format(widget.poll.endDate)}'
                                  : 'Closes: ${dateFormat.format(widget.poll.endDate)}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Already voted banner
                  if (_hasAlreadyVoted && !isExpired)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: AppColors.success),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'You have cast your vote. Watch the live results below!',
                              style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Content
                  if (showResults)
                    _buildResultsView()
                  else if (!_isAccessCodeVerified) ...[
                    const Text('This is a private poll. Enter the access code to continue.',
                        style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    CustomTextField(
                      hintText: 'Access Code',
                      controller: _accessCodeController,
                      prefixIcon: Icons.password,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    CustomButton(text: 'Verify Access Code', onPressed: _verifyAccessCode),
                  ] else
                    _buildCandidateSelection(),
                ],
              ),
            ),
    );
  }

  Widget _buildResultsView() {
    final candidates = Provider.of<PollProvider>(context).getCandidatesForPoll(widget.poll.id);
    final totalVotes = candidates.fold(0, (sum, c) => sum + c.voteCount);
    final sorted = List<CandidateModel>.from(candidates)..sort((a, b) => b.voteCount.compareTo(a.voteCount));
    final isExpired = widget.poll.endDate.isBefore(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              isExpired ? 'Final Results' : 'Live Vote Tally',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const Spacer(),
            if (!isExpired)
              Row(children: const [
                Icon(Icons.circle, size: 8, color: Colors.green),
                SizedBox(width: 4),
                Text('Live', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 12)),
              ]),
          ],
        ),
        const SizedBox(height: 4),
        Text('$totalVotes total votes cast',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        ...sorted.asMap().entries.map((entry) {
          final rank = entry.key;
          final c = entry.value;
          final pct = totalVotes == 0 ? 0.0 : c.voteCount / totalVotes;
          final isWinner = rank == 0 && totalVotes > 0;
          final isMyVote = c.id == _votedCandidateId;

          return AnimatedBuilder(
            animation: _animController,
            builder: (context, _) {
              final animatedPct = _animController.value * pct;
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isWinner
                        ? AppColors.gold.withValues(alpha: 0.5)
                        : isMyVote
                            ? AppColors.primary.withValues(alpha: 0.4)
                            : Colors.grey.shade200,
                    width: isWinner || isMyVote ? 1.5 : 1,
                  ),
                  boxShadow: [
                    if (isWinner)
                      BoxShadow(color: AppColors.gold.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Rank badge
                        Container(
                          width: 28, height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isWinner ? AppColors.gold : AppColors.primaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: isWinner
                              ? const Icon(Icons.emoji_events_rounded, size: 16, color: Colors.white)
                              : Text('${rank + 1}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
                        ),
                        const SizedBox(width: 12),
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.primaryLight,
                          backgroundImage: c.imageUrl != null ? NetworkImage(c.imageUrl!) : null,
                          child: c.imageUrl == null ? const Icon(Icons.person, color: AppColors.primary) : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(c.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: isWinner ? AppColors.gold : AppColors.textPrimary,
                                        )),
                                  ),
                                  if (isMyVote)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('Your Vote',
                                          style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                              if (c.description != null)
                                Text(c.description!,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${c.voteCount}',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18,
                                    color: isWinner ? AppColors.gold : AppColors.textPrimary)),
                            Text('${(pct * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: animatedPct,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: AlwaysStoppedAnimation(isWinner ? AppColors.gold : AppColors.primary),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ],
    );
  }

  Widget _buildCandidateSelection() {
    final candidates = Provider.of<PollProvider>(context).getCandidatesForPoll(widget.poll.id);
    final user = Provider.of<AuthStateProvider>(context, listen: false).currentUser;

    if (user?.role == 'admin' || user?.role == 'system_admin') {
      return _infoBox(Icons.gavel, 'Admin Voting Restricted',
          'Administrators are not permitted to cast ballots to maintain election integrity.',
          color: AppColors.error);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select a candidate to cast your ballot:',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        ...candidates.map((c) {
          final isSelected = _selectedCandidateId == c.id;
          return GestureDetector(
            onTap: () => setState(() => _selectedCandidateId = c.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryLight : Colors.white,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: isSelected
                    ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 3))]
                    : [],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryLight,
                    backgroundImage: c.imageUrl != null ? NetworkImage(c.imageUrl!) : null,
                    child: c.imageUrl == null ? const Icon(Icons.person, color: AppColors.primary) : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        if (c.description != null)
                          Text(c.description!,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade400, width: 2),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : null,
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
        CustomButton(
          text: 'Verify Identity & Cast Vote',
          icon: Icons.how_to_vote,
          isLoading: _isVoting,
          onPressed: _selectedCandidateId != null ? _handleVote : null,
        ),
      ],
    );
  }

  Widget _infoBox(IconData icon, String title, String subtitle, {required Color color}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 48),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 13)),
        ],
      ),
    );
  }
}
