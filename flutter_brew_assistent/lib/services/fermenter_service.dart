import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/fermenter.dart';

class FermenterService {
  FermenterService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const String _schemaName = 'aibrewgenius';
  static const String _tableName = 'fermenters';

  SupabaseQueryBuilder _table() =>
      _client.schema(_schemaName).from(_tableName);

  Future<List<Fermenter>> fetchFermenters(String userProfileId) async {
    final data = await _table()
        .select()
        .eq('user_profile_id', userProfileId)
        .order('is_default', ascending: false)
        .order('created_at');
    return data
        .cast<Map<String, dynamic>>()
        .map(Fermenter.fromJson)
        .toList();
  }

  Future<Fermenter> saveFermenter(Fermenter fermenter) async {
    if (fermenter.isDefault) {
      await _table()
          .update({'is_default': false})
          .eq('user_profile_id', fermenter.userProfileId);
    }
    final data = await _table().upsert(fermenter.toJson()).select().single();
    return Fermenter.fromJson(data);
  }

  Future<void> deleteFermenter(String id) async {
    await _table().delete().eq('id', id);
  }
}
