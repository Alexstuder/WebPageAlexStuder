import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/packaging_profile.dart';

class PackagingProfileService {
  PackagingProfileService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const String _schemaName = 'aibrewgenius';
  static const String _tableName = 'packaging_profiles';

  SupabaseQueryBuilder _table() =>
      _client.schema(_schemaName).from(_tableName);

  Future<List<PackagingProfile>> fetchProfiles(String userProfileId) async {
    final data = await _table()
        .select()
        .eq('user_profile_id', userProfileId)
        .order('is_default', ascending: false)
        .order('created_at');
    return data
        .cast<Map<String, dynamic>>()
        .map(PackagingProfile.fromJson)
        .toList();
  }

  Future<PackagingProfile> saveProfile(PackagingProfile profile) async {
    if (profile.isDefault) {
      await _table()
          .update({'is_default': false})
          .eq('user_profile_id', profile.userProfileId);
    }
    final data = await _table().upsert(profile.toJson()).select().single();
    return PackagingProfile.fromJson(data);
  }

  Future<void> deleteProfile(String id) async {
    await _table().delete().eq('id', id);
  }
}
