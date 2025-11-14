import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/brew_kettle.dart';

class BrewKettleService {
  BrewKettleService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const String _schemaName = 'aibrewgenius';
  static const String _tableName = 'brew_kettles';

  SupabaseQueryBuilder _table() =>
      _client.schema(_schemaName).from(_tableName);

  Future<List<BrewKettle>> fetchKettles(String userProfileId) async {
    final data = await _table()
        .select()
        .eq('user_profile_id', userProfileId)
        .order('created_at');
    return data
        .cast<Map<String, dynamic>>()
        .map(BrewKettle.fromJson)
        .toList();
  }

  Future<BrewKettle> saveKettle(BrewKettle kettle) async {
    final data = await _table().upsert(kettle.toJson()).select().single();
    return BrewKettle.fromJson(data);
  }

  Future<void> deleteKettle(String id) async {
    await _table().delete().eq('id', id);
  }
}
