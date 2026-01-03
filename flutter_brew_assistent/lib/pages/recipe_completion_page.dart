import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ai_recipe.dart';
import '../services/openai_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'dart:convert';

class RecipeCompletionPage extends StatefulWidget {
  final AiRecipe recipe;

  const RecipeCompletionPage({super.key, required this.recipe});

  @override
  State<RecipeCompletionPage> createState() => _RecipeCompletionPageState();
}

class _RecipeCompletionPageState extends State<RecipeCompletionPage> {
  late final TextEditingController _promptController;
  final OpenAIService _openAIService = OpenAIService();
  bool _isGenerating = false;
  String? _generatedImageUrl;
  bool _useSourceImage = false;

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController(text: _buildInitialPrompt());
    _useSourceImage = widget.recipe.sourceImage != null;
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  String _buildInitialPrompt() {
    final style = widget.recipe.bierTyp;
    final name = widget.recipe.basisBier;
    
    String prompt = 'Erstelle ein professionelles Produktfoto für ein Bier \'$name\' im Stil \'$style\'. ';
    prompt += 'Das Bild zeigt das Bier in einem passenden Glas, appetitlich und frisch in Szene gesetzt. ';
    prompt += 'Die Umgebung ist atmosphärisch passend, aber nicht ablenkend. ';
    prompt += '\n\nSTRIKT FOR BREWFATHER-APP OPTIMIEREN:\n';
    prompt += '1. FORMAT & AUFLÖSUNG: Quadratisch (1:1), 1200x1200px (mind. 800x800px).\n';
    prompt += '2. DATEIGRÖSSEN-OPTIMIERUNG (<5MB): Nutze klare Flächen und starke Kontraste. Vermeide unnötiges visuelles Rauschen ("Noise"), um eine gute JPG/PNG-Komprimierung zu gewährleisten.\n';
    prompt += '3. INHALT: Bier im passenden Glas, zentral platziert (Safe-Zone für Cropping!), professioneller RGB-Stil.\n';
    prompt += '4. NO-GOS: Kein Text, keine Rahmen, keine Transparenz.';
    
    return prompt;
  }

  Future<void> _generateImage() async {
    if (_promptController.text.trim().isEmpty) return;

    setState(() {
      _isGenerating = true;
      _generatedImageUrl = null;
    });

    try {
      final result = await _openAIService.generateImage(
        _promptController.text,
        attachment: _useSourceImage ? widget.recipe.sourceImage : null,
      );
      if (mounted) {
        setState(() {
          _generatedImageUrl = result;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler bei der Generierung: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _saveRecipeNormalized() async {
    const userId = 'self_hosted_profile';
    final r = widget.recipe;
    final client = Supabase.instance.client;

    // Process image if available
    String? base64Image;
    if (_generatedImageUrl != null) {
      try {
        // Use the proxy-image URL if it's the one we are displaying, or standard URL?
        // _generatedImageUrl holds the direct OpenAI URL usually.
        // However, if we use a proxy in the app, we might want to fetch via that?
        // Standard OpenAI URL is fine if we are on the server/client that has access.
        // Since we are in the browser, CORS might be an issue if we fetch directly from OpenAI blob URL.
        // But the OpenAIService returns the direct URL.
        // Let's try fetching. The proxy is used for display because of CORS.
        // So we should probably use the proxy URL for fetching bytes too if we are on web.
        // _openAIService.proxyBaseUrl -> http://localhost:3000
        
        final urlToFetch = '${_openAIService.proxyBaseUrl}/proxy-image?url=${Uri.encodeComponent(_generatedImageUrl!)}';
        
        final response = await http.get(Uri.parse(urlToFetch));
        if (response.statusCode == 200) {
           final image = img.decodeImage(response.bodyBytes);
           if (image != null) {
             // Resize to max 512px
             final resized = img.copyResize(image, width: 512); 
             // Convert to JPG with 65% quality
             final jpg = img.encodeJpg(resized, quality: 65);
             base64Image = base64Encode(jpg);
           }
        }
      } catch (e) {
        debugPrint('Image processing failed: $e');
      }
    }

    // 1. Insert Main Recipe
    final recipeRes = await client.from('ai_generated_recipes').insert({
      'user_profile_id': userId,
      'basis_bier': r.basisBier,
      'bier_typ': r.bierTyp,
      'stammwuerze_sg': r.stammwuerzeSg,
      'restextrakt_sg': r.restextraktSg,
      'alkoholgehalt': r.alkoholgehalt,
      'notizen': r.notizen,
      'generated_image': base64Image,
      // Yeast (1:1)
      'yeast_name': r.zutaten.yeast.name,
      'yeast_type': r.zutaten.yeast.type,
      'yeast_amount': r.zutaten.yeast.amount,
      'yeast_procurement_needed': r.zutaten.yeast.procurementNeeded,
      // Water (1:1)
      'water_ca': r.zutaten.water.ca,
      'water_mg': r.zutaten.water.mg,
      'water_na': r.zutaten.water.na,
      'water_cl': r.zutaten.water.cl,
      'water_so4': r.zutaten.water.so4,
      'water_hco3': r.zutaten.water.hco3,
      'water_salt_timing': r.zutaten.water.saltTiming,
      // Process 1:1
      'mash_water_l': r.prozessdaten.mash.mashWaterL,
      'mash_in_temp_c': r.prozessdaten.mash.mashInTemp,
      'lauter_sparge_water_l': r.prozessdaten.lauter.spargeWaterL,
      'lauter_target_ph': r.prozessdaten.lauter.targetPh,
      'boil_pre_vol_l': r.prozessdaten.boil.preBoilVolumeL,
      'boil_duration_min': r.prozessdaten.boil.duration,
      'fermentation_pitch_temp_c': r.prozessdaten.fermentation.pitchTemp,
      // Packaging 1:1
      'packaging_type': r.prozessdaten.packaging.type,
      'packaging_co2_target': r.prozessdaten.packaging.co2Target,
      'packaging_keg_pressure': r.prozessdaten.packaging.kegPressure,
      'packaging_keg_temp': r.prozessdaten.packaging.kegTemp,
      'packaging_bottle_sugar': r.prozessdaten.packaging.bottleSugar,
      'packaging_bottle_temp': r.prozessdaten.packaging.bottleTemp,
      'packaging_storage_temp': r.prozessdaten.packaging.storageTemp,
      'packaging_storage_weeks': r.prozessdaten.packaging.storageDurationWeeks,
      'packaging_maturation_note': r.prozessdaten.packaging.maturationNote,
      'packaging_serving_gas': r.prozessdaten.packaging.servingGasRecommendation,
      'packaging_carb_days': r.prozessdaten.packaging.carbonationDurationDays,
    }).select('id').single();

    final recipeId = recipeRes['id'] as String;

    // 2. Insert Lists
    final futures = <Future>[];

    if (r.zutaten.malts.isNotEmpty) {
      futures.add(client.from('ai_recipe_malts').insert(
        r.zutaten.malts.map((m) => {
          'recipe_id': recipeId,
          'name': m.name,
          'amount_kg': m.amountKg,
          'crush_gap_mm': m.crushGap,
        }).toList()
      ));
    }

    if (r.zutaten.hops.isNotEmpty) {
      futures.add(client.from('ai_recipe_hops').insert(
        r.zutaten.hops.map((h) => {
          'recipe_id': recipeId,
          'name': h.name,
          'alpha_acid': h.alpha,
          'amount_g': h.amountG,
          'use_type': h.use,
          'time_min': h.timeMin,
        }).toList()
      ));
    }

    if (r.zutaten.specials.isNotEmpty) {
      futures.add(client.from('ai_recipe_specials').insert(
        r.zutaten.specials.map((s) => {
          'recipe_id': recipeId,
          'name': s.name,
          'amount': s.amount,
          'unit': s.unit,
          'detail': s.detail,
        }).toList()
      ));
    }
      
    if (r.zutaten.finings.isNotEmpty) {
      futures.add(client.from('ai_recipe_finings').insert(
        r.zutaten.finings.map((f) => {
          'recipe_id': recipeId,
          'name': f.name,
          'amount': f.amount,
          'phase': f.phase,
          'purpose': f.purpose,
          'detail': f.applicationDetail,
          'procurement_needed': f.procurementNeeded,
        }).toList()
      ));
    }
      
    if (r.prozessdaten.mash.steps.isNotEmpty) {
      final steps = r.prozessdaten.mash.steps.asMap().entries.map((e) => {
        'recipe_id': recipeId,
        'step_order': e.key,
        'stage': e.value.stage,
        'temp_c': e.value.temp,
        'duration_min': e.value.duration,
      }).toList();
      futures.add(client.from('ai_recipe_mash_steps').insert(steps));
    }

    if (r.prozessdaten.fermentation.steps.isNotEmpty) {
       final steps = r.prozessdaten.fermentation.steps.asMap().entries.map((e) => {
        'recipe_id': recipeId,
        'step_order': e.key,
        'phase': e.value.phase,
        'temp_c': e.value.temp,
        'days': e.value.days,
        'pressure_bar': e.value.pressure,
        'pressure_note': e.value.pressureReason,
        'note': e.value.note,
      }).toList();
      futures.add(client.from('ai_recipe_fermentation_steps').insert(steps));
    }

    await Future.wait(futures);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rezept abschließen'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Dein Rezept ist bereit!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            const Text(
              'Bild-Prompt anpassen:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _promptController,
              maxLines: 4,
              enabled: !_isGenerating,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'Vorgeschlagener Prompt...',
                fillColor: Colors.grey.withValues(alpha: 0.1),
                filled: true,
              ),
            ),
            if (widget.recipe.sourceImage != null) ...[
              const SizedBox(height: 8),
              CheckboxListTile(
                title: const Text(
                  'Soll das hochgeladene Foto als Vorlage an ChatGPT mitgeliefert werden?',
                  style: TextStyle(fontSize: 14),
                ),
                value: _useSourceImage,
                onChanged: _isGenerating 
                    ? null 
                    : (val) => setState(() => _useSourceImage = val ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ],
            const SizedBox(height: 16),
            

            const SizedBox(height: 16),
            
            if (_generatedImageUrl != null) ...[
              const Text(
                'Generiertes Bild:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 500),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
                  ),
                  child: Image.network(
                    '${_openAIService.proxyBaseUrl}/proxy-image?url=${Uri.encodeComponent(_generatedImageUrl!)}',
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return SizedBox(
                        height: 300,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(
                                'Lade Bild: ${loadingProgress.cumulativeBytesLoaded ~/ 1024} KB',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.red.withValues(alpha: 0.1),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 48),
                              const SizedBox(height: 8),
                              const Text('Bild konnte nicht geladen werden.'),
                              TextButton(
                                onPressed: _generateImage,
                                child: const Text('Erneut versuchen'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final url = Uri.parse(_generatedImageUrl!);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Bild öffnen / Download'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.withValues(alpha: 0.8),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _generatedImageUrl!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link in Zwischenablage kopiert!')),
                      );
                    },
                    icon: const Icon(Icons.link),
                    label: const Text('Link kopieren'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            _CompletionButton(
              label: _isGenerating ? 'Generiere...' : 'Bild generieren',
              icon: Icons.auto_awesome,
              onPressed: _isGenerating ? null : _generateImage,
              isLoading: _isGenerating,
            ),
            
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            
              _CompletionButton(
              label: 'Rezept abspeichern',
              icon: Icons.save,
              onPressed: _isGenerating ? null : () async {
                try {
                  await _saveRecipeNormalized();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Rezept erfolgreich gespeichert!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Fehler beim Speichern: $e')),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 16),
            _CompletionButton(
              label: 'In Brewfather.json transformieren',
              icon: Icons.code,
              onPressed: _isGenerating ? null : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('In Brewfather.json transformieren...')),
                );
              },
            ),
            const SizedBox(height: 16),
            _CompletionButton(
              label: 'In BeerXML transformieren',
              icon: Icons.description,
              onPressed: _isGenerating ? null : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('In BeerXML transformieren...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _CompletionButton({
    required this.label,
    required this.icon,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: isLoading 
          ? const SizedBox(
              width: 18, 
              height: 18, 
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ) 
          : Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 16),
      ),
    );
  }
}
