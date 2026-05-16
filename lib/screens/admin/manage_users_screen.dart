import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/supabase_service.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseService _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'All Users'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingUsersTab(),
          _buildAllUsersTab(),
        ],
      ),
    );
  }

  Widget _buildPendingUsersTab() {
    return FutureBuilder<List<UserModel>>(
      future: _supabaseService.getPendingUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return const Center(child: Text('No pending users'));
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              title: Text(user.name),
              subtitle: Text(user.email),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () => _approveUser(user.id, true),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => _approveUser(user.id, false),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAllUsersTab() {
    return FutureBuilder<List<UserModel>>(
      future: _supabaseService.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final users = snapshot.data ?? [];

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              title: Text(user.name),
              subtitle: Text('${user.email} - ${user.approved ? 'Approved' : 'Pending'}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (user.isAdmin)
                    const Icon(Icons.admin_panel_settings, color: Colors.blue)
                  else
                    IconButton(
                      icon: const Icon(Icons.security, color: Colors.grey),
                      onPressed: () => _setUserAsAdmin(user.id, true),
                      tooltip: 'Make Admin',
                    ),
                  if (user.isAdmin)
                    IconButton(
                      icon: const Icon(Icons.admin_panel_settings, color: Colors.blue),
                      onPressed: () => _setUserAsAdmin(user.id, false),
                      tooltip: 'Remove Admin',
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _approveUser(String userId, bool approved) async {
    try {
      await _supabaseService.approveUser(userId, approved);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User ${approved ? 'approved' : 'disapproved'}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _setUserAsAdmin(String userId, bool isAdmin) async {
    try {
      await _supabaseService.setUserAsAdmin(userId, isAdmin);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User ${isAdmin ? 'promoted to admin' : 'removed from admin'}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}