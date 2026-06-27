import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_colors.dart';

class NotificationService {
  final SupabaseClient _client = Supabase.instance.client;
  bool _isListening = false;

  /// Starts a Supabase Realtime listener to detect new polls
  /// and shows an in-app banner to the user immediately.
  void startInAppNotifications(BuildContext context) {
    if (_isListening) return;
    _isListening = true;

    _client.channel('public:new_polls_alerts').onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'polls',
      callback: (payload) {
        final newPollData = payload.newRecord;
        
        // Ensure the context is still valid before showing UI
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(bottom: 80, left: 20, right: 20),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 5),
              content: Row(
                children: [
                  const Icon(Icons.notifications_active, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('New Poll Available!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        Text(newPollData['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    ).subscribe();
  }
}