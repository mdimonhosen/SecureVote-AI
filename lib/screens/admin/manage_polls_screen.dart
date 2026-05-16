import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/poll_model.dart';
import '../../models/candidate_model.dart';
import '../../services/supabase_service.dart';

class ManagePollsScreen extends StatefulWidget {
  const ManagePollsScreen({super.key});

  @override
  State<ManagePollsScreen> createState() => _ManagePollsScreenState();
}

class _ManagePollsScreenState extends State<ManagePollsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<PollModel> _polls = [];

  @override
  void initState() {
    super.initState();
    _loadPolls();
  }

  Future<void> _loadPolls() async {
    try {
      final active = await _supabaseService.getActivePolls();
      final upcoming = await _supabaseService.getUpcomingPolls();
      final expired = await _supabaseService.getExpiredPolls();
      setState(() {
        _polls = [...active, ...upcoming, ...expired];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading polls: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Polls'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreatePollDialog,
          ),
        ],
      ),
      body: _polls.isEmpty
          ? const Center(child: Text('No polls found'))
          : ListView.builder(
              itemCount: _polls.length,
              itemBuilder: (context, index) {
                final poll = _polls[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(poll.title),
                    subtitle: Text(
                      '${DateFormat.yMd().format(poll.startDate)} - ${DateFormat.yMd().format(poll.endDate)}\n'
                      '${poll.isPrivate ? 'Private' : 'Public'} - ${poll.candidates.length} candidates',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) => _handlePollAction(value, poll),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                        const PopupMenuItem(value: 'add_candidate', child: Text('Add Candidate')),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _handlePollAction(String action, PollModel poll) {
    switch (action) {
      case 'edit':
        _showEditPollDialog(poll);
        break;
      case 'delete':
        _deletePoll(poll.id);
        break;
      case 'add_candidate':
        _showAddCandidateDialog(poll.id);
        break;
    }
  }

  void _showCreatePollDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;
    bool isPrivate = false;
    String? securityCode;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Poll'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => startDate = picked);
                          }
                        },
                        child: Text(startDate == null
                            ? 'Start Date'
                            : DateFormat.yMd().format(startDate!)),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate ?? DateTime.now(),
                            firstDate: startDate ?? DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => endDate = picked);
                          }
                        },
                        child: Text(endDate == null
                            ? 'End Date'
                            : DateFormat.yMd().format(endDate!)),
                      ),
                    ),
                  ],
                ),
                CheckboxListTile(
                  title: const Text('Private Poll'),
                  value: isPrivate,
                  onChanged: (value) => setState(() => isPrivate = value ?? false),
                ),
                if (isPrivate)
                  TextField(
                    onChanged: (value) => securityCode = value,
                    decoration: const InputDecoration(labelText: 'Security Code'),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || startDate == null || endDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all required fields')),
                  );
                  return;
                }

                try {
                  final poll = PollModel(
                    id: '', // Will be generated
                    title: titleController.text,
                    description: descriptionController.text,
                    startDate: startDate!,
                    endDate: endDate!,
                    isPrivate: isPrivate,
                    securityCode: securityCode,
                    createdBy: '', // Will be set by service
                    candidates: [],
                  );

                  await _supabaseService.createPoll(poll);
                  Navigator.pop(context);
                  _loadPolls();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Poll created successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPollDialog(PollModel poll) {
    // Similar to create dialog but with pre-filled values
    // Implementation omitted for brevity
  }

  Future<void> _deletePoll(String pollId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Poll'),
        content: const Text('Are you sure you want to delete this poll?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabaseService.deletePoll(pollId);
        _loadPolls();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Poll deleted')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showAddCandidateDialog(String pollId) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Candidate'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Candidate Name'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter candidate name')),
                );
                return;
              }

              try {
                final candidate = CandidateModel(
                  id: '', // Will be generated
                  name: nameController.text,
                  description: descriptionController.text,
                  pollId: pollId,
                );

                await _supabaseService.addCandidate(candidate);
                Navigator.pop(context);
                _loadPolls();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Candidate added')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}