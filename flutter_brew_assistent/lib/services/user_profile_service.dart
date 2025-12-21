import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bf_recipe.dart';
import '../models/bf_batch.dart';
import '../models/misc.dart';
import '../models/hop.dart';
import '../models/fermentable.dart';
import '../models/user_profile.dart';

abstract class UserProfileRepository {
  Future<void> saveProfile(UserProfile profile);
  Future<UserProfile?> fetchProfile(String id);
  Future<UserProfile?> fetchDefaultProfile({bool refresh = false});
  
  // Fermentables
  Future<List<Fermentable>> getFermentables(String userProfileId);
  Future<void> saveFermentables(List<Fermentable> fermentables);
  Future<void> saveFermentable(Fermentable fermentable);
  Future<void> deleteFermentable(String id);

  // Hops
  Future<List<Hop>> getHops(String userProfileId);
  Future<void> saveHops(List<Hop> hops);
  Future<void> saveHop(Hop hop);

  // Miscs
  Future<List<Misc>> getMiscs(String userProfileId);
  Future<void> saveMiscs(List<Misc> miscs);
  Future<void> saveMisc(Misc misc);

  // Recipes
  Future<List<BfRecipe>> getRecipes(String userProfileId);
  Future<void> saveRecipes(List<BfRecipe> recipes);

  // Batches
  Future<List<BfBatch>> getBatches(String userProfileId);
  Future<void> saveBatches(List<BfBatch> batches);
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

  @override
  Future<List<Fermentable>> getFermentables(String userProfileId) async {
    final data = await _tableFermentables().select().eq('user_profile_id', userProfileId);
    return (data as List).map((e) => Fermentable.fromJson(e)).toList();
  }

  @override
  Future<void> saveFermentables(List<Fermentable> fermentables) async {
    if (fermentables.isEmpty) return;
    
    // Convert to JSON and remove null ID so DB generates it for new inserts
    final data = fermentables.map((e) {
      final json = e.toJson();
      if (json['id'] == null) json.remove('id');
      return json;
    }).toList();

    await _tableFermentables().upsert(data, onConflict: 'user_profile_id, brewfather_id');
  }

  @override
  Future<void> saveFermentable(Fermentable item) async {
    final json = item.toJson();
    if (json['id'] == null) json.remove('id');
    
    // If we have an ID, we upsert on ID (default).
    // If not, and no brewfather_id, we just insert.
    if (item.id != null) {
      await _tableFermentables().upsert(json);
    } else {
      await _tableFermentables().insert(json);
    }
  }

  @override
  Future<void> deleteFermentable(String id) async {
    await _tableFermentables().delete().eq('id', id);
  }

  @override
  Future<List<Hop>> getHops(String userProfileId) async {
    final data = await _tableHops().select().eq('user_profile_id', userProfileId);
    return (data as List).map((e) => Hop.fromJson(e)).toList();
  }

  @override
  Future<void> saveHops(List<Hop> hops) async {
    if (hops.isEmpty) return;
    final data = hops.map((e) {
      final json = e.toJson();
      if (json['id'] == null) json.remove('id');
      return json;
    }).toList();
    await _tableHops().upsert(data, onConflict: 'user_profile_id, brewfather_id');
  }

  @override
  Future<void> saveHop(Hop item) async {
    final json = item.toJson();
    if (json['id'] == null) json.remove('id');
    if (item.id != null) {
      await _tableHops().upsert(json);
    } else {
      await _tableHops().insert(json);
    }
  }

  Future<void> deleteHop(String id) async {
    await _tableHops().delete().eq('id', id);
  }

  @override
  Future<List<Misc>> getMiscs(String userProfileId) async {
    final data = await _tableMiscs().select().eq('user_profile_id', userProfileId);
    return (data as List).map((e) => Misc.fromJson(e)).toList();
  }

  @override
  Future<void> saveMiscs(List<Misc> miscs) async {
    if (miscs.isEmpty) return;
    final data = miscs.map((e) {
      final json = e.toJson();
      if (json['id'] == null) json.remove('id');
      return json;
    }).toList();
    await _tableMiscs().upsert(data, onConflict: 'user_profile_id, brewfather_id');
  }

  @override
  Future<void> saveMisc(Misc item) async {
    final json = item.toJson();
    if (json['id'] == null) json.remove('id');
    if (item.id != null) {
      await _tableMiscs().upsert(json);
    } else {
      await _tableMiscs().insert(json);
    }
  }

  Future<void> deleteMisc(String id) async {
    await _tableMiscs().delete().eq('id', id);
  }

  @override
  Future<List<BfRecipe>> getRecipes(String userProfileId) async {
    final data = await _tableRecipes().select().eq('user_profile_id', userProfileId);
    return (data as List).map((e) => BfRecipe.fromJson(e)).toList();
  }

  @override
  Future<void> saveRecipes(List<BfRecipe> recipes) async {
    if (recipes.isEmpty) return;
    final data = recipes.map((e) {
      final json = e.toDbJson();
      if (json['id'] == null) json.remove('id');
      return json;
    }).toList();
    await _tableRecipes().upsert(data, onConflict: 'user_profile_id, brewfather_id');
  }

  // Helper to save a single recipe (with image for example)
  Future<void> saveRecipe(BfRecipe recipe) async {
     final json = recipe.toDbJson();
      if (json['id'] == null) json.remove('id');
      await _tableRecipes().upsert(json, onConflict: 'user_profile_id, brewfather_id');
  }

  @override
  Future<List<BfBatch>> getBatches(String userProfileId) async {
    final data = await _tableBatches().select().eq('user_profile_id', userProfileId);
    return (data as List).map((e) => BfBatch.fromJson(e)).toList();
  }

  @override
  Future<void> saveBatches(List<BfBatch> batches) async {
    if (batches.isEmpty) return;

    // 1. Fetch existing batches for this user/profile to check for existing RAPT data or updates
    // We assume all batches belong to the same profile based on the first item
    final userProfileId = batches.first.userProfileId;
    final existingData = await _tableBatches()
        .select('brewfather_id, rapt_data, analysis_data, data, id')
        .eq('user_profile_id', userProfileId);
    
    // Map existing batches by brewfather_id for quick lookup
    final existingMap = {
      for (var item in existingData) 
         if (item['brewfather_id'] != null) item['brewfather_id'] as String : item
    };

    final Map<String, Map<String, dynamic>> dataToUpsert = {};
    for (var batch in batches) {
       var json = batch.toJson();
       if (json['id'] == null) json.remove('id');

       final bfId = batch.brewfatherId;
       if (bfId != null) {
          if (existingMap.containsKey(bfId)) {
             final existing = existingMap[bfId]!;
             
             // Preserve existing data if incoming is empty
             final incomingRapt = json['rapt_data'] as Map<String, dynamic>? ?? {};
             final existingRapt = existing['rapt_data'] as Map<String, dynamic>? ?? {};
             if (incomingRapt.isEmpty && existingRapt.isNotEmpty) {
                json['rapt_data'] = existingRapt;
             }

             final incomingAnalysis = json['analysis_data'] as Map<String, dynamic>? ?? {};
             final existingAnalysis = existing['analysis_data'] as Map<String, dynamic>? ?? {};
             if (incomingAnalysis.isEmpty && existingAnalysis.isNotEmpty) {
                json['analysis_data'] = existingAnalysis;
             }
             
             // Ensure we update the existing row ID if it exists
             json['id'] = existing['id'];
          }
          // Deduplicate in the local list to avoid conflict errors
          dataToUpsert[bfId] = json;
       }
    }

    if (dataToUpsert.isNotEmpty) {
       await _tableBatches().upsert(dataToUpsert.values.toList(), onConflict: 'user_profile_id, brewfather_id');
    }
  }

  SupabaseQueryBuilder _table() =>
      _client.schema(_schemaName).from(_tableName);

  SupabaseQueryBuilder _tableFermentables() =>
      _client.schema(_schemaName).from('fermentables');

  SupabaseQueryBuilder _tableHops() =>
    _client.schema(_schemaName).from('hops');

  SupabaseQueryBuilder _tableMiscs() =>
    _client.schema(_schemaName).from('miscs');

  SupabaseQueryBuilder _tableRecipes() =>
    _client.schema(_schemaName).from('recipes');

  SupabaseQueryBuilder _tableBatches() =>
    _client.schema(_schemaName).from('batches');
}
