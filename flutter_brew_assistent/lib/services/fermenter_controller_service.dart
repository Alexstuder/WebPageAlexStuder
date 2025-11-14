import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/fermenter_controller.dart';

class FermenterControllerService {
  FermenterControllerService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const String _schemaName = 'aibrewgenius';
  static const String _tableName = 'fermenter_controllers';

  SupabaseQueryBuilder _table() =>
      _client.schema(_schemaName).from(_tableName);

  Future<List<FermenterControllerModel>> fetchControllers(
      String userProfileId) async {
    final data = await _table()
        .select()
        .eq('user_profile_id', userProfileId)
        .order('created_at');
    return data
        .cast<Map<String, dynamic>>()
        .map(FermenterControllerModel.fromJson)
        .toList();
  }

  Future<FermenterControllerModel> saveController(
      FermenterControllerModel controller) async {
    final data = await _table().upsert(controller.toJson()).select().single();
    return FermenterControllerModel.fromJson(data);
  }

  Future<void> deleteController(String id) async {
    await _table().delete().eq('id', id);
  }
}
