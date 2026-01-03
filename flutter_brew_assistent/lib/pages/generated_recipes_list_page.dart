import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ai_recipe.dart';
import 'recipe_result_page.dart';

class GeneratedRecipesListPage extends StatefulWidget {
  const GeneratedRecipesListPage({super.key});

  @override
  State<GeneratedRecipesListPage> createState() => _GeneratedRecipesListPageState();
}

class _GeneratedRecipesListPageState extends State<GeneratedRecipesListPage> {
  final _supabase = Supabase.instance.client;

  Stream<List<Map<String, dynamic>>> _recipesStream() {
    return _supabase.from('ai_generated_recipes').stream(primaryKey: ['id']).order('created_at', ascending: false).map((recipes) {
       // Since stream() doesn't support deep joins easily with realtime, we might need to fetch details on demand or accept that we only have the main table first.
       // However, the user wants the list. The list mainly needs the name and style.
       // The details are fetched on Tap? No, the OnTap logic I wrote assumes 'row' has everything.
       // Supabase 'stream' does NOT support joins. It only listens to one table.
       // We must switch to a FutureBuilder with standard .select() or accept that fetching details happens on Tap.
       // Given the constraint "modify stream builder logic", I will assume we switch to FutureBuilder or simple One-Shot query for now, OR fetch details in the OnTap.
       // BUT, the previous code structure uses StreamBuilder. To keep it responding to changes, I should keep StreamBuilder BUT 'stream' limitation is real.
       // actually, let's just create a Future that fetches EVERYTHING.
       // Wait, the user wants to see the list.
       // Let's change this to use .select() which is a Future, not a Stream, OR just fetch the ID and Name for the list, and fetch full details when clicking.
       // BUT my previous edit was inside the ListView builder assuming 'row' has the data.
       
       // Correct approach for "No View" and "Complex Data":
       // The list only needs name/style/date.
       // The DETAIL (On Tap) needs everything.
       return recipes;
    });
  }
  
  // Actually, I need to fetch the full data ON CLICK if I can't get it in the stream.
  // The 'row' in ListView right now only comes from 'ai_generated_recipes' table stream. It WON'T have the joined tables.
  // So my OnTap logic will fail because row['ai_recipe_malts'] will be null.
  
  // I need to fetch the full recipe in OnTap.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generierte Rezepte')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _recipesStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Fehler: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final recipes = snapshot.data!;
          if (recipes.isEmpty) {
            return const Center(child: Text('Keine gespeicherten Rezepte gefunden.'));
          }

          return ListView.builder(
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final row = recipes[index];
              final dateStr = row['created_at'] as String?;
              final date = dateStr != null ? DateTime.parse(dateStr).toLocal() : DateTime.now();

              return ListTile(
                title: Text(row['basis_bier'] ?? 'Unbenannt'),
                subtitle: Text('${row['bier_typ']} • ${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                   try {
                     // Fetch full details for this ID
                     final fullData = await _supabase.from('ai_generated_recipes').select('''
                        *,
                        ai_recipe_malts(*),
                        ai_recipe_hops(*),
                        ai_recipe_specials(*),
                        ai_recipe_finings(*),
                        ai_recipe_mash_steps(*),
                        ai_recipe_fermentation_steps(*)
                     ''').eq('id', row['id']).single();

                     // Normalize the returned data (Supabase returns List for 1:N relations)
                     final r = fullData;

                     final malts = (r['ai_recipe_malts'] as List?)?.map((m) => {
                       'Name': m['name'],
                       'Menge_kg': m['amount_kg'],
                       'Optimales_Schrot_Spaltmass_mm': m['crush_gap_mm'],
                     }).toList();

                     final hops = (r['ai_recipe_hops'] as List?)?.map((h) => {
                       'Sortenname': h['name'],
                       'Alpha_Saeure': h['alpha_acid'],
                       'Menge_g': h['amount_g'],
                       'Einsatz': h['use_type'],
                       'Zeit_min': h['time_min'],
                     }).toList();

                     final specials = (r['ai_recipe_specials'] as List?)?.map((s) => {
                       'Name': s['name'],
                       'Menge': s['amount'],
                       'Einheit': s['unit'],
                       'Anwendung_Detail': s['detail'],
                     }).toList();

                     final finings = (r['ai_recipe_finings'] as List?)?.map((f) => {
                       'Name': f['name'],
                       'Menge': f['amount'],
                       'Phase': f['phase'],
                       'Zweck': f['purpose'],
                       'Anwendung_Detail': f['detail'],
                       'Beschaffung_Notwendig': f['procurement_needed'],
                     }).toList();
                     
                     final mashSteps = (r['ai_recipe_mash_steps'] as List?)
                         ?..sort((a,b) => (a['step_order'] as int).compareTo(b['step_order'] as int));
                     final mashStepsMapped = mashSteps?.map((ms) => {
                       'Stufe': ms['stage'],
                       'Temperatur_C': ms['temp_c'],
                       'Dauer_min': ms['duration_min'],
                     }).toList();

                     final fermSteps = (r['ai_recipe_fermentation_steps'] as List?)
                         ?..sort((a,b) => (a['step_order'] as int).compareTo(b['step_order'] as int));
                     final fermStepsMapped = fermSteps?.map((fs) => {
                       'Phase': fs['phase'],
                       'Temperatur_C': fs['temp_c'],
                       'Dauer_Tage': fs['days'],
                       'Druck_bar': fs['pressure_bar'],
                       'Druck_Begruendung': fs['pressure_note'],
                       'Hinweis': fs['note'],
                     }).toList();

                     final recipeMap = {
                       'basis_bier': r['basis_bier'],
                       'bier_typ': r['bier_typ'],
                       'stammwuerze_sg': r['stammwuerze_sg'],
                       'restextrakt_sg': r['restextrakt_sg'],
                       'alkoholgehalt_vol_prozent': r['alkoholgehalt'],
                       'Notizen': r['notizen'] ?? [],
                       'generated_image': r['generated_image'],
                       'Zutaten': {
                         'Original_Malz': malts ?? [],
                         'Original_Hopfen': hops ?? [],
                         'Original_Hefe': {
                           'Name': r['yeast_name'],
                           'Typ': r['yeast_type'],
                           'Menge_Packungen_oder_ml': r['yeast_amount'],
                           'Beschaffung_Notwendig': r['yeast_procurement_needed'] ?? false,
                         },
                         'Wasserprofil_Zielwerte': {
                           'Kalzium_Ca_mg_L': r['water_ca'],
                           'Magnesium_Mg_mg_L': r['water_mg'],
                           'Natrium_Na_mg_L': r['water_na'],
                           'Chlorid_Cl_mg_L': r['water_cl'],
                           'Sulfat_SO4_mg_L': r['water_so4'],
                           'Hydrogencarbonat_HCO3_mg_L': r['water_hco3'],
                           'Salzzugabe_Zeitpunkt': r['water_salt_timing'],
                         },
                         'Spezialzutaten': specials ?? [],
                         'Klaer_und_Schonungsmittel': finings ?? [],
                       },
                       'Prozessdaten': {
                         'Maischeplan': {
                           'Hauptguss_L': r['mash_water_l'],
                           'Einmaischtemperatur_C': r['mash_in_temp_c'],
                           'Rasten': mashStepsMapped ?? [],
                         },
                         'Laeuterungsplan': {
                           'Nachgusswasser_Menge_L': r['lauter_sparge_water_l'],
                           'Ziel_pH_vor_Laeutern': r['lauter_target_ph'],
                         },
                         'Kochplan': {
                           'Pfannevoll_Tatsaechlich_L': r['boil_pre_vol_l'],
                           'Gesamte_Kochdauer_min': r['boil_duration_min'],
                         },
                         'Gaerungsplan': {
                           'Hefe_Anstelltemperatur_C': r['fermentation_pitch_temp_c'],
                           'Gaerverlauf': fermStepsMapped ?? [],
                         },
                         'Abfuell_und_Lagerungsplan': {
                           'Abfuellung_Typ': r['packaging_type'],
                           'Karbonisierung_Ziel_CO2_g_L': r['packaging_co2_target'],
                           'Keg_Druck_bar': r['packaging_keg_pressure'],
                           'Keg_Karbonisierung_Temp_C': r['packaging_keg_temp'],
                           'Flaschen_Zucker_g_pro_L': r['packaging_bottle_sugar'],
                           'Flaschen_Karbonisierung_Temp_C': r['packaging_bottle_temp'],
                           'Lagerung_Temperatur_C': r['packaging_storage_temp'],
                           'Lagerung_Dauer_Wochen': r['packaging_storage_weeks'],
                           'Reifungshinweis': r['packaging_maturation_note'],
                           'Empfohlenes_Ausschankgas': r['packaging_serving_gas'],
                           'Karbonisierungsdauer_Tage': r['packaging_carb_days'],
                         }
                       }
                     };

                     final recipe = AiRecipe.fromJson(recipeMap);
                     if (context.mounted) {
                       Navigator.of(context).push(
                         MaterialPageRoute(builder: (_) => RecipeResultPage(recipe: recipe)),
                       );
                     }

                   } catch (e) {
                     if (context.mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler beim Laden: $e')));
                     }
                   }
                },
              );
            },
          );
        },
      ),
    );
  }
}
