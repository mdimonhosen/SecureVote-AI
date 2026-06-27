import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/supabase_service.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final _supabase = Supabase.instance.client;
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  // Fetches all users from your custom SQL table
  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      // Swapped 'display_name' to 'name' to match the database changes
      final response = await _supabase
          .from('users')
          .select('id, name, email, phone, created_at, role, status')
          .order('created_at', ascending: false);
      
      setState(() {
        _users = response;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Updates the user's status (Approve, Reject, or Ban/Unban)
  Future<void> _updateUserStatus(String userId, String status) async {
    try {
      await _supabase.from('users').update({'status': status}).eq('id', userId);
      
      // NEW: Blueprint 11.8 - Audit Logging addition
      await SupabaseService().logAdminAction(
        'USER_STATUS_CHANGE', 
        'Changed user ($userId) status to: $status'
      );

      _fetchUsers(); // Refresh the list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User marked as $status'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating user: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  // Shows a confirmation dialog before applying a strict ban
  void _confirmBanUser(String userId, String currentName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ban User?'),
        content: Text('Are you sure you want to ban $currentName? They will be completely blocked from logging in or using the system until unbanned.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            onPressed: () {
              Navigator.pop(context);
              _updateUserStatus(userId, 'banned');
            },
            child: const Text('Ban User', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Formats the ugly SQL timestamp into a readable date
  String _formatDate(String? isoDate) {
    if (isoDate == null) return 'Never';
    final date = DateTime.parse(isoDate).toLocal();
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Shows the popup dialog with specific SQL columns
  void _showUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user['name'] ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('UID', user['id']),
              _detailRow('Email', user['email']),
              _detailRow('Phone', user['phone'] ?? 'Not provided'),
              _detailRow('Role', user['role'].toString().toUpperCase()),
              _detailRow('Status', user['status'].toString().toUpperCase()),
              _detailRow('Registered On', _formatDate(user['created_at'])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppColors.primary)),
          )
        ],
      ),
    );
  }

  // Helper widget for the popup dialog
  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  // Builds the list UI based on whatever filtered list is passed to it
  Widget _buildUserList(List<dynamic> filteredUsers) {
    if (filteredUsers.isEmpty) {
      return const Center(child: Text('No users found in this category.', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        final status = user['status'];
        final isApproved = status == 'approved';
        final isPending = status == 'pending';
        final isBanned = status == 'banned';

        Color avatarColor = Colors.grey;
        IconData avatarIcon = Icons.person;

        if (isApproved) {
          avatarColor = Colors.green;
          avatarIcon = Icons.check;
        } else if (isPending) {
          avatarColor = Colors.orange;
          avatarIcon = Icons.hourglass_empty;
        } else if (isBanned) {
          avatarColor = Colors.black;
          avatarIcon = Icons.gavel;
        } else {
          // Rejected Status
          avatarColor = Colors.red;
          avatarIcon = Icons.block;
        }

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: avatarColor,
              child: Icon(avatarIcon, color: Colors.white),
            ),
            title: Text(user['name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['email'], maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  'Status: ${status.toString().toUpperCase()}', 
                  style: TextStyle(color: avatarColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
            onTap: () => _showUserDetails(user),
            trailing: user['role'] == 'admin' || user['role'] == 'system_admin'
                ? const Text('ADMIN', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: _buildActionButtons(user),
                  ),
          ),
        );
      },
    );
  }

  // Dynamically creates the correct buttons based on the user's current status
  List<Widget> _buildActionButtons(Map<String, dynamic> user) {
    final status = user['status'];
    final userId = user['id'];
    List<Widget> buttons = [];

    if (status == 'banned') {
      // Banned users only get the UNBAN button
      buttons.add(
        IconButton(
          icon: const Icon(Icons.restore, color: Colors.blue),
          tooltip: 'Unban User (Move to Pending)',
          onPressed: () => _updateUserStatus(userId, 'pending'),
        ),
      );
    } else {
      // APPROVE Button (shows if they aren't already approved)
      if (status != 'approved') {
        buttons.add(
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.green),
            tooltip: 'Approve Access',
            onPressed: () => _updateUserStatus(userId, 'approved'),
          ),
        );
      }

      // REJECT Button (shows if they aren't already rejected)
      if (status != 'rejected') {
        buttons.add(
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.red),
            tooltip: 'Reject Access',
            onPressed: () => _updateUserStatus(userId, 'rejected'),
          ),
        );
      }

      // BAN Button (available for anyone not already banned)
      buttons.add(
        IconButton(
          icon: const Icon(Icons.gavel, color: Colors.black),
          tooltip: 'Ban User Permanently',
          onPressed: () => _confirmBanUser(userId, user['name'] ?? 'this user'),
        ),
      );
    }

    return buttons;
  }

  @override
  Widget build(BuildContext context) {
    // Filter the full list of users into dedicated sub-lists
    final pendingUsers = _users.where((u) => u['status'] == 'pending').toList();
    final approvedUsers = _users.where((u) => u['status'] == 'approved').toList();
    final rejectedBannedUsers = _users.where((u) => u['status'] == 'rejected' || u['status'] == 'banned').toList();

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Users', style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.primary,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchUsers),
          ],
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Pending'),
              Tab(text: 'Approved'),
              Tab(text: 'Rejected/Banned'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : TabBarView(
                children: [
                  _buildUserList(_users),
                  _buildUserList(pendingUsers),
                  _buildUserList(approvedUsers),
                  _buildUserList(rejectedBannedUsers),
                ],
              ),
      ),
    );
  }
}