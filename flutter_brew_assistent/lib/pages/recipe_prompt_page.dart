import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/openai_service.dart';
import '../services/packaging_profile_service.dart';
import '../services/brew_kettle_service.dart';
import '../services/fining_agents_service.dart';
import '../services/user_profile_service.dart';
import '../models/user_profile.dart';
import '../models/packaging_profile.dart';
import '../models/brew_kettle.dart';
import '../models/fining_agents.dart';
import '../models/ai_recipe.dart';
import 'recipe_result_page.dart';
import 'user_profile_page.dart';
import '../widgets/user_name_banner.dart';

class RecipePromptPage extends StatefulWidget {
  const RecipePromptPage({super.key});

  static const String routeName = '/prompt';

  @override
  State<RecipePromptPage> createState() => _RecipePromptPageState();
}

class _RecipePromptPageState extends State<RecipePromptPage> {
  final TextEditingController _promptController = TextEditingController();
  final OpenAIService _service = OpenAIService();

  String? _response;
  String? _error;
  bool _isLoading = false;
  Uint8List? _imageBytes;
  String? _imageName;
  String? _imageMime;
  bool _isSearchingShops = false;

  String? _lastGeneratedPrompt;
  AiRecipe? _lastGeneratedRecipe;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _requestRecipe() async {
    final userInput = _promptController.text.trim();
    if (userInput.isEmpty) {
      setState(() {
        _error = 'Bitte gib eine Beschreibung ein.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _response = null;

      _lastGeneratedPrompt = null;
    });

    try {
      final bundle = DefaultAssetBundle.of(context);
      final template = await bundle.loadString('prompt/freitext_rezept_basis2');
      final jsonTemplate = await bundle.loadString('prompt/freitext_response_template2.json');

      double targetVolume = 20.0;
      double bottleVolume = 0.0;
      double kegVolume = 0.0;
      bool bottleEnabled = false;
      bool kegEnabled = false;
      String servingGas = 'CO2';
      double? bottleCarbTemp;
      double? kegCarbTemp;
      double? kegStorageTemp;
      bool foundDefaultPackaging = false;
      bool foundDefaultKettle = false;
      bool foundFining = false;

      try {
        final packagingService = PackagingProfileService();
        final profiles = await packagingService
            .fetchProfiles(UserProfileService.defaultProfileId);
        foundDefaultPackaging = profiles.any((p) => p.isDefault);
        
        final defaultProfile = profiles.firstWhere(
          (p) => p.isDefault,
          orElse: () => profiles.isNotEmpty
              ? profiles.first
              : PackagingProfile(
                  id: '',
                  userProfileId: '',
                  name: '',
                  createdAt: DateTime.now(),
                ),
        );

        if (defaultProfile.targetVolume != null) {
          targetVolume = defaultProfile.targetVolume!;
        }
        
        if (defaultProfile.bottleEnabled) {
          bottleEnabled = true;
          bottleCarbTemp = defaultProfile.bottleCarbonationTempC;
        }
 

        if (defaultProfile.kegEnabled) {
          kegEnabled = true;
          kegVolume = defaultProfile.kegVolumeLiters ?? 0.0;
          kegCarbTemp = defaultProfile.kegCarbonationTempC;
          kegStorageTemp = defaultProfile.kegStorageTempC;
          final List<String> g = [];
          if (defaultProfile.hasCo2) g.add('CO2');
          if (defaultProfile.hasNitro) g.add('Nitro');
          if (g.isNotEmpty) servingGas = g.join(' + ');
        }

        // Logic to split volumes
        if (bottleEnabled && kegEnabled) {
          if (kegVolume > targetVolume) {
            kegVolume = targetVolume;
            bottleVolume = 0;
          } else {
            bottleVolume = targetVolume - kegVolume;
          }
        } else if (kegEnabled) {
          kegVolume = targetVolume;
          bottleVolume = 0;
        } else {
          bottleVolume = targetVolume;
          bottleEnabled = true;
        }
      } catch (e) {
        debugPrint('Error fetching packaging profile: $e');
        // Fallback
        bottleVolume = targetVolume;
        bottleEnabled = true;
      }

      // --- 2. Construct Packaging Info String ---
      String packagingInfo = '';
      String bottleInfoText = '';
      String kegInfoText = '';

      if (kegEnabled && kegVolume > 0) {
        kegInfoText = '${kegVolume.toStringAsFixed(1)} Liter KEGS';
      }
      if (bottleEnabled && bottleVolume > 0) {
        bottleInfoText = '${bottleVolume.toStringAsFixed(1)} Liter FLASCHEN';
      }

      if (bottleInfoText.isNotEmpty && kegInfoText.isNotEmpty) {
        packagingInfo =
            'Abfüllung: $bottleInfoText und $kegInfoText (Zapfgas: $servingGas)\n(Flaschen-Temp: ${bottleCarbTemp ?? 20}°C, Keg-Carb-Temp: ${kegCarbTemp ?? 5}°C, Keg-Lager-Temp: ${kegStorageTemp ?? 5}°C)';
      } else if (bottleInfoText.isNotEmpty) {
        packagingInfo =
            'Abfüllung: $bottleInfoText\n(Flaschen-Temp: ${bottleCarbTemp ?? 20}°C)';
      } else if (kegInfoText.isNotEmpty) {
        packagingInfo =
            'Abfüllung: $kegInfoText (Zapfgas: $servingGas)\n(Keg-Carb-Temp: ${kegCarbTemp ?? 5}°C, Keg-Lager-Temp: ${kegStorageTemp ?? 5}°C)';
      } else {
        packagingInfo = 'Keine spezifische Abfüllung angegeben.';
      }

      // --- 3. Fetch Brew Kettle (Sudhaus) ---
      String brewingEquipmentInfo = 'Kein spezifisches Equipment angegeben.';
      try {
        final kettleService = BrewKettleService();
        final kettles =
            await kettleService.fetchKettles(UserProfileService.defaultProfileId);
        foundDefaultKettle = kettles.any((k) => k.isDefault);
        if (kettles.isNotEmpty) {
          final defaultKettle = kettles.firstWhere(
            (k) => k.isDefault,
            orElse: () => kettles.first,
          );
          final vol = defaultKettle.volumeLiters != null
              ? '${defaultKettle.volumeLiters}L'
              : 'Unbekannt';
          brewingEquipmentInfo =
              'Marke: ${defaultKettle.brand}, Modell: ${defaultKettle.model ?? ""}, Volumen: $vol';
          if (defaultKettle.notes != null &&
              defaultKettle.notes!.isNotEmpty) {
            brewingEquipmentInfo += ', Notizen: ${defaultKettle.notes}';
          }
           if (defaultKettle.hasCondenserHat) {
            brewingEquipmentInfo +=
                ', Kondensator Hut vorhanden (Verdunstung reduziert)';
          }
        }
      } catch (e) {
        debugPrint('Error fetching brew kettles: $e');
      }

      // --- 4. Fetch Fining Agents (Schönungsmittel) ---
      String finingAgentsInfo = 'Keine verfügbaren Schönungsmittel im Profil.';
      try {
        final finingService = FiningAgentsService();
        final settings = await finingService.fetchSettings(UserProfileService.defaultProfileId);
        
        final available = <String>[];
        if (settings.irishMoss) available.add('Irish Moss (Kochen)');
        if (settings.whirlfloc) available.add('Whirlfloc (Kochen/Whirlpool)');
        if (settings.gelatin) available.add('Gelatine (Klärung/Lagerung)');
        if (settings.biersol) available.add('Biersol (Klärung)');
        if (settings.polyclar) available.add('Polyclar (Stabilisierung)');
        if (settings.isinglass) available.add('Isinglass (Klärung)');
        if (settings.bentonite) available.add('Bentonite (Klärung)');
        if (settings.eggWhites) available.add('Eiweiß (Klärung)');
        if (settings.activatedCarbon) available.add('Aktivkohle (Klärung/Geschmack)');
        
        if (settings.extras.isNotEmpty) {
          available.addAll(settings.extras.map((e) => '$e (Benutzerdefiniert)'));
        }

        if (available.isNotEmpty) {
          foundFining = true;
          finingAgentsInfo = available.map((a) => '- $a').join('\n');
        }
      } catch (e) {
        debugPrint('Error fetching fining agents: $e');
      }



      // --- Check for missing defaults ---
      final missingDefaults = <String>[];
      if (!foundDefaultPackaging) missingDefaults.add('Verpackungsprofil (Favorit)');
      if (!foundDefaultKettle) missingDefaults.add('Brauanlage (Favorit)');
      if (!foundFining) missingDefaults.add('Schönungsmittel (keine ausgewählt)');

      if (missingDefaults.isNotEmpty) {
        if (!mounted) return;
        final proceed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Fehlende Favoriten/Informationen'),
            content: Text(
                'Für ein präzises Rezept fehlen folgende Informationen (Favoriten):\n\n${missingDefaults.map((e) => '- $e').join('\n')}\n\nOhne diese Angaben muss improvisiert werden (Standardwerte).'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Abbrechen'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Trotzdem erstellen'),
              ),
            ],
          ),
        );

        if (proceed != true) {
          setState(() => _isLoading = false);
          return;
        }
      }

      // --- 5. Build Final Prompt ---
      final fullPrompt = template
          .replaceAll('{{description}}', userInput)
          .replaceAll('{{targetVolume}}', targetVolume.toString())
          .replaceAll('{{packaging_info}}', packagingInfo)
          .replaceAll('{{brewing_equipment}}', brewingEquipmentInfo)
          .replaceAll('{{fining_agents}}', finingAgentsInfo)
          .replaceAll('{{json_template}}', jsonTemplate);

      setState(() {
        _lastGeneratedPrompt = fullPrompt;
      });

      final attachment = _buildAttachment();
      final recipeJsonString = await _service.brewRecipe(
        fullPrompt,
        attachment: attachment,
      );
      
      // Parse JSON
      final recipeMap = jsonDecode(recipeJsonString);
      final recipe = AiRecipe.fromJson(recipeMap);

      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _lastGeneratedRecipe = recipe;
        _response = recipeJsonString; // Save raw response
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecipeResultPage(recipe: recipe),
        ),
      );

    } catch (e) {
      String msg = e.toString();
      if (msg.contains('Interner Proxy-Fehler') || msg.contains('504') || msg.contains('500')) {
         msg = 'Fehler: Die KI antwortet nicht rechtzeitig oder das Bild ist zu groß.\nBitte versuche es erneut (ggf. ohne Bild oder kürzerem Text).';
      }
      setState(() => _error = msg);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        return;
      }
      final file = result.files.first;
      Uint8List? rawBytes = file.bytes;
      if (rawBytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konnte Bilddaten nicht laden.')),
        );
        return;
      }
      
      Uint8List bytes = rawBytes;

      // KEINE Bildbearbeitung mehr. Rohdaten verwenden.
      // Nur Check auf max Dateigröße (10 MB).
      await _validateImageSize(bytes);
      
      setState(() {
        _imageBytes = bytes;
        _imageName = file.name;
      });
      final mime = lookupMimeType(
        file.name,
        headerBytes: bytes.length >= 16 ? bytes.sublist(0, 16) : bytes,
      );
      if (mime == null || !mime.startsWith('image/')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nur Bilddateien werden unterstützt.')),
        );
        return;
      }
      setState(() {
        _imageBytes = bytes;
        _imageName = file.name;
        _imageMime = mime;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Bild-Upload: $e')),
      );
    }
  }

  Future<void> _clearImage() async {
    setState(() {
      _imageBytes = null;
      _imageName = null;
      _imageMime = null;
    });
  }

  Future<void> _validateImageSize(Uint8List bytes) async {
    // Basic check: if > 10MB, warning
    if (bytes.lengthInBytes > 10 * 1024 * 1024) {
      throw Exception('Bild zu groß (max 10MB)');
    }
  }

  RecipeImageAttachment? _buildAttachment() {
    if (_imageBytes == null || _imageMime == null) return null;
    return RecipeImageAttachment(
      bytes: _imageBytes!,
      mimeType: _imageMime!,
      fileName: _imageName,
    );
  }

  Future<void> _searchShopsForIngredients() async {
    if (_response == null || _isSearchingShops) return;
    final queries = _extractShopQueries(_response!);
    if (queries.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Keine Zutaten für die Shopsuche gefunden.')),
      );
      return;
    }
    setState(() {
      _isSearchingShops = true;
    });
    final results = <ShopSearchResponse>[];
    try {
      for (final query in queries) {
        final response = await _service.searchShops(query);
        results.add(response);
      }
      if (!mounted) return;
      setState(() {
        _isSearchingShops = false;
      });
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ShopResultsSheet(results: results),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSearchingShops = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Shopsuche fehlgeschlagen: $e')),
      );
    }
  }

  List<String> _extractShopQueries(String text) {
    final queries = <String>{};
    final parsed = _tryParseIngredientJson(text);
    if (parsed != null) {
      void collect(String key) {
        final list = parsed[key];
        if (list is List) {
          for (final item in list) {
            if (item is Map && item['name'] is String) {
              final name = (item['name'] as String).trim();
              if (name.isNotEmpty) {
                queries.add(name);
                if (queries.length >= 12) return;
              }
            }
          }
        }
      }

      collect('malz');
      collect('hopfen');
      collect('hefe');
      if (queries.isNotEmpty) {
        return queries.toList();
      }
    }

    final fallbackCategories = {'malz', 'hopfen', 'hefe'};
    final lines = text.split('\n');
    String? currentCategory;
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      final lower = line.toLowerCase();
      if (fallbackCategories.any(
        (cat) =>
            lower.startsWith(cat) &&
            (lower.length == cat.length ||
                lower.substring(cat.length).startsWith(' ') ||
                lower.substring(cat.length).startsWith(':')),
      )) {
        currentCategory =
            fallbackCategories.firstWhere((cat) => lower.startsWith(cat));
        continue;
      }
      if (lower.endsWith(':')) {
        final heading = lower.substring(0, lower.length - 1);
        if (fallbackCategories.contains(heading)) {
          currentCategory = heading;
          continue;
        }
      }
      if (currentCategory == null) continue;
      String entry = line;
      if (entry.startsWith('#')) continue;
      if (RegExp(r'^[0-9]+[\.\)]').hasMatch(entry)) continue;
      if (entry.toLowerCase().contains('mais') ||
          entry.toLowerCase().contains('gär') ||
          entry.toLowerCase().contains('plan')) {
        continue;
      }
      if (entry.startsWith('-') || entry.startsWith('*')) {
        entry = entry.substring(1).trim();
      }
      entry = entry.replaceFirst(RegExp(r'^[0-9\.\)\s]+'), '').trim();
      if (entry.isEmpty) continue;
      if (entry.toLowerCase() == 'unbekannt') continue;
      queries.add(entry);
      if (queries.length >= 8) break;
    }
    return queries.toList();
  }

  Map<String, dynamic>? _tryParseIngredientJson(String text) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bool isWide = media.size.width >= 720;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AiBrewGenius'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: UserNameBanner(),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Image.asset(
                        'assets/icon_small.png',
                        height: 98,
                        filterQuality: FilterQuality.none,
                        semanticLabel: 'AiBrewGenius',
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Wähle dein Equipment und Abfüll Profil',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          OutlinedButton(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const UserProfilePage(),
                                ),
                              );
                            },
                            child: const Text('Zum Profil'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _promptController,
                      maxLines: 5,
                      minLines: 3,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText:
                            'Beschreibe deinen Wunsch-Sud (Stil, Aromen, ABV …)',
                        errorText: _error,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        FilledButton.icon(
                          onPressed: _isLoading ? null : _requestRecipe,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.auto_awesome),
                          label: Text(_isLoading
                              ? 'Zaubere Rezept …'
                              : 'Rezept generieren'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 24),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _isLoading ? null : _pickImage,
                          tooltip: 'Bild hochladen (z.B. Etikett, Bierglas...)',
                          icon: const Icon(Icons.image),
                        ),
                        if (_imageName != null) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _imageName!,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          IconButton(
                            onPressed: _isLoading ? null : _clearImage,
                            icon: const Icon(Icons.close, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ],
                    ),
                    if (_response != null) ...[
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text('Ergebnis:',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(
                          _response!,
                          style: const TextStyle(
                              fontFamily: 'monospace', fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _searchShopsForIngredients,
                            icon: const Icon(Icons.store),
                            label: const Text('Zutaten einkaufen'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading) ...[
            const ModalBarrier(dismissible: false, color: Colors.black54),
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('AI braut dein Rezept ...'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ShopResultsSheet extends StatelessWidget {
  const _ShopResultsSheet({required this.results});

  final List<ShopSearchResponse> results;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      expand: false,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: ListView.builder(
          controller: controller,
          itemCount: results.length,
          itemBuilder: (context, index) {
            final result = results[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _ShopResultSection(result: result),
            );
          },
        ),
      ),
    );
  }
}

class _ShopResultSection extends StatelessWidget {
  const _ShopResultSection({required this.result});

  final ShopSearchResponse result;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Zutat: ${result.query}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...result.shops.map(
          (shop) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ShopCard(shop: shop),
          ),
        ),
      ],
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({required this.shop});

  final ShopSearchShop shop;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF111827),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  shop.shop,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (shop.url != null)
                  TextButton(
                    onPressed: () => _launchShopLink(shop.url!),
                    child: const Text('Shop öffnen'),
                  ),
              ],
            ),
            if (shop.error != null)
              Text(
                'Keine Ergebnisse automatisch verfügbar. Bitte Shop öffnen.',
                style: const TextStyle(color: Colors.redAccent),
              )
            else if (shop.results.isEmpty)
              const Text(
                'Keine Treffer gefunden.',
                style: TextStyle(color: Colors.white70),
              )
            else
              ...shop.results.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if ((item.price ?? '').isNotEmpty)
                        Text(item.price!,
                            style: const TextStyle(color: Colors.white70)),
                      if ((item.availability ?? '').isNotEmpty)
                        Text(
                          item.availability!,
                          style: const TextStyle(color: Colors.white54),
                        ),
                      if ((item.link ?? '').isNotEmpty)
                        TextButton(
                          onPressed: () => _launchShopLink(item.link!),
                          child: const Text('Produkt öffnen'),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchShopLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
