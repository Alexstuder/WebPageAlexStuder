import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';

abstract class UserProfileRepository {
  Future<void> saveProfile(UserProfile profile);
  Future<UserProfile?> fetchProfile(String id);
  Future<UserProfile?> fetchDefaultProfile({bool refresh = false});
}

class UserProfileService implements UserProfileRepository {
  UserProfileService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _tableName = 'user_profiles';
  static const String _schemaName = 'aibrewgenius';
  static const String defaultProfileId = 'self_hosted_profile';
  static Future<UserProfile?>? _cachedDefaultProfile;

  @override
  Future<void> saveProfile(UserProfile profile) async {
    await _table()
        .upsert(profile.toJson(), onConflict: 'id');
    if (profile.id == defaultProfileId) {
      _cachedDefaultProfile = Future.value(profile);
    }
  }

  @override
  Future<UserProfile?> fetchProfile(String id) async {
    final data =
        await _table().select().eq('id', id).maybeSingle();
    print('DEBUG FETCHED DATA: $data');
    if (data == null) return null;
    final profile = UserProfile.fromJson(data);
    if (id == defaultProfileId) {
      _cachedDefaultProfile = Future.value(profile);
    }
    return profile;
  }

  @override
  Future<UserProfile?> fetchDefaultProfile({bool refresh = false}) {
    if (refresh || _cachedDefaultProfile == null) {
      _cachedDefaultProfile = fetchProfile(defaultProfileId);
    }
    return _cachedDefaultProfile!;
  }

  SupabaseQueryBuilder _table() =>
      _client.schema(_schemaName).from(_tableName);
}
