import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';

class UserProfileService {
  UserProfileService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _tableName = 'user_profiles';
  static const String _schemaName = 'aibrewgenius';
  static const String defaultProfileId = 'self_hosted_profile';
  static Future<UserProfile?>? _cachedDefaultProfile;

  Future<void> saveProfile(UserProfile profile) async {
    await _table()
        .upsert(profile.toJson(), onConflict: 'id');
    if (profile.id == defaultProfileId) {
      _cachedDefaultProfile = Future.value(profile);
    }
  }

  Future<UserProfile?> fetchProfile(String id) async {
    final data =
        await _table().select().eq('id', id).maybeSingle();
    if (data == null) return null;
    final profile = UserProfile.fromJson(data);
    if (id == defaultProfileId) {
      _cachedDefaultProfile = Future.value(profile);
    }
    return profile;
  }

  Future<UserProfile?> fetchDefaultProfile({bool refresh = false}) {
    if (refresh || _cachedDefaultProfile == null) {
      _cachedDefaultProfile = fetchProfile(defaultProfileId);
    }
    return _cachedDefaultProfile!;
  }

  SupabaseQueryBuilder _table() =>
      _client.schema(_schemaName).from(_tableName);
}
