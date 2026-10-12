import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:marea/features/community/models/post_social.dart';
import '../models/notification_preferences.dart';

abstract interface class NotificationPreferencesRepository {
  Future<NotificationPreferences> load();
  Future<void> save(NotificationPreferences preferences);
  Future<void> recordActivity(String timezone);
  Future<void> registerDevice(
    String installationId,
    String token,
    bool enabled,
  );
  Future<void> unregisterDevice(String installationId);
  Future<SocialNotification?> notification(String id);
}

class SupabaseNotificationPreferencesRepository
    implements NotificationPreferencesRepository {
  SupabaseNotificationPreferencesRepository(this.client);
  final SupabaseClient client;
  @override
  Future<NotificationPreferences> load() async {
    final result = await client
        .from('notification_preferences')
        .select()
        .eq('user_id', client.auth.currentUser!.id)
        .maybeSingle();
    return NotificationPreferences.fromJson(result ?? {});
  }

  @override
  Future<void> save(NotificationPreferences p) async {
    await client.rpc(
      'set_notification_preferences',
      params: {'activity': p.activity, 'marea_messages': p.mareaMessages},
    );
  }

  @override
  Future<void> recordActivity(String timezone) async {
    await client.rpc(
      'record_notification_activity',
      params: {'zone': timezone},
    );
  }

  @override
  Future<void> registerDevice(
    String installationId,
    String token,
    bool enabled,
  ) async {
    await client.rpc(
      'register_notification_device',
      params: {
        'installation': installationId,
        'fcm_token': token,
        'permission_granted': enabled,
      },
    );
  }

  @override
  Future<void> unregisterDevice(String installationId) async {
    await client.rpc(
      'unregister_notification_device',
      params: {'installation': installationId},
    );
  }

  @override
  Future<SocialNotification?> notification(String id) async {
    final result = await client
        .from('notifications')
        .select()
        .eq('id', id)
        .maybeSingle();
    return result == null ? null : SocialNotification.fromJson(result);
  }
}
