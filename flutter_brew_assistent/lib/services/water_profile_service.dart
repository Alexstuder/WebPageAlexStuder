import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/water_profile.dart';

class WaterProfileService {
  WaterProfileService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _schemaName = 'aibrewgenius';
  static const String _tableName = 'water_profiles';

  SupabaseQueryBuilder _table() =>
      _client.schema(_schemaName).from(_tableName);

  Future<List<WaterProfile>> fetchProfiles(String userProfileId) async {
    final data = await _table()
        .select()
        .eq('user_profile_id', userProfileId)
        .order('is_default', ascending: false)
        .order('created_at');
    return data
        .cast<Map<String, dynamic>>()
        .map(WaterProfile.fromJson)
        .toList();
  }

  Future<WaterProfile> saveProfile(WaterProfile profile) async {
    if (profile.isDefault) {
      await _table()
          .update({'is_default': false})
          .eq('user_profile_id', profile.userProfileId);
    }
    final payload = profile.toJson();
    final data = await _table().upsert(payload).select().single();
    return WaterProfile.fromJson(data);
  }

  Future<void> deleteProfile(String id) async {
    await _table().delete().eq('id', id);
  }
}
