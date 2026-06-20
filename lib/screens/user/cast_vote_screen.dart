import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/services/supabase_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/poll_provider.dart';
import '../../models/poll_model.dart';

class CastVoteScreen extends StatefulWidget {
  final PollModel poll;
  const CastVoteScreen({super.key, required this.poll});

  @override
  State<CastVoteScreen> createState() => _CastVoteScreenState();
}

class _CastVoteScreenState extends State<CastVoteScreen> {
  bool _isAccessCodeVerified = false;
  final _accessCodeController = TextEditingController();
  String? _selectedCandidateId;
  bool _isVoting = false;

  @override
  void initState() {
    super.initState();
    // Public polls bypass the PIN screen automatically
    if (!widget.poll.isPrivate) {
      _isAccessCodeVerified = true;
    }
  }

  void _verifyAccessCode() {
    final inputHash = SupabaseService().hashAccessCode(_accessCodeController.text.trim());
    if (inputHash == widget.poll.accessCodeHash) {
      setState(() => _isAccessCodeVerified = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Access Code', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.error));
    }
  }

  void _handleVote() async {
    if (_selectedCandidateId == null) return;
    
    // In production, insert biometric FaceService live check here!
    // bool faceMatched = await Navigator.push(context, MaterialPageRoute(builder: (_) => FaceVerifyScreen()));
    // if (!faceMatched) return;

    setState(() => _isVoting = true);
    final success = await Provider.of<PollProvider>(context, listen: false).voteForCandidate(widget.poll.id, _selectedCandidateId!);
    
    if (mounted) {
      setState(() => _isVoting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vote cast successfully!')));
        Navigator.pop(context); // Return home after voting
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You have already voted or an error occurred.'), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  void dispose() {
    _accessCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: const Text('Cast Vote', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poll Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(widget.poll.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20))),
                      if (widget.poll.isPrivate) const Icon(Icons.lock, color: AppColors.textPrimary),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(widget.poll.description, style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text('Ends: ${dateFormat.format(widget.poll.endDate)}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Conditional State: Access Code Check vs Voting Form
            if (!_isAccessCodeVerified) ...[
              const Text('This is a private poll. Enter the access code to continue.', style: TextStyle(fontSize: 16)),
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

  Widget _buildCandidateSelection() {
    final candidates = Provider.of<PollProvider>(context, listen: false).getCandidatesForPoll(widget.poll.id);
    final user = Provider.of<AuthStateProvider>(context, listen: false).currentUser;
    final canVote = user?.faceRegistered ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select a candidate:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...candidates.map((candidate) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: _selectedCandidateId == candidate.id ? AppColors.primaryLight : Colors.white,
              border: Border.all(color: _selectedCandidateId == candidate.id ? AppColors.primary : Colors.black12, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: RadioListTile<String>(
              value: candidate.id,
              // ignore: deprecated_member_use
              groupValue: _selectedCandidateId,
              activeColor: AppColors.primary,
              title: Text(candidate.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: candidate.description != null && candidate.description!.isNotEmpty ? Text(candidate.description!) : null,
              // ignore: deprecated_member_use
              onChanged: (val) => setState(() => _selectedCandidateId = val),
            ),
          );
        }),
        const SizedBox(height: 24),
        if (!canVote)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.pendingBackground, borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.error),
                SizedBox(width: 12),
                Expanded(child: Text('Face registration required. Register your face in Profile settings.', style: TextStyle(color: AppColors.error, fontSize: 13))),
              ],
            ),
          ),
        const SizedBox(height: 16),
        CustomButton(
          text: 'Verify & Cast Vote',
          icon: Icons.face,
          isLoading: _isVoting,
          onPressed: (canVote && _selectedCandidateId != null) ? _handleVote : null,
        ),
      ],
    );
  }
}