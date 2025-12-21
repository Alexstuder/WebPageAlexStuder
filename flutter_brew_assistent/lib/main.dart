import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'pages/rapt_dashboard_page.dart';
import 'package:image/image.dart' as img; // For image resizing
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/openai_service.dart';
import 'services/user_profile_service.dart';
import 'services/water_profile_service.dart';
import 'services/brew_kettle_service.dart';
import 'services/fermenter_service.dart';
import 'services/yeast_bank_service.dart';
import 'services/malt_depot_service.dart';
import 'services/fermenter_controller_service.dart';
import 'services/packaging_profile_service.dart';
import 'services/fining_agents_service.dart';
import 'models/user_profile.dart';
import 'models/water_profile.dart';
import 'models/brew_kettle.dart';
import 'models/fermenter.dart';
import 'models/yeast_bank_entry.dart';
import 'models/malt_depot_entry.dart';
import 'models/fermenter_controller.dart';
import 'pages/available_ingredients_page.dart';
import 'pages/hops_manager_page.dart';
import 'pages/miscs_manager_page.dart';
import 'pages/recipes_list_page.dart';
import 'pages/batches_list_page.dart';
import 'models/packaging_profile.dart';
import 'models/fining_agents.dart';
import 'models/ai_recipe.dart';
import 'pages/recipe_result_page.dart';
import 'pages/integrations_page.dart';
import 'pages/brewfather_menu_page.dart';
import 'services/brewfather_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'widgets/card_actions.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('de_DE', null);
  await dotenv.load(fileName: '.env');
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception('Supabase config missing. Check .env');
  }
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const BrewMateApp());
}


class BrewMateApp extends StatelessWidget {
  const BrewMateApp({
    super.key,
    this.profileRepository,
    this.waterRepository,
    this.brewKettleRepository,
    this.fermenterRepository,
    this.fermenterControllerRepository,
    this.maltDepotRepository,
    this.packagingRepository,
    this.finingAgentsRepository,
    this.yeastRepository,
  });
  
  final UserProfileRepository? profileRepository;
  final WaterProfileRepository? waterRepository;
  final BrewKettleRepository? brewKettleRepository;
  final FermenterRepository? fermenterRepository;
  final FermenterControllerRepository? fermenterControllerRepository;
  final MaltDepotRepository? maltDepotRepository;
  final PackagingProfileRepository? packagingRepository;
  final FiningAgentsRepository? finingAgentsRepository;
  final YeastBankRepository? yeastRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AiBrewGenius',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2563EB),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF1E293B),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      initialRoute: BrewEntryPage.routeName,
      routes: {
        BrewEntryPage.routeName: (_) => const BrewEntryPage(),
        UserProfilePage.routeName: (_) => UserProfilePage(
          profileRepository: profileRepository,
          waterRepository: waterRepository,
          brewKettleRepository: brewKettleRepository,
          fermenterRepository: fermenterRepository,
          fermenterControllerRepository: fermenterControllerRepository,
          maltDepotRepository: maltDepotRepository,
          packagingRepository: packagingRepository,
          finingAgentsRepository: finingAgentsRepository,
          yeastRepository: yeastRepository,
        ),
        DiscoveryWelcomePage.routeName: (_) => const DiscoveryWelcomePage(),
        RecipePromptPage.routeName: (_) => const RecipePromptPage(),
        RaptDashboardPage.routeName: (_) => const RaptDashboardPage(),
      },
      builder: (context, child) {
        final Widget safeChild = child ?? const SizedBox.shrink();
        return LayoutBuilder(
          builder: (context, constraints) {
            const double maxWidth = 1200;
            if (constraints.maxWidth <= maxWidth) {
              return safeChild;
            }
            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: maxWidth,
                child: safeChild,
              ),
            );
          },
        );
      },
    );
  }
}

class BrewEntryPage extends StatelessWidget {
  const BrewEntryPage({super.key});

  static const String routeName = '/';

  void _openRoute(BuildContext context, String route) {
    Navigator.of(context).pushNamed(route);
  }

  Future<void> _openStudio(BuildContext context) async {
    final uri = Uri.parse('http://127.0.0.1:54323/');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konnte Studio nicht öffnen.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 20,
              right: 20,
              child: Image.asset(
                'assets/icon_small.png',
                height: 49,
                filterQuality: FilterQuality.none,
                semanticLabel: 'AiBrewGenius',
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  _EntryButton(
                    label: 'Users profil',
                    onPressed: () =>
                        _openRoute(context, UserProfilePage.routeName),
                  ),
                  const SizedBox(height: 18),
                  _EntryButton(
                    label: 'Currently Brewing',
                    onPressed: () => _openRoute(context, RaptDashboardPage.routeName),
                  ),
                  const SizedBox(height: 18),
                  _EntryButton(
                    label: 'Studio',
                    onPressed: () => _openStudio(context),
                  ),
                  const SizedBox(height: 18),
                  _EntryButton(
                    label: 'Start, entdecken wir ein neues Bier',
                    onPressed: () => _openRoute(
                      context,
                      DiscoveryWelcomePage.routeName,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _EntryButton(
                    label: 'Freie Text beschreibung',
                    onPressed: () =>
                        _openRoute(context, RecipePromptPage.routeName),
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
}

class DiscoveryWelcomePage extends StatefulWidget {
  const DiscoveryWelcomePage({super.key});

  static const String routeName = '/discover';

  @override
  State<DiscoveryWelcomePage> createState() => _DiscoveryWelcomePageState();
}

class _DiscoveryWelcomePageState extends State<DiscoveryWelcomePage> {
  final Map<String, List<String>> _beerGroups = const {
    'Ale': ['Porter', 'Stout', 'Pale Ale', 'IPA', 'Weizen', 'Belgian'],
    'Lager': ['Pale Lager', 'Schwarzbier', 'Märzen', 'Bock'],
  };

  String? _selectedBeer;

  Future<void> _handleSelection(String value) async {
    setState(() {
      _selectedBeer = value;
    });

    final beerType = _beerGroups.entries
        .firstWhere(
          (entry) => entry.value.contains(value),
          orElse: () => MapEntry('Unbekannt', <String>[]),
        )
        .key;

    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excelente Wahl. Los gehts ...'),
        content: Text('„$value“ auswählen und weitermachen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Weiter'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (proceed == true) {
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              FineTuningGeneralPage(beerName: value, beerType: beerType),
        ),
      );
      if (!mounted) return;
      setState(() {
        _selectedBeer = null;
      });
    } else {
      setState(() {
        _selectedBeer = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AiBrewGenius'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Image.asset(
              'assets/icon_small.png',
              height: 40,
              filterQuality: FilterQuality.none,
              semanticLabel: 'AiBrewGenius',
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _UserNameBanner(),
            const SizedBox(height: 20),
            const Text(
              'Wähle die Basis deines neuen Bieres',
              style: TextStyle(fontSize: 26, letterSpacing: 1.2),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: _beerGroups.entries
                    .map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: _BeerGroup(
                            title: entry.key,
                            beers: entry.value,
                            selected: _selectedBeer,
                            onSelected: _handleSelection,
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({
    super.key,
    this.profileRepository,
    this.waterRepository,
    this.brewKettleRepository,
    this.fermenterRepository,
    this.fermenterControllerRepository,
    this.maltDepotRepository,
    this.packagingRepository,
    this.finingAgentsRepository,
    this.yeastRepository,
  });

  static const String routeName = '/user-profile';
  final UserProfileRepository? profileRepository;
  final WaterProfileRepository? waterRepository;
  final BrewKettleRepository? brewKettleRepository;
  final FermenterRepository? fermenterRepository;
  final FermenterControllerRepository? fermenterControllerRepository;
  final MaltDepotRepository? maltDepotRepository;
  final PackagingProfileRepository? packagingRepository;
  final FiningAgentsRepository? finingAgentsRepository;
  final YeastBankRepository? yeastRepository;

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final TextEditingController _userNameCtrl = TextEditingController();
  final FocusNode _userNameFocusNode = FocusNode();


  final TextEditingController _defaultBatchCtrl = TextEditingController();

  String? _newAvatarBase64;
  late final UserProfileRepository _profileRepository;




  bool _isSaving = false;
  bool _isLoadingProfile = true;
  String? _loadError;
  static const String _profileId = UserProfileService.defaultProfileId;
  String? _userNameError;
  UserProfile? _loadedProfile;



  @override
  void initState() {
    super.initState();
    _profileRepository = widget.profileRepository ?? UserProfileService();
    _loadProfile();
  }

  @override
  void dispose() {
    _userNameCtrl.dispose();
    _userNameFocusNode.dispose();

    _defaultBatchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileRepository.fetchProfile(_profileId);
      _loadedProfile = profile;
      if (profile != null) {
        _userNameCtrl.text = profile.name;

        _defaultBatchCtrl.text = profile.defaultBatchLiters?.toString() ?? '';
      }
      setState(() {
        _isLoadingProfile = false;
        _loadError = null;
      });
    } catch (e) {
      setState(() {
        _isLoadingProfile = false;
        _loadError = e.toString();
      });
    }
  }

  Future<bool> _saveProfile({bool showFeedback = true}) async {
    FocusScope.of(context).unfocus();
    final double? defaultBatch =
        double.tryParse(_defaultBatchCtrl.text.replaceAll(',', '.'));

    final profile = UserProfile(
      id: _profileId,
      name: _userNameCtrl.text.trim(),

      avatarBlob: _newAvatarBase64 ?? _loadedProfile?.avatarBlob,
      defaultBatchLiters: defaultBatch,
      raptUserId: _loadedProfile?.raptUserId,
      raptApiKey: _loadedProfile?.raptApiKey,
      brewfatherUserId: _loadedProfile?.brewfatherUserId,

      brewfatherApiKey: _loadedProfile?.brewfatherApiKey,
      brewfatherSyncEnabled: _loadedProfile?.brewfatherSyncEnabled ?? false,
    );

    setState(() {
      _isSaving = true;
    });

    var success = false;
    try {
      await _profileRepository.saveProfile(profile);
      _loadedProfile = profile;
      if (!mounted) return success;
      if (showFeedback) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil gespeichert')),
        );
      }
      success = true;
    } catch (e) {
      if (!mounted) return success;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speichern fehlgeschlagen: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
    return success;
  }

  Future<void> _uploadAvatar() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      Uint8List? fileBytes = file.bytes;

      if (fileBytes == null) return;

      setState(() => _isSaving = true);

      // 1. Resize Image (Max 512x512)
      final image = img.decodeImage(fileBytes);
      if (image == null) throw Exception('Bild konnte nicht dekodiert werden');

      img.Image resized = image;
      if (image.width > 512 || image.height > 512) {
        resized = img.copyResize(
          image,
          width: image.width >= image.height ? 512 : null,
          height: image.height > image.width ? 512 : null,
        );
      }

      // 2. Compress to JPG 80%
      final jpgBytes = img.encodeJpg(resized, quality: 80);

      // 3. Encode to Base64 (BLOB)
      final base64Image = base64Encode(jpgBytes);

      setState(() {
        _newAvatarBase64 = base64Image;
        // Optional: Keep URL if you want fallback, or clear it. 
        // Clearing it makes it clear we are using the BLOB.
        // _avatarUrlCtrl.clear(); 
      });

      // Automatically save profile to persist BLOB
      await _saveProfile();

    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload fehlgeschlagen: $e')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users Profil'),
        centerTitle: true,
      ),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) => Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_loadError != null) ...[
                          Card(
                            color: Colors.red.shade900.withValues(alpha: 0.35),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                'Laden fehlgeschlagen: $_loadError',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        _buildUserSection(),
                        const SizedBox(height: 20),
                        _buildResourceButtons(),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isSaving)
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              else
                                const Icon(Icons.save_rounded),
                              const SizedBox(width: 12),
                              Text(_isSaving
                                  ? 'Speichert …'
                                  : 'Profil speichern'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Zurück'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  void _openBrewKettleManager() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BrewKettleManagerPage(
          profileId: _profileId,
          repository: widget.brewKettleRepository,
        ),
      ),
    );
  }

  void _openFermenterManager() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FermenterManagerPage(
          profileId: _profileId,
          repository: widget.fermenterRepository,
        ),
      ),
    );
  }

  void _openYeastBankManager() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => YeastBankManagerPage(
          profileId: _profileId,
          repository: widget.yeastRepository,
          userRepository: widget.profileRepository,
        ),
      ),
    );
  }



  void _openHopsManager() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HopsManagerPage(profileId: _profileId),
      ),
    );
  }

  void _openMiscsManager() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MiscsManagerPage(profileId: _profileId),
      ),
    );
  }

  void _openRecipesList() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecipesListPage(profileId: _profileId),
      ),
    );
  }

  void _openBatchesList() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BatchesListPage(profileId: _profileId),
      ),
    );
  }

  void _openAvailableIngredientsManager() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AvailableIngredientsPage(
          profileId: _profileId,
          userRepository: widget.profileRepository,
        ),
      ),
    );
  }

  void _openMaltDepotManager() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MaltDepotManagerPage(
          profileId: _profileId,
          repository: widget.maltDepotRepository,
        ),
      ),
    );
  }

  void _openFermenterControllerManager() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FermenterControllerManagerPage(
          profileId: _profileId,
          repository: widget.fermenterControllerRepository,
        ),
      ),
    );
  }

  void _openPackagingProfileManager() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PackagingProfileManagerPage(
          profileId: _profileId,
          repository: widget.packagingRepository,
        ),
      ),
    );
  }

  void _openFiningAgentsManager() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FiningAgentsPage(
          profileId: _profileId,
          repository: widget.finingAgentsRepository,
        ),
      ),
    );
  }

  void _openWaterProfileManager() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WaterProfileManagerPage(
          profileId: _profileId,
          repository: widget.waterRepository,
        ),
      ),
    );
  }

  void _openIntegrationsPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IntegrationsPage(profileId: _profileId),
      ),
    );
  }

  void _openBrewfatherMenu() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BrewfatherMenuPage(profileId: _profileId),
      ),
    );
  }

  Widget _buildUserSection() {
    ImageProvider? avatarImage;
    if (_newAvatarBase64 != null) {
      avatarImage = MemoryImage(base64Decode(_newAvatarBase64!));
    } else if (_loadedProfile?.avatarBlob != null &&
        _loadedProfile!.avatarBlob!.isNotEmpty) {
      avatarImage = MemoryImage(base64Decode(_loadedProfile!.avatarBlob!));


    }

    return Card(
      color: const Color(0xFF0F172A),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'User',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                GestureDetector(
                  onTap: _uploadAvatar,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundColor: const Color(0xFF1D4ED8),
                        backgroundImage: avatarImage,
                        child: avatarImage == null
                            ? Icon(
                                Icons.person_outline,
                                size: 36,
                                color: Colors.white.withValues(alpha: 0.9),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                width: 1.5),
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _userNameCtrl,
                    focusNode: _userNameFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      hintText: 'z. B. Alex Studer',
                      errorText: _userNameError,
                    ),
                    onChanged: (_) {
                      if (_userNameError != null) {
                        setState(() => _userNameError = null);
                      }
                    },
                  ),
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildResourceButtons() {
    return Column(
      children: [
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 60,
          ),
          children: [
            _managerButton(
              icon: Icons.water_drop_outlined,
              label: 'Wasserprofile',
              onPressed: _openWaterProfileManager,
            ),
            _managerButton(
              icon: Icons.kitchen_outlined,
              label: 'Braukessel',
              onPressed: _openBrewKettleManager,
            ),
            _managerButton(
              icon: Icons.science_outlined,
              label: 'Fermentierer',
              onPressed: _openFermenterManager,
            ),
            _managerButton(
              icon: Icons.developer_board_outlined,
              label: 'Fermentierer-Kontroller',
              onPressed: _openFermenterControllerManager,
            ),
            _managerButton(
              icon: Icons.inventory_2_outlined,
              label: 'Zielmenge,Abfüllen und Lagern',
              onPressed: _openPackagingProfileManager,
            ),
            _managerButton(
              icon: Icons.filter_alt_outlined,
              label: 'Klärmittel / Schönungsmittel',
              onPressed: _openFiningAgentsManager,
            ),
            _managerButton(
              icon: Icons.warehouse_outlined,
              label: 'Brauerei Shops',
              onPressed: _openMaltDepotManager,
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(color: Colors.white24),
        const SizedBox(height: 24),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 60,
          ),
          children: [
            _managerButton(
              icon: Icons.extension_outlined,
              label: 'Integration',
              onPressed: _openIntegrationsPage,
            ),
            _managerButton(
              icon: Icons.cloud_download_outlined,
              label: 'Brewfather',
              onPressed: _openBrewfatherMenu,
              customIcon: Image.asset(
                'assets/Brewfather_logo.png',
                width: 24,
                height: 24,
              ),
            ),
            _managerButton(
              icon: Icons.biotech_outlined,
              label: 'Hefe',
              onPressed: _openYeastBankManager,
            ),
            _managerButton(
              icon: Icons.grain_outlined,
              label: 'Vergärbare Zutaten',
              onPressed: _openAvailableIngredientsManager,
            ),
            _managerButton(
              icon: Icons.grass_outlined,
              label: 'Hopfen',
              onPressed: _openHopsManager,
            ),
             _managerButton(
              icon: Icons.category_outlined,
              label: 'Sonstiges',
              onPressed: _openMiscsManager,
            ),
             _managerButton(
              icon: Icons.menu_book,
              label: 'Rezepte',
              onPressed: _openRecipesList,
            ),
             _managerButton(
              icon: Icons.history_edu,
              label: 'Sud',
              onPressed: _openBatchesList,
            ),
          ],
        ),
      ],
    );
  }

  Widget _managerButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Widget? customIcon,
  }) {
    return OutlinedButton.icon(
      onPressed: () async {
        if (!_ensureUserName()) return;
        final saved = await _saveProfileIfNeeded();
        if (!saved) return;
        onPressed();
      },
      icon: customIcon ?? Icon(icon),
      label: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  bool _ensureUserName() {
    final name = _userNameCtrl.text.trim();
    if (name.isNotEmpty) {
      if (_userNameError != null) {
        setState(() => _userNameError = null);
      }
      return true;
    }
    setState(() => _userNameError = 'Name erforderlich');
    _userNameFocusNode.requestFocus();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Name fehlt'),
        content: const Text(
          'Bitte gib zuerst einen Profilnamen ein, bevor du weitere Ressourcen verwaltest.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return false;
  }

  Future<bool> _saveProfileIfNeeded() async {
    if (_isSaving) return false;
    final success = await _saveProfile(showFeedback: false);
    return success;
  }
}

class _WaterSectionHeader extends StatelessWidget {
  const _WaterSectionHeader({
    required this.title,
    required this.accent,
    required this.subtitle,
    this.trailing,
    this.trailingColor,
  });

  final String title;
  final Color accent;
  final String subtitle;
  final String? trailing;
  final Color? trailingColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: '$title ',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                  children: [
                    TextSpan(
                      text: subtitle,
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: TextStyle(
                  color: trailingColor ?? Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Container(height: 2, width: 64, color: accent),
      ],
    );
  }
}

class _WaterIonTile extends StatelessWidget {
  const _WaterIonTile({
    required this.title,
    required this.controller,
    this.fieldKey,
    this.onChanged,
  });

  final String title;
  final TextEditingController controller;
  final Key? fieldKey;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFF0F172A),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ppm',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: fieldKey,
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Wert',
              hintText: 'z. B. 50',
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _WaterStatTile extends StatelessWidget {
  const _WaterStatTile({
    required this.width,
    required this.label,
    required this.value,
  });

  final double width;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF0F172A),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WaterProfileManagerPage extends StatefulWidget {
  const WaterProfileManagerPage({
    super.key,
    required this.profileId,
    this.repository,
  });

  final String profileId;
  final WaterProfileRepository? repository;

  @override
  State<WaterProfileManagerPage> createState() =>
      _WaterProfileManagerPageState();
}

class _WaterProfileManagerPageState extends State<WaterProfileManagerPage> {
  bool _isLoading = true;
  String? _error;
  List<WaterProfile> _profiles = [];
  late final WaterProfileRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? WaterProfileService();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await _repository.fetchProfiles(widget.profileId);
      if (!mounted) return;
      items.sort((a, b) {
        if (a.isDefault != b.isDefault) {
          return a.isDefault ? -1 : 1;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      setState(() {
        _profiles = items;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wasserprofile'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add),
              label: const Text('Neu'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(
          'Konnte Wasserprofile nicht laden:\n$_error',
          textAlign: TextAlign.center,
        ),
      );
    }
    if (_profiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Noch keine Wasserprofile vorhanden.'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add),
              label: const Text('Profil anlegen'),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: _profiles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final profile = _profiles[index];
        final title = profile.name.isEmpty ? 'Unbenannt' : profile.name;
        final stats = _buildQuickStats(profile);
        return Card(
          color: const Color(0xFF0F172A),
          child: ListTile(
            onTap: () => _openEditor(editing: profile),
            leading: Icon(
              profile.isDefault ? Icons.star : Icons.star_border,
              color: profile.isDefault ? Colors.amber : Colors.white54,
            ),
            title: Text(title),
            subtitle: Text(stats),
            trailing: CardActions(
              onEdit: () => _openEditor(editing: profile),
              onDelete: () => _confirmDelete(
                title:
                    'Profil “${profile.name.isEmpty ? 'Unbenannt' : profile.name}” löschen?',
                onDelete: () => _deleteProfile(profile),
              ),
            ),
          ),
        );
      },
    );
  }

  String _buildQuickStats(WaterProfile profile) {
    final values = <String>[];
    if (profile.ph != null) {
      values.add('pH ${profile.ph!.toStringAsFixed(2)}');
    }
    values.add('Ca ${profile.calciumPpm.toStringAsFixed(0)} ppm');
    values.add('Mg ${profile.magnesiumPpm.toStringAsFixed(0)} ppm');
    values.add('SO₄ ${profile.sulfatePpm.toStringAsFixed(0)} ppm');
    values.add('Cl ${profile.chloridePpm.toStringAsFixed(0)} ppm');
    return values.join(' · ');
  }

  Future<void> _openEditor({WaterProfile? editing}) async {
    final saved = await Navigator.of(context).push<WaterProfile?>(
      MaterialPageRoute(
        builder: (_) => WaterProfileEditorPage(
          profileId: widget.profileId,
          profile: editing,
          repository: _repository,
        ),
      ),
    );
    if (saved != null) {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            editing == null
                ? 'Wasserprofil erstellt'
                : 'Wasserprofil aktualisiert',
          ),
        ),
      );
    }
  }

  Future<void> _deleteProfile(WaterProfile profile) async {
    try {
      await _repository.deleteProfile(profile.id!);
      setState(() {
        _profiles.removeWhere((element) => element.id == profile.id);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profil "${profile.name}" gelöscht')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profil konnte nicht gelöscht werden: $e')),
      );
    }
  }

  Future<void> _confirmDelete({
    required String title,
    required Future<void> Function() onDelete,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content:
            const Text('Dieser Vorgang kann nicht rückgängig gemacht werden.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await onDelete();
    }
  }
}

class WaterProfileEditorPage extends StatefulWidget {
  const WaterProfileEditorPage({
    super.key,
    required this.profileId,
    this.profile,
    this.repository,
  });

  final String profileId;
  final WaterProfile? profile;
  final WaterProfileRepository? repository;

  @override
  State<WaterProfileEditorPage> createState() => _WaterProfileEditorPageState();
}

class _WaterProfileEditorPageState extends State<WaterProfileEditorPage> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phCtrl = TextEditingController();
  final TextEditingController _calciumCtrl = TextEditingController();
  final TextEditingController _magnesiumCtrl = TextEditingController();
  final TextEditingController _sodiumCtrl = TextEditingController();
  final TextEditingController _chlorideCtrl = TextEditingController();
  final TextEditingController _sulfateCtrl = TextEditingController();
  final TextEditingController _bicarbonateCtrl = TextEditingController();

  bool _isDefault = false;
  bool _isSaving = false;
  bool _hasWaterStats = false;
  double? _computedWaterPh;
  double _cationCharge = 0;
  double _anionCharge = 0;
  double? _ionBalancePercent;
  double? _so4ClRatio;
  double? _waterHardness;
  double? _waterAlkalinity;
  double? _residualAlkalinity;
  late final WaterProfileRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? WaterProfileService();
    _loadFromProfile();
  }

  void _loadFromProfile() {
    final profile = widget.profile;
    if (profile != null) {
      _nameCtrl.text = profile.name;
      _phCtrl.text = _doubleToText(profile.ph, emptyIfNull: true);
      _calciumCtrl.text = _doubleToText(profile.calciumPpm);
      _magnesiumCtrl.text = _doubleToText(profile.magnesiumPpm);
      _sodiumCtrl.text = _doubleToText(profile.sodiumPpm);
      _chlorideCtrl.text = _doubleToText(profile.chloridePpm);
      _sulfateCtrl.text = _doubleToText(profile.sulfatePpm);
      _bicarbonateCtrl.text = _doubleToText(profile.bicarbonatePpm);
      _isDefault = profile.isDefault;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _updateWaterStats();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phCtrl.dispose();
    _calciumCtrl.dispose();
    _magnesiumCtrl.dispose();
    _sodiumCtrl.dispose();
    _chlorideCtrl.dispose();
    _sulfateCtrl.dispose();
    _bicarbonateCtrl.dispose();
    super.dispose();
  }

  bool get _hasWaterInput {
    final controllers = [
      _phCtrl,
      _calciumCtrl,
      _magnesiumCtrl,
      _sodiumCtrl,
      _chlorideCtrl,
      _sulfateCtrl,
      _bicarbonateCtrl,
    ];
    return controllers.any((ctrl) => ctrl.text.trim().isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.profile == null
        ? 'Wasserprofil anlegen'
        : 'Wasserprofil bearbeiten';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Profilname',
                      hintText: 'z. B. Glattfelden',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _phCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'pH',
                      hintText: '7.2',
                    ),
                    onChanged: (_) => _updateWaterStats(),
                  ),
                ),
              ],
            ),
            CheckboxListTile(
              value: _isDefault,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: const Text('Als Standard verwenden (★)'),
              onChanged: (value) {
                setState(() {
                  _isDefault = value ?? false;
                });
              },
            ),
            const SizedBox(height: 24),
            _WaterSectionHeader(
              title: 'Kationen',
              accent: const Color(0xFFEAB308),
              subtitle: 'Eingabe in ppm',
              trailing: _hasWaterStats
                  ? '${_cationCharge.toStringAsFixed(2)} mEq/L'
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _WaterIonTile(
                    title: 'Kalzium Ca²⁺',
                    controller: _calciumCtrl,
                    fieldKey: const Key('input_calcium'),
                    onChanged: (_) => _updateWaterStats(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _WaterIonTile(
                    title: 'Magnesium Mg²⁺',
                    controller: _magnesiumCtrl,
                    fieldKey: const Key('input_magnesium'),
                    onChanged: (_) => _updateWaterStats(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _WaterIonTile(
                    title: 'Natrium Na⁺',
                    controller: _sodiumCtrl,
                    fieldKey: const Key('input_sodium'),
                    onChanged: (_) => _updateWaterStats(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _WaterSectionHeader(
              title: 'Anionen',
              accent: const Color(0xFF38BDF8),
              subtitle: 'Eingabe in ppm',
              trailing: _hasWaterStats
                  ? '${_anionCharge.toStringAsFixed(2)} mEq/L'
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _WaterIonTile(
                    title: 'Chlorid Cl⁻',
                    controller: _chlorideCtrl,
                    fieldKey: const Key('input_chloride'),
                    onChanged: (_) => _updateWaterStats(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _WaterIonTile(
                    title: 'Sulfat SO₄²⁻',
                    controller: _sulfateCtrl,
                    fieldKey: const Key('input_sulfate'),
                    onChanged: (_) => _updateWaterStats(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _WaterIonTile(
                    title: 'Bicarbonat HCO₃⁻',
                    controller: _bicarbonateCtrl,
                    fieldKey: const Key('input_bicarbonate'),
                    onChanged: (_) => _updateWaterStats(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFF0F172A),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.white54),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Gib deine Wasserwerte in ppm ein. '
                      'Die Berechnung erfolgt automatisch.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_hasWaterStats) ...[
              const SizedBox(height: 24),
              _WaterSectionHeader(
                title: 'Statistiken',
                accent: Colors.white24,
                subtitle: 'Berechnet aus den Eingaben',
                trailing: _ionBalancePercent != null
                    ? 'Ionenbilanz ${_ionBalancePercent! >= 0 ? '+' : ''}${_ionBalancePercent!.toStringAsFixed(0)}%'
                    : null,
                trailingColor: (_ionBalancePercent?.abs() ?? 0) > 10
                    ? Colors.redAccent
                    : Colors.greenAccent,
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final double baseWidth = constraints.maxWidth >= 640
                      ? (constraints.maxWidth - 48) / 5
                      : (constraints.maxWidth - 36) / 3;
                  final double tileWidth =
                      baseWidth.clamp(140.0, constraints.maxWidth);
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _WaterStatTile(
                        width: tileWidth,
                        label: 'SO₄²⁻/Cl⁻ Verhältnis',
                        value: _formatNumber(_so4ClRatio),
                      ),
                      _WaterStatTile(
                        width: tileWidth,
                        label: 'Härte (ppm CaCO₃)',
                        value: _formatNumber(_waterHardness, fractionDigits: 0),
                      ),
                      _WaterStatTile(
                        width: tileWidth,
                        label: 'Alkalinität',
                        value:
                            _formatNumber(_waterAlkalinity, fractionDigits: 0),
                      ),
                      _WaterStatTile(
                        width: tileWidth,
                        label: 'Restalkalinität',
                        value: _formatNumber(_residualAlkalinity,
                            fractionDigits: 0),
                      ),
                      _WaterStatTile(
                        width: tileWidth,
                        label: 'pH Eingabe',
                        value: _computedWaterPh != null
                            ? _computedWaterPh!.toStringAsFixed(2)
                            : '–',
                      ),
                    ],
                  );
                },
              ),
            ],
            const SizedBox(height: 24),
            Row(
              key: const Key('editor_actions_row'),
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton.icon(
                  key: const Key('save_button'),
                  onPressed: _isSaving ? null : _handleSave,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isSaving ? 'Speichert …' : 'Speichern'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  label: const Text('Abbrechen'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    final draft = _buildDraft();
    setState(() {
      _isSaving = true;
    });
    try {
      final saved = await _repository.saveProfile(draft);
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Wasserprofil konnte nicht gespeichert werden: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  WaterProfile _buildDraft() {
    final name = _nameCtrl.text.trim().isEmpty
        ? 'Unbenanntes Profil'
        : _nameCtrl.text.trim();
    return WaterProfile(
      id: widget.profile?.id,
      userProfileId: widget.profileId,
      name: name,
      isDefault: _isDefault,
      ph: _parseOptionalDouble(_phCtrl),
      calciumPpm: _parseControllerValue(_calciumCtrl),
      magnesiumPpm: _parseControllerValue(_magnesiumCtrl),
      sodiumPpm: _parseControllerValue(_sodiumCtrl),
      chloridePpm: _parseControllerValue(_chlorideCtrl),
      sulfatePpm: _parseControllerValue(_sulfateCtrl),
      bicarbonatePpm: _parseControllerValue(_bicarbonateCtrl),
    );
  }

  double _parseControllerValue(TextEditingController controller) {
    return double.tryParse(controller.text.replaceAll(',', '.')) ?? 0.0;
  }

  double? _parseOptionalDouble(TextEditingController controller) {
    final text = controller.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text.replaceAll(',', '.'));
  }

  void _updateWaterStats() {
    if (!_hasWaterInput) {
      setState(() {
        _resetStats();
      });
      return;
    }
    final double ca = _parseControllerValue(_calciumCtrl);
    final double mg = _parseControllerValue(_magnesiumCtrl);
    final double na = _parseControllerValue(_sodiumCtrl);
    final double cl = _parseControllerValue(_chlorideCtrl);
    final double so4 = _parseControllerValue(_sulfateCtrl);
    final double hco3 = _parseControllerValue(_bicarbonateCtrl);
    final double ph = _parseControllerValue(_phCtrl);

    final double cationMeq = (ca / 20.0) + (mg / 12.15) + (na / 23.0);
    final double anionMeq = (cl / 35.45) + (so4 / 48.0) + (hco3 / 61.0);

    final double? ionBalance = (cationMeq > 0 && anionMeq > 0)
        ? ((cationMeq - anionMeq) / ((cationMeq + anionMeq) / 2)) * 100
        : null;

    final double? ratio = cl > 0 ? so4 / cl : null;
    final double hardness = (2.5 * ca) + (4.1 * mg);
    final double alkalinity = hco3 * (50 / 61);
    final double residual =
        alkalinity - ((2.5 * ca) / 3.5) - ((4.1 * mg) / 7.0);

    setState(() {
      _hasWaterStats = true;
      _cationCharge = cationMeq;
      _anionCharge = anionMeq;
      _ionBalancePercent = ionBalance;
      _so4ClRatio = ratio;
      _waterHardness = hardness;
      _waterAlkalinity = alkalinity;
      _residualAlkalinity = residual;
      _computedWaterPh = ph > 0 ? ph : null;
    });
  }

  void _resetStats() {
    _hasWaterStats = false;
    _cationCharge = 0;
    _anionCharge = 0;
    _ionBalancePercent = null;
    _so4ClRatio = null;
    _waterHardness = null;
    _waterAlkalinity = null;
    _residualAlkalinity = null;
    _computedWaterPh = null;
  }

  String _doubleToText(double? value, {bool emptyIfNull = false}) {
    if (value == null) {
      return emptyIfNull ? '' : '–';
    }
    if (value == 0) return '0';
    final bool isInt = value.truncateToDouble() == value;
    return isInt ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
  }

  String _formatNumber(double? value, {int fractionDigits = 2}) {
    if (value == null || value.isNaN || value.isInfinite) return '–';
    return value.toStringAsFixed(fractionDigits);
  }
}

class BrewKettleManagerPage extends StatefulWidget {
  const BrewKettleManagerPage({
    super.key,
    required this.profileId,
    this.repository,
  });

  final String profileId;
  final BrewKettleRepository? repository;

  @override
  State<BrewKettleManagerPage> createState() => _BrewKettleManagerPageState();
}

class _BrewKettleManagerPageState extends State<BrewKettleManagerPage> {
  late final BrewKettleRepository _service;

  @override
  void initState() {
    super.initState();
    _service = widget.repository ?? BrewKettleService();
    _load();
  }
  bool _isLoading = true;
  List<BrewKettle> _kettles = [];
  String? _error;



  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await _service.fetchKettles(widget.profileId);
      if (!mounted) return;
      setState(() {
        _kettles = items;
        _sortKettles();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Braukessel'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add),
              label: const Text('Neu'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(
          'Konnte Braukessel nicht laden:\n$_error',
          textAlign: TextAlign.center,
        ),
      );
    }
    if (_kettles.isEmpty) {
      return const Center(
        child: Text('Noch keine Braukessel vorhanden.'),
      );
    }
    return ListView.separated(
      itemCount: _kettles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final kettle = _kettles[index];
        final titleText = kettle.model?.isNotEmpty == true
            ? '${kettle.brand} ${kettle.model}'
            : kettle.brand;
        return Card(
          color: const Color(0xFF0F172A),
          child: ListTile(
            onTap: () => _openForm(editing: kettle),
            leading: Icon(
              kettle.isDefault ? Icons.star : Icons.star_border,
              color: kettle.isDefault ? Colors.amber : Colors.white54,
            ),
            title: Text(titleText.trim()),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (kettle.volumeLiters != null)
                  Text('Volumen: ${kettle.volumeLiters!.toStringAsFixed(1)} L'),
                if ((kettle.notes ?? '').isNotEmpty)
                  Text(
                    kettle.notes!,
                    style: const TextStyle(color: Colors.white70),
                  ),
                if (kettle.hasCondenserHat)
                  const Text(
                    'Hat Kondensator Hut',
                    style: TextStyle(color: Colors.lightBlueAccent),
                  ),
              ],
            ),
            trailing: CardActions(
              onEdit: () => _openForm(editing: kettle),
              onDelete: () => _confirmDelete(
                'Braukessel “${titleText.trim()}” löschen?',
                () => _deleteKettle(kettle),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openForm({BrewKettle? editing}) async {
    final brandCtrl = TextEditingController(text: editing?.brand ?? '');
    final modelCtrl = TextEditingController(text: editing?.model ?? '');
    final volumeCtrl = TextEditingController(
      text: editing?.volumeLiters?.toString() ?? '',
    );
    final notesCtrl = TextEditingController(text: editing?.notes ?? '');
    bool isDefault = editing?.isDefault ?? false;
    bool hasCondenserHat = editing?.hasCondenserHat ?? false;
    String? brandError;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(editing == null
              ? 'Braukessel hinzufügen'
              : 'Braukessel bearbeiten'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: brandCtrl,
                  decoration: InputDecoration(
                    labelText: 'Marke',
                    errorText: brandError,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: modelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Modell',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: volumeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Volumen (L)',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notizen',
                  ),
                ),
                CheckboxListTile(
                  value: hasCondenserHat,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Kondensator Hut'),
                  onChanged: (value) =>
                      setState(() => hasCondenserHat = value ?? false),
                ),
                CheckboxListTile(
                  value: isDefault,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Als Standard verwenden (★)'),
                  onChanged: (value) =>
                      setState(() => isDefault = value ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                if (brandCtrl.text.trim().isEmpty) {
                  setState(() => brandError = 'Marke erforderlich');
                  return;
                }
                Navigator.of(dialogCtx).pop(true);
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    final kettle = BrewKettle(
      id: editing?.id,
      userProfileId: widget.profileId,
      brand: brandCtrl.text.trim(),
      model: modelCtrl.text.trim().isEmpty ? null : modelCtrl.text.trim(),
      isDefault: isDefault,
      volumeLiters: _parseDouble(volumeCtrl.text),
      hasCondenserHat: hasCondenserHat,
      notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
    );

    try {
      final saved = await _service.saveKettle(kettle);
      if (!mounted) return;
      setState(() {
        if (saved.isDefault) {
          _kettles = _kettles
              .map((existing) => existing.id == saved.id
                  ? existing
                  : existing.copyWith(isDefault: false))
              .toList();
        }
        _upsert(saved);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              editing == null
                  ? 'Braukessel erstellt'
                  : 'Braukessel aktualisiert',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speichern fehlgeschlagen: $e')),
      );
    }
  }

  void _upsert(BrewKettle kettle) {
    final index = _kettles.indexWhere((element) => element.id == kettle.id);
    if (index >= 0) {
      _kettles[index] = kettle;
    } else {
      _kettles.add(kettle);
    }
    _sortKettles();
  }

  void _sortKettles() {
    _kettles.sort((a, b) {
      if (a.isDefault != b.isDefault) {
        return a.isDefault ? -1 : 1;
      }
      return a.brand.toLowerCase().compareTo(b.brand.toLowerCase());
    });
  }

  double? _parseDouble(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned.replaceAll(',', '.'));
  }

  Future<void> _deleteKettle(BrewKettle kettle) async {
    if (kettle.id == null) return;
    try {
      await _service.deleteKettle(kettle.id!);
      setState(() {
        _kettles.removeWhere((item) => item.id == kettle.id);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Braukessel "${kettle.brand}" gelöscht')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Löschen fehlgeschlagen: $e')));
    }
  }

  Future<void> _confirmDelete(
    String title,
    Future<void> Function() onDelete,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content:
            const Text('Dieser Vorgang kann nicht rückgängig gemacht werden.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await onDelete();
    }
  }
}

class FermenterManagerPage extends StatefulWidget {
  const FermenterManagerPage({
    super.key,
    required this.profileId,
    this.repository,
  });

  final String profileId;
  final FermenterRepository? repository;

  @override
  State<FermenterManagerPage> createState() => _FermenterManagerPageState();
}

class _FermenterManagerPageState extends State<FermenterManagerPage> {
  late final FermenterRepository _service;
  bool _isLoading = true;
  List<Fermenter> _fermenters = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = widget.repository ?? FermenterService();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await _service.fetchFermenters(widget.profileId);
      if (!mounted) return;
      setState(() {
        _fermenters = items;
        _sortFermenters();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fermentierer'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add),
              label: const Text('Neu'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(
          'Konnte Fermentierer nicht laden:\n$_error',
          textAlign: TextAlign.center,
        ),
      );
    }
    if (_fermenters.isEmpty) {
      return const Center(
        child: Text('Noch keine Fermentierer vorhanden.'),
      );
    }
    return ListView.separated(
      itemCount: _fermenters.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final fermenter = _fermenters[index];
        final titleText = fermenter.type?.isNotEmpty == true
            ? '${fermenter.brand} ${fermenter.type}'
            : fermenter.brand;
        return Card(
          color: const Color(0xFF0F172A),
          child: ListTile(
            onTap: () => _openForm(editing: fermenter),
            leading: Icon(
              fermenter.isDefault ? Icons.star : Icons.star_border,
              color: fermenter.isDefault ? Colors.amber : Colors.white54,
            ),
            title: Text(titleText.trim()),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (fermenter.volumeLiters != null)
                  Text(
                      'Volumen: ${fermenter.volumeLiters!.toStringAsFixed(1)} L'),
                Text('Heizung: ${fermenter.hasHeating ? 'Ja' : 'Nein'}'),
                Text('Kühlung: ${fermenter.hasCooling ? 'Ja' : 'Nein'}'),
                Text(
                    'Dry-Hopping-Port: ${fermenter.hasDryHoppingPort ? 'Ja' : 'Nein'}'),
                if ((fermenter.notes ?? '').isNotEmpty)
                  Text(
                    fermenter.notes!,
                    style: const TextStyle(color: Colors.white70),
                  ),
              ],
            ),
            trailing: CardActions(
              onEdit: () => _openForm(editing: fermenter),
              onDelete: () => _confirmDelete(
                'Fermentierer “${titleText.trim()}” löschen?',
                () => _deleteFermenter(fermenter),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openForm({Fermenter? editing}) async {
    final brandCtrl = TextEditingController(text: editing?.brand ?? '');
    final typeCtrl = TextEditingController(text: editing?.type ?? '');
    final volumeCtrl =
        TextEditingController(text: editing?.volumeLiters?.toString() ?? '');
    final notesCtrl = TextEditingController(text: editing?.notes ?? '');
    bool hasHeating = editing?.hasHeating ?? false;
    bool hasCooling = editing?.hasCooling ?? false;
    bool hasDryHopPort = editing?.hasDryHoppingPort ?? false;
    bool isDefault = editing?.isDefault ?? false;
    String? brandError;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(editing == null
              ? 'Fermentierer hinzufügen'
              : 'Fermentierer bearbeiten'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: brandCtrl,
                  decoration: InputDecoration(
                    labelText: 'Marke',
                    errorText: brandError,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: typeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Typ',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: volumeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Volumen (L)',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notizen',
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: hasHeating,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Heizung vorhanden'),
                  onChanged: (value) =>
                      setState(() => hasHeating = value ?? false),
                ),
                CheckboxListTile(
                  value: hasCooling,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Kühlung vorhanden'),
                  onChanged: (value) =>
                      setState(() => hasCooling = value ?? false),
                ),
                CheckboxListTile(
                  value: hasDryHopPort,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Dry-Hopping Port vorhanden'),
                  onChanged: (value) =>
                      setState(() => hasDryHopPort = value ?? false),
                ),
                CheckboxListTile(
                  value: isDefault,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Als Standard verwenden (★)'),
                  onChanged: (value) =>
                      setState(() => isDefault = value ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                if (brandCtrl.text.trim().isEmpty) {
                  setState(() => brandError = 'Marke erforderlich');
                  return;
                }
                Navigator.of(dialogCtx).pop(true);
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    final fermenter = Fermenter(
      id: editing?.id,
      userProfileId: widget.profileId,
      brand: brandCtrl.text.trim(),
      type: typeCtrl.text.trim().isEmpty ? null : typeCtrl.text.trim(),
      volumeLiters: _parseDouble(volumeCtrl.text),
      hasHeating: hasHeating,
      hasCooling: hasCooling,
      hasDryHoppingPort: hasDryHopPort,
      isDefault: isDefault,
      notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
    );

    try {
      final saved = await _service.saveFermenter(fermenter);
      if (!mounted) return;
      setState(() {
        if (saved.isDefault) {
          _fermenters = _fermenters
              .map((existing) => existing.id == saved.id
                  ? existing
                  : existing.copyWith(isDefault: false))
              .toList();
        }
        final index =
            _fermenters.indexWhere((element) => element.id == saved.id);
        if (index >= 0) {
          _fermenters[index] = saved;
        } else {
          _fermenters.add(saved);
        }
        _sortFermenters();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              editing == null
                  ? 'Fermentierer erstellt'
                  : 'Fermentierer aktualisiert',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speichern fehlgeschlagen: $e')),
      );
    }
  }

  double? _parseDouble(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned.replaceAll(',', '.'));
  }

  void _sortFermenters() {
    _fermenters.sort((a, b) {
      if (a.isDefault != b.isDefault) {
        return a.isDefault ? -1 : 1;
      }
      return a.brand.toLowerCase().compareTo(b.brand.toLowerCase());
    });
  }

  Future<void> _deleteFermenter(Fermenter fermenter) async {
    if (fermenter.id == null) return;
    try {
      await _service.deleteFermenter(fermenter.id!);
      setState(() {
        _fermenters.removeWhere((item) => item.id == fermenter.id);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fermentierer "${fermenter.brand}" gelöscht')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Löschen fehlgeschlagen: $e')));
    }
  }

  Future<void> _confirmDelete(
    String title,
    Future<void> Function() onDelete,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content:
            const Text('Dieser Vorgang kann nicht rückgängig gemacht werden.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await onDelete();
    }
  }
}

class YeastBankManagerPage extends StatefulWidget {
  const YeastBankManagerPage({
    super.key,
    required this.profileId,
    this.repository,
    this.userRepository,
  });

  final String profileId;
  final YeastBankRepository? repository;
  final UserProfileRepository? userRepository;

  @override
  State<YeastBankManagerPage> createState() => _YeastBankManagerPageState();
}

class _YeastBankManagerPageState extends State<YeastBankManagerPage> {
  late final YeastBankRepository _service;
  late final UserProfileRepository _userService;
  bool _isLoading = true;
  List<YeastBankEntry> _entries = [];
  String? _error;
  bool _syncEnabled = false;
  UserProfile? _userProfile;
  final Map<String, String> _debugJsonMap = {};

  @override
  void initState() {
    super.initState();
    _service = widget.repository ?? YeastBankService();
    _userService = widget.userRepository ?? UserProfileService();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // 1. Erstmal lokale Daten laden und anzeigen
      final profile = await _userService.fetchProfile(widget.profileId);
      final items = await _service.fetchEntries(widget.profileId);
      
      if (!mounted) return;
      
      setState(() {
        _userProfile = profile;
        _syncEnabled = profile?.brewfatherSyncEnabled ?? false;
        _entries = items;
        _isLoading = false; // Ladeindikator frühzeitig entfernen
      });

      // 2. Im Hintergrund synchronisieren (falls aktiv)
      if (_syncEnabled) {
         await _syncWithBrewfather();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _syncWithBrewfather() async {
     if (_userProfile?.brewfatherUserId == null || _userProfile?.brewfatherApiKey == null) return;
     try {
       final bfService = BrewfatherService(userId: _userProfile!.brewfatherUserId!, apiKey: _userProfile!.brewfatherApiKey!);
       final inventory = await bfService.getInventory();
       final yeasts = inventory['yeasts'] ?? [];
       
       bool changed = false;
       for (var y in yeasts) {
          // Check if exists
          final name = y['name'] ?? '';
          if (name.isEmpty) continue;
          
          YeastBankEntry? existingEntry;
          final bfId = y['_id'] ?? y['id'];

          // 1. Try match by brewfatherId
          if (bfId != null) {
            try {
              existingEntry =
                  _entries.firstWhere((e) => e.brewfatherId == bfId);
            } catch (_) {}
          }

          // 2. Fallback to name match if not found
          if (existingEntry == null) {
            try {
              existingEntry = _entries.firstWhere(
                  (e) => e.strain.toLowerCase() == name.toLowerCase());
            } catch (_) {}
          }

          if (mounted) {
             setState(() {
                _debugJsonMap[name] = jsonEncode(y);
             });
          }

          // Update or Create
          final newEntry = YeastBankEntry(
            id: existingEntry?.id, // ID behalten für Update
            userProfileId: widget.profileId,
            brewfatherId: bfId,
            brand: y['laboratory'] ?? y['lab'] ?? 'Brewfather',
            strain: name,
            style: y['type'],
            attenuationMin: (y['minAttenuation'] as num?)?.toDouble() ?? (y['attenuation'] as num?)?.toDouble(),
            attenuationMax: (y['maxAttenuation'] as num?)?.toDouble() ?? (y['attenuation'] as num?)?.toDouble(),
            temperatureMin: (y['minTemp'] as num?)?.toDouble(),
            temperatureMax: (y['maxTemp'] as num?)?.toDouble(),
            notes: y['description'] ?? y['notes'],
            // Map additional fields from Brewfather or preserve existing
            productId: y['productId']?.toString() ?? existingEntry?.productId,
            form: y['form']?.toString() ?? existingEntry?.form,
            inventory: (y['inventory'] as num?)?.toDouble() ?? (y['amount'] as num?)?.toDouble(),
            unit: y['unit']?.toString() ?? y['amountUnit']?.toString(),
            url: existingEntry?.url, // Preserve local URL
          );
          
          final saved = await _service.saveEntry(newEntry);
          
          if (existingEntry != null) {
             final index = _entries.indexOf(existingEntry);
             if (index != -1) {
               _entries[index] = saved;
             }
          } else {
             _entries.add(saved);
          }
          changed = true;
       }
       if (changed && mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hefen von Brewfather synchronisiert.')));
           setState(() {});
       }
     } catch (e) {
       debugPrint('Sync Error: $e');
     }
  }

  Future<void> _toggleSync(bool value) async {
    if (_userProfile == null) return;
    
    if (value) {
      if ((_userProfile!.brewfatherUserId ?? '').isEmpty || (_userProfile!.brewfatherApiKey ?? '').isEmpty) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Fehlende Zugangsdaten'),
            content: const Text(
                'Bitte hinterlegen Sie erst Ihre Brewfather User ID und API Key in den Einstellungen.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Abbrechen')),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => IntegrationsPage(profileId: widget.profileId),
                    ),
                  );
                },
                child: const Text('Zu den Einstellungen'),
              ),
            ],
          ),
        );
        return;
      }
    }

    final updated = UserProfile(
      id: _userProfile!.id,
      name: _userProfile!.name,
      avatarBlob: _userProfile!.avatarBlob,
      defaultBatchLiters: _userProfile!.defaultBatchLiters,
      raptUserId: _userProfile!.raptUserId,
      raptApiKey: _userProfile!.raptApiKey,
      brewfatherUserId: _userProfile!.brewfatherUserId,
      brewfatherApiKey: _userProfile!.brewfatherApiKey,
      brewfatherSyncEnabled: value,
    );

    await _userService.saveProfile(updated);
    setState(() {
      _userProfile = updated;
      _syncEnabled = value;
    });

    if (value) {
      setState(() => _isLoading = true);
      await _syncWithBrewfather();
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hefedatenbank'),
        actions: [
          Row(
             children: [
               const Text('Brewfather Sync'),
               Switch(
                 value: _syncEnabled, 
                 onChanged: _toggleSync,
                 activeThumbColor: Colors.blue,
               ),
             ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add),
              label: const Text('Neu'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text(
          'Konnte Hefen nicht laden:\n$_error',
          textAlign: TextAlign.center,
        ),
      );
    }
    if (_entries.isEmpty) {
      return const Center(
        child: Text('Noch keine Hefen eingetragen.'),
      );
    }
    return ListView.separated(
      itemCount: _entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = _entries[index];
        return Card(
          color: const Color(0xFF0F172A),
          child: ListTile(
            leading: (entry.brewfatherId != null && entry.brewfatherId!.isNotEmpty)
                ? Image.asset('assets/Brewfather_logo.png', width: 24, height: 24)
                : Image.asset('assets/icon_small.png', width: 24, height: 24),
            onTap: () => _openForm(editing: entry),
            title: Text('${entry.brand} · ${entry.strain}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((entry.style ?? '').isNotEmpty)
                  Text('Stil: ${entry.style}'),
                if (entry.attenuationMin != null ||
                    entry.attenuationMax != null)
                  Text(
                    'EVG: ${_rangeString(entry.attenuationMin, entry.attenuationMax, suffix: '%')}',
                  ),
                if (entry.temperatureMin != null ||
                    entry.temperatureMax != null)
                  Text(
                    'Temp: ${_rangeString(entry.temperatureMin, entry.temperatureMax, suffix: '°C')}',
                  ),
                if ((entry.url ?? '').isNotEmpty)
                  InkWell(
                    onTap: () async {
                       final uri = Uri.parse(entry.url!);
                       if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                       }
                    },
                    child: Text(
                      'URL: ${entry.url}',
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                if ((entry.notes ?? '').isNotEmpty)
                  Text(
                    entry.notes!,
                    style: const TextStyle(color: Colors.white70),
                  ),
                if (_debugJsonMap.containsKey(entry.strain)) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      border: Border.all(color: Colors.grey.shade800),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SelectableText(
                      'Brewfather Raw:\n${_debugJsonMap[entry.strain]}',
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: Colors.greenAccent),
                    ),
                  ),
                ],
              ],
            ),
            trailing: CardActions(
              onEdit: () => _openForm(editing: entry),
              onDelete: () => _confirmDelete(
                'Hefeeintrag “${entry.brand} · ${entry.strain}” löschen?',
                () => _deleteEntry(entry),
              ),
            ),
          ),
        );
      },
    );
  }

  double? _parseDouble(String value) {
     if (value.trim().isEmpty) return null;
     return double.tryParse(value.replaceAll(',', '.').trim());
  }

  String _rangeString(double? min, double? max, {String suffix = ''}) {
    if (min == null && max == null) return '–';
    if (min != null && max != null) {
      return '${min.toStringAsFixed(1)}–${max.toStringAsFixed(1)}$suffix';
    }
    final value = min ?? max!;
    return '${value.toStringAsFixed(1)}$suffix';
  }

  Future<void> _openForm({YeastBankEntry? editing}) async {
    final brandCtrl = TextEditingController(text: editing?.brand ?? '');
    final strainCtrl = TextEditingController(text: editing?.strain ?? '');
    final styleCtrl = TextEditingController(text: editing?.style ?? '');
    final urlCtrl = TextEditingController(text: editing?.url ?? '');
    final attenuationMinCtrl =
        TextEditingController(text: editing?.attenuationMin?.toString() ?? '');
    final attenuationMaxCtrl =
        TextEditingController(text: editing?.attenuationMax?.toString() ?? '');
    final tempMinCtrl =
        TextEditingController(text: editing?.temperatureMin?.toString() ?? '');
    final tempMaxCtrl =
        TextEditingController(text: editing?.temperatureMax?.toString() ?? '');
    final notesCtrl = TextEditingController(text: editing?.notes ?? '');
    
    // Initialize new controllers (try editing entry first, then fallback to debug map if needed, though usually editing is source of truth after sync)
    // We actually need access to the debug map here if we want to pre-fill for the FIRST time before DB has these columns populated.
    // However, _syncWithBrewfather should eventually populate the DB entry.
    // Let's rely on `editing` entry fields mostly, but if they are null and we have debug map, we might peek.
    // Actually, simpler: Initialize with empty string, and if editing is not null, use it.
    // Sync logic updates DB, so editing object should have data if synced.
    
    String initialProductId = editing?.productId ?? '';
    String initialForm = editing?.form ?? '';
    String initialInventory = editing?.inventory != null ? editing!.inventory.toString() : '';
    // Unit is usually part of inventory display string but stored separately. Let's assume unit is editable or fixed? 
    // User asked "Bestand: 1.2 pkg". In BF it's amount + unit.
    // We will make inventory a number field, and maybe add a unit field or keep unit as text.
    // Let's check what we added to DB: `unit TEXT`.
    String initialUnit = editing?.unit ?? '';
    
    // If empty and we have debug map (legacy case), try to fill?
    if (editing != null && (initialProductId.isEmpty || initialForm.isEmpty) && _debugJsonMap.containsKey(editing.strain)) {
       try {
         final data = jsonDecode(_debugJsonMap[editing.strain]!) as Map<String, dynamic>;
         if (initialProductId.isEmpty) initialProductId = data['productId']?.toString() ?? '';
         if (initialForm.isEmpty) initialForm = data['form']?.toString() ?? '';
         if (initialInventory.isEmpty && data['inventory'] != null) initialInventory = data['inventory'].toString();
         if (initialUnit.isEmpty && data['unit'] != null) initialUnit = data['unit'].toString();
       } catch (_) {}
    }

    final productIdCtrl = TextEditingController(text: initialProductId);
    final formCtrl = TextEditingController(text: initialForm);
    final inventoryCtrl = TextEditingController(text: initialInventory);
    final unitCtrl = TextEditingController(text: initialUnit);
    String? brandError;
    String? strainError;
    final isSynced = editing?.brewfatherId != null && editing!.brewfatherId!.isNotEmpty;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(editing == null ? 'Hefe hinzufügen' : 'Hefe bearbeiten'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                    
                    Column(
                      children: [
                        Tooltip(
                          message: isSynced
                              ? 'Dieses Feld erlaubt Brewfather nicht mutiert zu werden.'
                              : '',
                          child: TextField(
                            controller: brandCtrl,
                            readOnly: isSynced,
                            decoration: InputDecoration(
                              labelText: 'Marke',
                              errorText: brandError,
                              filled: isSynced,
                              fillColor: isSynced ? Colors.grey.withValues(alpha: 0.1) : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Tooltip(
                          message: isSynced
                              ? 'Dieses Feld erlaubt Brewfather nicht mutiert zu werden.'
                              : '',
                          child: TextField(
                            controller: productIdCtrl,
                            readOnly: isSynced,
                            decoration: InputDecoration(
                              labelText: 'Produkt ID',
                              filled: isSynced,
                              fillColor: isSynced ? Colors.grey.withValues(alpha: 0.1) : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Tooltip(
                          message: isSynced
                              ? 'Dieses Feld erlaubt Brewfather nicht mutiert zu werden.'
                              : '',
                          child: TextField(
                            controller: strainCtrl,
                            readOnly: isSynced,
                            decoration: InputDecoration(
                              labelText: 'Stamm',
                              errorText: strainError,
                              filled: isSynced,
                              fillColor: isSynced ? Colors.grey.withValues(alpha: 0.1) : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Tooltip(
                          message: isSynced
                              ? 'Dieses Feld erlaubt Brewfather nicht mutiert zu werden.'
                              : '',
                          child: TextField(
                            controller: styleCtrl,
                            readOnly: isSynced,
                            decoration: InputDecoration(
                              labelText: 'Stil / Verwendung',
                              filled: isSynced,
                              fillColor: isSynced ? Colors.grey.withValues(alpha: 0.1) : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Tooltip(
                          message: isSynced
                              ? 'Dieses Feld erlaubt Brewfather nicht mutiert zu werden.'
                              : '',
                          child: TextField(
                            controller: formCtrl,
                            readOnly: isSynced,
                            decoration: InputDecoration(
                              labelText: 'Form',
                              filled: isSynced,
                              fillColor: isSynced ? Colors.grey.withValues(alpha: 0.1) : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: urlCtrl,
                          decoration: const InputDecoration(
                            labelText: 'URL (lokal)',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Tooltip(
                                message: isSynced
                                    ? 'Dieses Feld erlaubt Brewfather nicht mutiert zu werden.'
                                    : '',
                                child: TextField(
                                  controller: attenuationMinCtrl,
                                  readOnly: isSynced,
                                  decoration: InputDecoration(
                                    labelText: 'EVG min %',
                                    filled: isSynced,
                                    fillColor: isSynced ? Colors.grey.withValues(alpha: 0.1) : null,
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(
                                      decimal: true),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Tooltip(
                                message: isSynced
                                    ? 'Dieses Feld erlaubt Brewfather nicht mutiert zu werden.'
                                    : '',
                                child: TextField(
                                  controller: attenuationMaxCtrl,
                                  readOnly: isSynced,
                                  decoration: InputDecoration(
                                    labelText: 'EVG max %',
                                    filled: isSynced,
                                    fillColor: isSynced ? Colors.grey.withValues(alpha: 0.1) : null,
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(
                                      decimal: true),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Tooltip(
                                message: isSynced
                                    ? 'Dieses Feld erlaubt Brewfather nicht mutiert zu werden.'
                                    : '',
                                child: TextField(
                                  controller: tempMinCtrl,
                                  readOnly: isSynced,
                                  decoration: InputDecoration(
                                    labelText: 'Temp. min (°C)',
                                    filled: isSynced,
                                    fillColor: isSynced ? Colors.grey.withValues(alpha: 0.1) : null,
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(
                                      decimal: true),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Tooltip(
                                message: isSynced
                                    ? 'Dieses Feld erlaubt Brewfather nicht mutiert zu werden.'
                                    : '',
                                child: TextField(
                                  controller: tempMaxCtrl,
                                  readOnly: isSynced,
                                  decoration: InputDecoration(
                                    labelText: 'Temp. max (°C)',
                                    filled: isSynced,
                                    fillColor: isSynced ? Colors.grey.withValues(alpha: 0.1) : null,
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(
                                      decimal: true),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: inventoryCtrl,
                                // Inventory is editable!
                                decoration: const InputDecoration(
                                  labelText: 'Bestand',
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: Tooltip(
                                message: isSynced
                                    ? 'Dieses Feld erlaubt Brewfather nicht mutiert zu werden.'
                                    : '',
                                child: TextField(
                                  controller: unitCtrl,
                                  readOnly: isSynced,
                                  decoration: InputDecoration(
                                    labelText: 'Einheit',
                                    filled: isSynced,
                                    fillColor: isSynced ? Colors.grey.withValues(alpha: 0.1) : null,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Tooltip(
                          message: isSynced
                              ? 'Dieses Feld erlaubt Brewfather nicht mutiert zu werden.'
                              : '',
                          child: TextField(
                            controller: notesCtrl,
                            readOnly: isSynced,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Notizen',
                              filled: isSynced,
                              fillColor: isSynced ? Colors.grey.withValues(alpha: 0.1) : null,
                            ),
                          ),
                        ),
                      ],
                    ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                if (brandCtrl.text.trim().isEmpty) {
                  setState(() => brandError = 'Pflichtfeld');
                  return;
                }
                if (strainCtrl.text.trim().isEmpty) {
                  setState(() => strainError = 'Pflichtfeld');
                  return;
                }
                Navigator.of(dialogCtx).pop(true);
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    final entry = YeastBankEntry(
      id: editing?.id,
      userProfileId: widget.profileId,
      brewfatherId: editing?.brewfatherId,
      brand: brandCtrl.text.trim(),
      strain: strainCtrl.text.trim(),
      productId: productIdCtrl.text.trim().isEmpty ? null : productIdCtrl.text.trim(),
      form: formCtrl.text.trim().isEmpty ? null : formCtrl.text.trim(),
      inventory: _parseDouble(inventoryCtrl.text),
      unit: unitCtrl.text.trim().isEmpty ? null : unitCtrl.text.trim(),
      style: styleCtrl.text.trim().isEmpty ? null : styleCtrl.text.trim(),
      url: urlCtrl.text.trim().isEmpty ? null : urlCtrl.text.trim(),
      attenuationMin: _parseDouble(attenuationMinCtrl.text),
      attenuationMax: _parseDouble(attenuationMaxCtrl.text),
      temperatureMin: _parseDouble(tempMinCtrl.text),
      temperatureMax: _parseDouble(tempMaxCtrl.text),
      notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
    );

    try {
      final saved = await _service.saveEntry(entry);
      
      // Sync logic based on user request: Update only if source is Brewfather (has ID), else Popup.
      if (_syncEnabled && _userProfile?.brewfatherUserId != null && _userProfile?.brewfatherApiKey != null) {
          if (saved.brewfatherId != null) {
              // Update existing Brewfather entry
              try {
                final bfService = BrewfatherService(userId: _userProfile!.brewfatherUserId!, apiKey: _userProfile!.brewfatherApiKey!);
                await bfService.updateInventoryYeast(saved.brewfatherId!, {
                   'name': saved.strain,
                   'lab': saved.brand,
                   'type': saved.style ?? 'Ale',
                   'attenuation': saved.attenuationMax ?? 75,
                   'minTemp': saved.temperatureMin ?? 18,
                   'maxTemp': saved.temperatureMax ?? 23,
                   'description': saved.notes ?? '',
                   'productId': saved.productId,
                   'form': saved.form,
                   'inventory': saved.inventory,
                   // Unit is seemingly not always updateable or depends on field? 
                   // Brewfather API might respect 'unit' in body.
                   'unit': saved.unit,
                });
                 if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update an Brewfather gesendet.')));
                 }
              } catch(e) {
                 debugPrint('Error updating Brewfather: $e');
                 if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Warnung: Brewfather Update fehlgeschlagen: $e')));
                 }
              }
          } else {
             // New/Local entry -> PopUp
             if (mounted) {
                 showDialog(
                   context: context,
                   builder: (ctx) => AlertDialog(
                     title: const Text('Brewfather Info'),
                     content: const Text('Eintrag wurde lokal gespeichert.\nDas Hinzufügen neuer Einträge wird von Brewfather nicht unterstützt.'),
                     actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                   ),
                 );
             }
          }
      }

      if (!mounted) return;
      setState(() {
        final index = _entries.indexWhere((element) => element.id == saved.id);
        if (index >= 0) {
          _entries[index] = saved;
        } else {
          _entries.add(saved);
        }
        _entries.sort(
          (a, b) => '${a.brand} ${a.strain}'
              .toLowerCase()
              .compareTo('${b.brand} ${b.strain}'.toLowerCase()),
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              editing == null ? 'Hefe gespeichert' : 'Hefe aktualisiert',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speichern fehlgeschlagen: $e')),
      );
    }
  }



  Future<void> _deleteEntry(YeastBankEntry entry) async {
    if (entry.id == null) return;
    try {
      await _service.deleteEntry(entry.id!);
      setState(() {
        _entries.removeWhere((item) => item.id == entry.id);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hefe "${entry.brand} · ${entry.strain}" gelöscht'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Löschen fehlgeschlagen: $e')));
    }
  }

  Future<void> _confirmDelete(
    String title,
    Future<void> Function() onDelete,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content:
            const Text('Dieser Vorgang kann nicht rückgängig gemacht werden.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await onDelete();
    }
  }
}

class _UserNameBanner extends StatefulWidget {
  const _UserNameBanner();

  @override
  State<_UserNameBanner> createState() => _UserNameBannerState();
}

class _UserNameBannerState extends State<_UserNameBanner> {
  late final Future<UserProfile?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = UserProfileService().fetchDefaultProfile();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        Widget child;
        if (snapshot.connectionState == ConnectionState.waiting) {
          child = const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        } else if (snapshot.hasError) {
          child = const Text(
            'User lädt nicht',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          );
        } else {
          final name = snapshot.data?.name.trim();
          child = Text(
            name?.isNotEmpty == true ? name! : 'User',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          );
        }
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person, size: 18, color: Colors.white70),
                const SizedBox(width: 8),
                child,
              ],
            ),
          ),
        );
      },
    );
  }
}

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
  AiRecipe? _lastGeneratedRecipe; // NEW: Store the parsed recipe object

  @override
  void initState() {
    super.initState();
    _promptController.addListener(() {
      // Clear generated prompt when user types new input? 
      // User didn't specify, but maybe safer to keep for reference or clear.
      // Let's keep it simple for now and not clear it.
    });
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

      // --- 1. Fetch Packaging Profile & Calculate Volumes ---
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

  Future<void> _openHomepage() async {
    final uri = Uri.parse('https://alexstuder.ch/');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konnte Hauptseite nicht öffnen.')),
      );
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
                      child: _UserNameBanner(),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Image.asset(
                        'assets/icon_small.png',
                        height: 98, // Exactly half of 196px for crisp 2x scaling
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
                      onChanged: (text) {
                        if (_error != null && text.trim().isNotEmpty) {
                          setState(() => _error = null);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _isLoading ? null : _pickImage,
                          icon: const Icon(Icons.add_a_photo_outlined),
                          label: const Text('Foto anhängen'),
                        ),
                        if (_imageBytes != null) ...[
                          const SizedBox(width: 12),
                          TextButton.icon(
                            onPressed: _isLoading ? null : _clearImage,
                            icon: const Icon(Icons.close),
                            label: const Text('Foto entfernen'),
                          ),
                        ],
                      ],
                    ),
                    if (_imageBytes != null) ...[
                      const SizedBox(height: 12),
                      _ImagePreview(
                        bytes: _imageBytes!,
                        fileName: _imageName,
                        isWide: isWide,
                      ),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _requestRecipe,
                        icon: const Icon(Icons.local_drink),
                        label: Text(
                          _isLoading ? 'Braut Rezept …' : 'Rezept erstellen',
                        ),
                      ),
                    ),
                    if (_lastGeneratedRecipe != null) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                             Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RecipeResultPage(recipe: _lastGeneratedRecipe!),
                              ),
                            );
                          },
                          icon: const Icon(Icons.receipt),
                          label: const Text('Letztes Rezept öffnen'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.amberAccent,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _openHomepage,
                        icon: const Icon(Icons.home),
                        label: const Text('Zur Hauptseite'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_lastGeneratedPrompt != null)
                      Card(
                        color: const Color(0xFF0F172A),
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Generierter Prompt:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(12),
                                height: 200,
                                child: SingleChildScrollView(
                                  child: SelectableText(
                                      _lastGeneratedPrompt!,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ),
                              SelectableText(
                                _lastGeneratedPrompt != null && _lastGeneratedPrompt!.contains('Original_Malz')
                                    ? 'Template enthält "Original_Malz" -> OK'
                                    : 'WARNUNG: Template scheint "Original_Malz" NICHT zu enthalten!',
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_response != null) ...[
                      const Text(
                        'Antwort aus ChatGPT:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: SelectableText(
                          _response!,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_response != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ElevatedButton.icon(
                          onPressed: _isLoading || _isSearchingShops
                              ? null
                              : _searchShopsForIngredients,
                          icon: _isSearchingShops
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.shopping_cart_outlined),
                          label: Text(
                            _isSearchingShops
                                ? 'Durchsuche Shops …'
                                : 'Im Shop suchen',
                          ),
                        ),
                      ),
                    if (_response != null) const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading || _isSearchingShops)
            _LoadingOverlay(
              message: _isLoading
                  ? 'Rezept wird erstellt …'
                  : 'Shops werden durchsucht …',
            ),
        ],
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({
    required this.bytes,
    required this.isWide,
    this.fileName,
  });

  final Uint8List bytes;
  final bool isWide;
  final String? fileName;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF0F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : MediaQuery.of(context).size.width;
                final ratio = isWide ? 16 / 9 : 4 / 3;
                final double targetHeight =
                    math.min(availableWidth / ratio, isWide ? 360 : 280);
                return SizedBox(
                  height: targetHeight,
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.none,
                  ),
                );



              },
            ),
          ),
          if ((fileName ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                fileName!,
                style: const TextStyle(fontSize: 13, color: Colors.white70),
                overflow: TextOverflow.ellipsis,
              ),
            ),
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






class _EntryButton extends StatelessWidget {
  const _EntryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360, minWidth: 260),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}

class FineTuningProfile {
  FineTuningProfile({required this.beerName, required this.beerType});

  final String beerName;
  final String beerType;
  double mouthfeel = 0.0;
  double antrunkMalt = 0.0;
  double antrunkRoast = 0.0;
  double smooth = 0.0;
  double fullBody = 0.0;
  double mainMalt = 0.0;
  double mainRoast = 0.0;
  double fade = 0.0;
  double fresh = 0.0;
  double dry = 0.0;
  double lasting = 0.0;
  double hopIntensity = 0.0;
  double hopHerbal = 0.0;
  double hopFloral = 0.0;
  double hopFruity = 0.0;
  double hopNose = 0.0;
  double hopPalate = 0.0;
  double hopFinish = 0.0;
  final List<SpecialAddition> specialAdditions = [];
  final List<String> specialStorage = [];

  final Map<String, double> _baseline = {};

  void applyPreset(Map<String, double> preset) {
    _baseline
      ..clear()
      ..addAll(preset);
    hopIntensity = preset['hopIntensity'] ?? hopIntensity;
    hopHerbal = preset['hopHerbal'] ?? hopHerbal;
    hopFloral = preset['hopFloral'] ?? hopFloral;
    hopFruity = preset['hopFruity'] ?? hopFruity;
    hopNose = preset['hopNose'] ?? hopNose;
    hopPalate = preset['hopPalate'] ?? hopPalate;
    hopFinish = preset['hopFinish'] ?? hopFinish;
    mouthfeel = preset['mouthfeel'] ?? mouthfeel;
    antrunkMalt = preset['antrunkMalt'] ?? antrunkMalt;
    antrunkRoast = preset['antrunkRoast'] ?? antrunkRoast;
    smooth = preset['smooth'] ?? smooth;
    fullBody = preset['fullBody'] ?? fullBody;
    mainMalt = preset['mainMalt'] ?? mainMalt;
    mainRoast = preset['mainRoast'] ?? mainRoast;
    fade = preset['fade'] ?? fade;
    fresh = preset['fresh'] ?? fresh;
    dry = preset['dry'] ?? dry;
    lasting = preset['lasting'] ?? lasting;
  }

  double diff(String key, double current) {
    final base = _baseline[key];
    if (base == null) return 0.0;
    return current - base;
  }
}

class SpecialAddition {
  SpecialAddition({
    required this.title,
    required this.focus,
    required this.intensity,
  });

  final String title;
  final double focus;
  final double intensity;
}

String describeAdditionFocus(double value) {
  if (value <= 0.2) return 'Antrunk';
  if (value >= 0.8) return 'Abgang';
  if (value < 0.5) return 'Zwischenphase (Richtung Antrunk)';
  if (value > 0.5) return 'Zwischenphase (Richtung Abgang)';
  return 'Zwischenphase';
}

const Map<String, Map<String, double>> _beerPresets = {
  'Porter': {
    'hopIntensity': 0.65,
    'hopHerbal': 0.20,
    'hopFloral': 0.10,
    'hopFruity': 0.25,
    'hopNose': 0.30,
    'hopPalate': 0.40,
    'hopFinish': 0.30,
    'mouthfeel': 0.40,
    'antrunkMalt': 0.50,
    'antrunkRoast': 0.80,
    'smooth': 0.45,
    'fullBody': 0.70,
    'mainMalt': 0.60,
    'mainRoast': 0.70,
    'fade': 0.40,
    'fresh': 0.30,
    'dry': 0.55,
    'lasting': 0.60,
  },
  'Stout': {
    'hopIntensity': 0.70,
    'hopHerbal': 0.15,
    'hopFloral': 0.05,
    'hopFruity': 0.15,
    'hopNose': 0.35,
    'hopPalate': 0.45,
    'hopFinish': 0.20,
    'mouthfeel': 0.30,
    'antrunkMalt': 0.40,
    'antrunkRoast': 0.90,
    'smooth': 0.40,
    'fullBody': 0.75,
    'mainMalt': 0.55,
    'mainRoast': 0.80,
    'fade': 0.35,
    'fresh': 0.25,
    'dry': 0.60,
    'lasting': 0.65,
  },
  'Pale Ale': {
    'hopIntensity': 0.65,
    'hopHerbal': 0.25,
    'hopFloral': 0.15,
    'hopFruity': 0.45,
    'hopNose': 0.45,
    'hopPalate': 0.50,
    'hopFinish': 0.40,
    'mouthfeel': 0.50,
    'antrunkMalt': 0.40,
    'antrunkRoast': 0.20,
    'smooth': 0.50,
    'fullBody': 0.45,
    'mainMalt': 0.30,
    'mainRoast': 0.20,
    'fade': 0.45,
    'fresh': 0.40,
    'dry': 0.30,
    'lasting': 0.35,
  },
  'IPA': {
    'hopIntensity': 0.85,
    'hopHerbal': 0.35,
    'hopFloral': 0.30,
    'hopFruity': 0.65,
    'hopNose': 0.60,
    'hopPalate': 0.70,
    'hopFinish': 0.50,
    'mouthfeel': 0.55,
    'antrunkMalt': 0.35,
    'antrunkRoast': 0.15,
    'smooth': 0.55,
    'fullBody': 0.40,
    'mainMalt': 0.30,
    'mainRoast': 0.15,
    'fade': 0.50,
    'fresh': 0.45,
    'dry': 0.35,
    'lasting': 0.40,
  },
  'Weizen': {
    'hopIntensity': 0.40,
    'hopHerbal': 0.10,
    'hopFloral': 0.15,
    'hopFruity': 0.55,
    'hopNose': 0.40,
    'hopPalate': 0.45,
    'hopFinish': 0.25,
    'mouthfeel': 0.50,
    'antrunkMalt': 0.40,
    'antrunkRoast': 0.10,
    'smooth': 0.55,
    'fullBody': 0.20,
    'mainMalt': 0.20,
    'mainRoast': 0.10,
    'fade': 0.40,
    'fresh': 0.60,
    'dry': 0.20,
    'lasting': 0.25,
  },
  'Belgian': {
    'hopIntensity': 0.70,
    'hopHerbal': 0.15,
    'hopFloral': 0.20,
    'hopFruity': 0.60,
    'hopNose': 0.50,
    'hopPalate': 0.55,
    'hopFinish': 0.40,
    'mouthfeel': 0.60,
    'antrunkMalt': 0.40,
    'antrunkRoast': 0.25,
    'smooth': 0.60,
    'fullBody': 0.45,
    'mainMalt': 0.40,
    'mainRoast': 0.25,
    'fade': 0.45,
    'fresh': 0.50,
    'dry': 0.35,
    'lasting': 0.40,
  },
  'Pale Lager': {
    'hopIntensity': 0.55,
    'hopHerbal': 0.20,
    'hopFloral': 0.10,
    'hopFruity': 0.30,
    'hopNose': 0.35,
    'hopPalate': 0.40,
    'hopFinish': 0.30,
    'mouthfeel': 0.55,
    'antrunkMalt': 0.30,
    'antrunkRoast': 0.10,
    'smooth': 0.60,
    'fullBody': 0.30,
    'mainMalt': 0.20,
    'mainRoast': 0.15,
    'fade': 0.40,
    'fresh': 0.55,
    'dry': 0.40,
    'lasting': 0.45,
  },
  'Schwarzbier': {
    'hopIntensity': 0.60,
    'hopHerbal': 0.15,
    'hopFloral': 0.05,
    'hopFruity': 0.15,
    'hopNose': 0.30,
    'hopPalate': 0.40,
    'hopFinish': 0.25,
    'mouthfeel': 0.50,
    'antrunkMalt': 0.45,
    'antrunkRoast': 0.70,
    'smooth': 0.50,
    'fullBody': 0.65,
    'mainMalt': 0.55,
    'mainRoast': 0.75,
    'fade': 0.35,
    'fresh': 0.25,
    'dry': 0.55,
    'lasting': 0.60,
  },
  'Märzen': {
    'hopIntensity': 0.45,
    'hopHerbal': 0.10,
    'hopFloral': 0.10,
    'hopFruity': 0.20,
    'hopNose': 0.30,
    'hopPalate': 0.35,
    'hopFinish': 0.25,
    'mouthfeel': 0.60,
    'antrunkMalt': 0.60,
    'antrunkRoast': 0.65,
    'smooth': 0.55,
    'fullBody': 0.70,
    'mainMalt': 0.60,
    'mainRoast': 0.70,
    'fade': 0.35,
    'fresh': 0.30,
    'dry': 0.50,
    'lasting': 0.55,
  },
  'Bock': {
    'hopIntensity': 0.50,
    'hopHerbal': 0.10,
    'hopFloral': 0.10,
    'hopFruity': 0.18,
    'hopNose': 0.25,
    'hopPalate': 0.40,
    'hopFinish': 0.25,
    'mouthfeel': 0.65,
    'antrunkMalt': 0.70,
    'antrunkRoast': 0.50,
    'smooth': 0.55,
    'fullBody': 0.60,
    'mainMalt': 0.55,
    'mainRoast': 0.60,
    'fade': 0.30,
    'fresh': 0.25,
    'dry': 0.45,
    'lasting': 0.50,
  },
};

class _BeerGroup extends StatelessWidget {
  const _BeerGroup({
    required this.title,
    required this.beers,
    required this.selected,
    required this.onSelected,
  });

  final String title;
  final List<String> beers;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: beers
              .map(
                (beer) => _BeerChoice(
                  label: beer,
                  groupValue: selected,
                  onTap: () => onSelected(beer),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _BeerChoice extends StatelessWidget {
  const _BeerChoice({
    required this.label,
    required this.groupValue,
    required this.onTap,
  });

  final String label;
  final String? groupValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isSelected = groupValue == label;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : Colors.white24,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? const Color(0xFF2563EB) : Colors.white54,
            ),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FineTuningGeneralPage extends StatefulWidget {
  const FineTuningGeneralPage(
      {super.key, required this.beerName, required this.beerType});

  final String beerName;
  final String beerType;

  @override
  State<FineTuningGeneralPage> createState() => _FineTuningGeneralPageState();
}

class _FineTuningGeneralPageState extends State<FineTuningGeneralPage> {
  late final FineTuningProfile profile;

  @override
  void initState() {
    super.initState();
    profile =
        FineTuningProfile(beerName: widget.beerName, beerType: widget.beerType);
    final preset = _beerPresets[widget.beerName];
    if (preset != null) {
      profile.applyPreset(preset);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feintuning Generell'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Image.asset(
              'assets/icon_small.png',
              height: 40,
              filterQuality: FilterQuality.none,
              semanticLabel: 'AiBrewGenius',
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _UserNameBanner(),
              const SizedBox(height: 20),
              Text(
                'Erste Anpassungen für ${profile.beerName}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Hopfen',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _IndentedBlock(
                child: Column(
                  children: [
                    _SliderBlock(
                      label: 'Aromaintensität',
                      minLabel: 'wenig',
                      maxLabel: 'stark',
                      value: profile.hopIntensity,
                      baselineKey: 'hopIntensity',
                    ),
                    _FineSlider(
                      value: profile.hopIntensity,
                      onChanged: (v) =>
                          setState(() => profile.hopIntensity = v),
                      baselineKey: 'hopIntensity',
                    ),
                    const SizedBox(height: 12),
                    _SliderBlock(
                      label: 'Kräuterig',
                      minLabel: 'wenig',
                      maxLabel: 'stark',
                      value: profile.hopHerbal,
                      baselineKey: 'hopHerbal',
                    ),
                    _FineSlider(
                      value: profile.hopHerbal,
                      onChanged: (v) => setState(() => profile.hopHerbal = v),
                      baselineKey: 'hopHerbal',
                    ),
                    const SizedBox(height: 12),
                    _SliderBlock(
                      label: 'Blumig',
                      minLabel: 'wenig',
                      maxLabel: 'stark',
                      value: profile.hopFloral,
                      baselineKey: 'hopFloral',
                    ),
                    _FineSlider(
                      value: profile.hopFloral,
                      onChanged: (v) => setState(() => profile.hopFloral = v),
                      baselineKey: 'hopFloral',
                    ),
                    const SizedBox(height: 12),
                    _SliderBlock(
                      label: 'Fruchtig',
                      minLabel: 'wenig',
                      maxLabel: 'stark',
                      value: profile.hopFruity,
                      baselineKey: 'hopFruity',
                    ),
                    _FineSlider(
                      value: profile.hopFruity,
                      onChanged: (v) => setState(() => profile.hopFruity = v),
                      baselineKey: 'hopFruity',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Verteilung',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _IndentedBlock(
                child: Column(
                  children: [
                    _SliderBlock(
                      label: 'Nase',
                      minLabel: 'wenig',
                      maxLabel: 'stark',
                      value: profile.hopNose,
                      baselineKey: 'hopNose',
                    ),
                    _FineSlider(
                      value: profile.hopNose,
                      onChanged: (v) => setState(() => profile.hopNose = v),
                      baselineKey: 'hopNose',
                    ),
                    const SizedBox(height: 12),
                    _SliderBlock(
                      label: 'Gaumen',
                      minLabel: 'wenig',
                      maxLabel: 'stark',
                      value: profile.hopPalate,
                      baselineKey: 'hopPalate',
                    ),
                    _FineSlider(
                      value: profile.hopPalate,
                      onChanged: (v) => setState(() => profile.hopPalate = v),
                      baselineKey: 'hopPalate',
                    ),
                    const SizedBox(height: 12),
                    _SliderBlock(
                      label: 'Abgang',
                      minLabel: 'wenig',
                      maxLabel: 'stark',
                      value: profile.hopFinish,
                      baselineKey: 'hopFinish',
                    ),
                    _FineSlider(
                      value: profile.hopFinish,
                      onChanged: (v) => setState(() => profile.hopFinish = v),
                      baselineKey: 'hopFinish',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => FineTuningPage(profile: profile),
                      ),
                    );
                  },
                  child: const Text('Weiter zu Feintuning Antrunk'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class FineTuningPage extends StatefulWidget {
  const FineTuningPage({super.key, required this.profile});

  final FineTuningProfile profile;

  @override
  State<FineTuningPage> createState() => _FineTuningPageState();
}

class _FineTuningPageState extends State<FineTuningPage> {
  FineTuningProfile get profile => widget.profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feintuning Antrunk'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Image.asset(
              'assets/icon_small.png',
              height: 40,
              filterQuality: FilterQuality.none,
              semanticLabel: 'AiBrewGenius',
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: _UserNameBanner(),
            ),
            const SizedBox(height: 20),
            Text(
              'Lass uns ein neues leckeres und einzigartiges ${profile.beerName} Bier entwerfen',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _SliderBlock(
              label: 'Mundgefühl',
              minLabel: 'Wasser',
              maxLabel: 'Motorenöl',
              value: profile.mouthfeel,
              baselineKey: 'mouthfeel',
            ),
            _FineSlider(
              value: profile.mouthfeel,
              onChanged: (v) => setState(() => profile.mouthfeel = v),
              baselineKey: 'mouthfeel',
            ),
            const SizedBox(height: 12),
            _SliderBlock(
              label: 'Malzaroma',
              minLabel: 'leicht',
              maxLabel: 'kräftig',
              value: profile.antrunkMalt,
              baselineKey: 'antrunkMalt',
            ),
            _FineSlider(
              value: profile.antrunkMalt,
              onChanged: (v) => setState(() => profile.antrunkMalt = v),
              baselineKey: 'antrunkMalt',
            ),
            const SizedBox(height: 12),
            _SliderBlock(
              label: 'Röstmalzaroma',
              minLabel: 'leicht',
              maxLabel: 'kräftig',
              value: profile.antrunkRoast,
              baselineKey: 'antrunkRoast',
            ),
            _FineSlider(
              value: profile.antrunkRoast,
              onChanged: (v) => setState(() => profile.antrunkRoast = v),
              baselineKey: 'antrunkRoast',
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FineTuningMainTrunkPage(profile: profile),
                    ),
                  );
                },
                child: const Text('Weiter zu Feintuning Haupttrunk'),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class FineTuningMainTrunkPage extends StatefulWidget {
  const FineTuningMainTrunkPage({super.key, required this.profile});

  final FineTuningProfile profile;

  @override
  State<FineTuningMainTrunkPage> createState() =>
      _FineTuningMainTrunkPageState();
}

class _FineTuningMainTrunkPageState extends State<FineTuningMainTrunkPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feintuning Haupttrunk'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Image.asset(
              'assets/icon_small.png',
              height: 40,
              filterQuality: FilterQuality.none,
              semanticLabel: 'AiBrewGenius',
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _UserNameBanner(),
                const SizedBox(height: 20),
                Text(
                  'Feintuning für ${widget.profile.beerName} · Haupttrunk',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                _SliderBlock(
                  label: 'süffig',
                  minLabel: 'leicht',
                  maxLabel: 'kräftig',
                  value: widget.profile.smooth,
                  baselineKey: 'smooth',
                ),
                _FineSlider(
                  value: widget.profile.smooth,
                  onChanged: (v) => setState(() => widget.profile.smooth = v),
                  baselineKey: 'smooth',
                ),
                const SizedBox(height: 12),
                _SliderBlock(
                  label: 'vollmundig',
                  minLabel: 'leicht',
                  maxLabel: 'kräftig',
                  value: widget.profile.fullBody,
                  baselineKey: 'fullBody',
                ),
                _FineSlider(
                  value: widget.profile.fullBody,
                  onChanged: (v) => setState(() => widget.profile.fullBody = v),
                  baselineKey: 'fullBody',
                ),
                const SizedBox(height: 12),
                _SliderBlock(
                  label: 'Malzaroma',
                  minLabel: 'leicht',
                  maxLabel: 'kräftig',
                  value: widget.profile.mainMalt,
                  baselineKey: 'mainMalt',
                ),
                _FineSlider(
                  value: widget.profile.mainMalt,
                  onChanged: (v) => setState(() => widget.profile.mainMalt = v),
                  baselineKey: 'mainMalt',
                ),
                const SizedBox(height: 12),
                _SliderBlock(
                  label: 'Röstaroma',
                  minLabel: 'leicht',
                  maxLabel: 'kräftig',
                  value: widget.profile.mainRoast,
                  baselineKey: 'mainRoast',
                ),
                _FineSlider(
                  value: widget.profile.mainRoast,
                  onChanged: (v) =>
                      setState(() => widget.profile.mainRoast = v),
                  baselineKey: 'mainRoast',
                ),
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.bottomRight,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              FineTuningAftertastePage(profile: widget.profile),
                        ),
                      );
                    },
                    child: const Text('Weiter zu Feintuning Nachtrunk'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FineTuningAftertastePage extends StatefulWidget {
  const FineTuningAftertastePage({super.key, required this.profile});

  final FineTuningProfile profile;

  @override
  State<FineTuningAftertastePage> createState() =>
      _FineTuningAftertastePageState();
}

class _FineTuningAftertastePageState extends State<FineTuningAftertastePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feintuning Nachtrunk'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Image.asset(
              'assets/icon_small.png',
              height: 40,
              filterQuality: FilterQuality.none,
              semanticLabel: 'AiBrewGenius',
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _UserNameBanner(),
                const SizedBox(height: 20),
                Text(
                  'Feintuning für ${widget.profile.beerName} · Nachtrunk',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                _SliderBlock(
                  label: 'abklingen',
                  minLabel: 'leicht',
                  maxLabel: 'kräftig',
                  value: widget.profile.fade,
                  baselineKey: 'fade',
                ),
                _FineSlider(
                  value: widget.profile.fade,
                  onChanged: (v) => setState(() => widget.profile.fade = v),
                  baselineKey: 'fade',
                ),
                const SizedBox(height: 12),
                _SliderBlock(
                  label: 'erfrischend',
                  minLabel: 'leicht',
                  maxLabel: 'kräftig',
                  value: widget.profile.fresh,
                  baselineKey: 'fresh',
                ),
                _FineSlider(
                  value: widget.profile.fresh,
                  onChanged: (v) => setState(() => widget.profile.fresh = v),
                  baselineKey: 'fresh',
                ),
                const SizedBox(height: 12),
                _SliderBlock(
                  label: 'trocken',
                  minLabel: 'leicht',
                  maxLabel: 'kräftig',
                  value: widget.profile.dry,
                  baselineKey: 'dry',
                ),
                _FineSlider(
                  value: widget.profile.dry,
                  onChanged: (v) => setState(() => widget.profile.dry = v),
                  baselineKey: 'dry',
                ),
                const SizedBox(height: 12),
                _SliderBlock(
                  label: 'langanhaltend',
                  minLabel: 'leicht',
                  maxLabel: 'kräftig',
                  value: widget.profile.lasting,
                  baselineKey: 'lasting',
                ),
                _FineSlider(
                  value: widget.profile.lasting,
                  onChanged: (v) => setState(() => widget.profile.lasting = v),
                  baselineKey: 'lasting',
                ),
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.bottomRight,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SpecialAdditionsPage(
                            profile: widget.profile,
                          ),
                        ),
                      );
                    },
                    child: const Text('Spezielle Zugaben festlegen'),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SpecialAdditionsPage extends StatefulWidget {
  const SpecialAdditionsPage({super.key, required this.profile});

  final FineTuningProfile profile;

  @override
  State<SpecialAdditionsPage> createState() => _SpecialAdditionsPageState();
}

class _SpecialAdditionsPageState extends State<SpecialAdditionsPage> {
  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController storageCtrl = TextEditingController();
  double focusValue = 0.5;
  double intensityValue = 0.5;
  String? titleError;
  String? storageError;

  @override
  void dispose() {
    titleCtrl.dispose();
    storageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spezielle Zugaben'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Image.asset(
              'assets/icon_small.png',
              height: 40,
              filterQuality: FilterQuality.none,
              semanticLabel: 'AiBrewGenius',
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _UserNameBanner(),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  Text(
                    'Füge deinem Bier besondere Schritte wie Barrel Aging, Holzchips oder Speziallagerungen hinzu.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bisherige Zugaben',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  if (widget.profile.specialAdditions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Text(
                        'Noch keine speziellen Zugaben definiert.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  else
                    Column(
                      children: [
                        ...widget.profile.specialAdditions.asMap().entries.map(
                          (entry) {
                            final addition = entry.value;
                            final antrunkPercent =
                                ((1 - addition.focus) * 100).round();
                            final abgangPercent = 100 - antrunkPercent;
                            final intensityPercent =
                                (addition.intensity * 100).round();
                            return Card(
                              color: const Color(0xFF0F172A),
                              child: ListTile(
                                title: Text(addition.title),
                                subtitle: Text(
                                  'Antrunk $antrunkPercent% · Abgang $abgangPercent% · Intensität $intensityPercent%',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => removeAddition(entry.key),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  Text(
                    'Neue Zugabe hinzufügen',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Bezeichnung',
                      hintText: 'z. B. Rumfass Lagerung',
                      errorText: titleError,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 12),
                  _FocusSlider(
                    value: focusValue,
                    onChanged: (v) => setState(() => focusValue = v),
                  ),
                  const SizedBox(height: 12),
                  _IntensitySlider(
                    value: intensityValue,
                    onChanged: (v) => setState(() => intensityValue = v),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: addAddition,
                      icon: const Icon(Icons.add),
                      label: const Text('Hinzufügen'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(
                    height: 32,
                    thickness: 1,
                    color: Colors.white24,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Spezielle Lagerung',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  if (widget.profile.specialStorage.isEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Text(
                        'Noch keine Lagerungsarten definiert.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  else
                    Column(
                      children: [
                        ...widget.profile.specialStorage.asMap().entries.map(
                              (entry) => Card(
                                color: const Color(0xFF0F172A),
                                child: ListTile(
                                  title: Text(entry.value),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => removeStorage(entry.key),
                                  ),
                                ),
                              ),
                            ),
                      ],
                    ),
                  TextField(
                    controller: storageCtrl,
                    decoration: InputDecoration(
                      labelText: 'z. B. Barrel Aged',
                      errorText: storageError,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: addStorage,
                      icon: const Icon(Icons.add),
                      label: const Text('Lagerung hinzufügen'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: goToSummary,
                  child: const Text('Überspringen'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: goToSummary,
                  child: const Text('Weiter zum Rezept'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void addAddition() {
    final title = titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => titleError = 'Bezeichnung erforderlich');
      return;
    }
    setState(() {
      titleError = null;
      widget.profile.specialAdditions.add(
        SpecialAddition(
          title: title,
          focus: focusValue,
          intensity: intensityValue,
        ),
      );
      titleCtrl.clear();
      focusValue = 0.5;
      intensityValue = 0.5;
    });
  }

  void removeAddition(int index) {
    setState(() {
      widget.profile.specialAdditions.removeAt(index);
    });
  }

  void addStorage() {
    final entry = storageCtrl.text.trim();
    if (entry.isEmpty) {
      setState(() => storageError = 'Bitte eine Lagerung eingeben');
      return;
    }
    setState(() {
      storageError = null;
      widget.profile.specialStorage.add(entry);
      storageCtrl.clear();
    });
  }

  void removeStorage(int index) {
    setState(() {
      widget.profile.specialStorage.removeAt(index);
    });
  }

  void goToSummary() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecipeSummaryPage(profile: widget.profile),
      ),
    );
  }
}

class _FocusSlider extends StatelessWidget {
  const _FocusSlider({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final antrunkPercent = ((1 - value) * 100).round();
    final abgangPercent = 100 - antrunkPercent;
    final sliderTheme = SliderTheme.of(context).copyWith(
      activeTrackColor: Colors.white60,
      inactiveTrackColor: Colors.white24,
      thumbColor: Colors.white,
      overlayColor: Colors.white10,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _SliderLabel(title: 'Antrunk', percent: antrunkPercent),
            Expanded(
              child: SliderTheme(
                data: sliderTheme,
                child: Slider(
                  value: value,
                  onChanged: onChanged,
                ),
              ),
            ),
            _SliderLabel(title: 'Abgang', percent: abgangPercent),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            describeAdditionFocus(value),
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
        ),
      ],
    );
  }
}

class _IntensitySlider extends StatelessWidget {
  const _IntensitySlider({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Intensität'),
            const SizedBox(width: 8),
            Text('$percent%'),
          ],
        ),
        Slider(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SliderLabel extends StatelessWidget {
  const _SliderLabel({required this.title, required this.percent});

  final String title;
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title),
        Text(
          '$percent%',
          style: const TextStyle(fontSize: 13, color: Colors.white70),
        ),
      ],
    );
  }
}

class RecipeSummaryPage extends StatelessWidget {
  const RecipeSummaryPage({super.key, required this.profile});

  final FineTuningProfile profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rezept'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Image.asset(
              'assets/icon_small.png',
              height: 40,
              filterQuality: FilterQuality.none,
              semanticLabel: 'AiBrewGenius',
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _UserNameBanner(),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  Text(
                    'Zusammenfassung für ${profile.beerName}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...buildRecipeSummarySections(profile),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EquipmentPage(profile: profile),
                    ),
                  );
                },
                child: const Text('Equipment'),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _SummarySection {
  const _SummarySection(this.title, this.entries, {this.dividerBefore = false});

  final String title;
  final List<_SummaryEntry> entries;
  final bool dividerBefore;
}

class _SummaryEntry {
  const _SummaryEntry(this.label, this.value, {required this.baselineKey});

  final String label;
  final double value;
  final String baselineKey;
}

List<Widget> buildRecipeSummarySections(FineTuningProfile profile) {
  final sections = [
    _SummarySection('Hopfen', [
      _SummaryEntry('Aromaintensität', profile.hopIntensity,
          baselineKey: 'hopIntensity'),
      _SummaryEntry('Kräuterig', profile.hopHerbal, baselineKey: 'hopHerbal'),
      _SummaryEntry('Blumig', profile.hopFloral, baselineKey: 'hopFloral'),
      _SummaryEntry('Fruchtig', profile.hopFruity, baselineKey: 'hopFruity'),
    ]),
    _SummarySection('Verteilung', [
      _SummaryEntry('Nase', profile.hopNose, baselineKey: 'hopNose'),
      _SummaryEntry('Gaumen', profile.hopPalate, baselineKey: 'hopPalate'),
      _SummaryEntry('Abgang', profile.hopFinish, baselineKey: 'hopFinish'),
    ]),
    _SummarySection(
        'Antrunk',
        [
          _SummaryEntry('Mundgefühl', profile.mouthfeel,
              baselineKey: 'mouthfeel'),
          _SummaryEntry('Malzaroma', profile.antrunkMalt,
              baselineKey: 'antrunkMalt'),
          _SummaryEntry('Röstmalzaroma', profile.antrunkRoast,
              baselineKey: 'antrunkRoast'),
        ],
        dividerBefore: true),
    _SummarySection('Haupttrunk', [
      _SummaryEntry('süffig', profile.smooth, baselineKey: 'smooth'),
      _SummaryEntry('vollmundig', profile.fullBody, baselineKey: 'fullBody'),
      _SummaryEntry('Malzaroma', profile.mainMalt, baselineKey: 'mainMalt'),
      _SummaryEntry('Röstaroma', profile.mainRoast, baselineKey: 'mainRoast'),
    ]),
    _SummarySection('Nachtrunk', [
      _SummaryEntry('abklingen', profile.fade, baselineKey: 'fade'),
      _SummaryEntry('erfrischend', profile.fresh, baselineKey: 'fresh'),
      _SummaryEntry('trocken', profile.dry, baselineKey: 'dry'),
      _SummaryEntry('langanhaltend', profile.lasting, baselineKey: 'lasting'),
    ]),
  ];

  final widgets = <Widget>[];
  for (final section in sections) {
    if (section.dividerBefore) {
      widgets.add(const Divider(
        height: 24,
        thickness: 1,
        color: Colors.white24,
      ));
    }
    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            ...section.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(left: 20, top: 4, bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.label,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      '${(entry.value * 100).round()}%',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 20),
                    Text(
                      _formatSummaryDiff(profile, entry),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
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
  if (profile.specialAdditions.isNotEmpty) {
    widgets.add(const Divider(
      height: 24,
      thickness: 1,
      color: Colors.white24,
    ));
    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Spezielle Zugaben & Lagerungen',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            ...profile.specialAdditions.map(
              (addition) {
                final antrunkPercent = ((1 - addition.focus) * 100).round();
                final abgangPercent = 100 - antrunkPercent;
                final intensityPercent = (addition.intensity * 100).round();
                return Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 8),
                  child: Text(
                    '${addition.title}: Antrunk $antrunkPercent% · Abgang $abgangPercent% · Intensität $intensityPercent%',
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  if (profile.specialStorage.isNotEmpty) {
    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Spezielle Lagerung',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            ...profile.specialStorage.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 6),
                child: Text(
                  entry,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  return widgets;
}

String _formatSummaryDiff(FineTuningProfile profile, _SummaryEntry entry) {
  final delta = profile.diff(entry.baselineKey, entry.value);
  if (delta.abs() < 0.005) return '0%';
  final sign = delta > 0 ? '+' : '-';
  return '$sign${(delta.abs() * 100).round()}%';
}

class _SliderBlock extends StatelessWidget {
  const _SliderBlock({
    required this.label,
    required this.minLabel,
    required this.maxLabel,
    required this.value,
    required this.baselineKey,
  });

  final String label;
  final String minLabel;
  final String maxLabel;
  final double value;
  final String baselineKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              minLabel,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
            Text(
              maxLabel,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${(value * 100).round()}%',
          style: const TextStyle(fontSize: 12, color: Colors.white60),
        ),
      ],
    );
  }
}

class _IndentedBlock extends StatelessWidget {
  const _IndentedBlock({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 48),
      child: child,
    );
  }
}

class _FineSlider extends StatelessWidget {
  const _FineSlider({
    required this.value,
    required this.onChanged,
    required this.baselineKey,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final String baselineKey;

  @override
  Widget build(BuildContext context) {
    final theme = SliderTheme.of(context).copyWith(
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final points = markerPoints(baselineKey, width);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                width: width,
                child: SliderTheme(
                  data: theme,
                  child: Slider(
                    value: value,
                    min: 0,
                    max: 1,
                    onChanged: onChanged,
                  ),
                ),
              ),
              ...points,
            ],
          );
        },
      ),
    );
  }

  List<Widget> markerPoints(String key, double width) {
    final entries = _beerPresets.entries
        .map((e) => MapEntry(e.key, e.value[key]))
        .where((e) => e.value != null)
        .map((e) => MapEntry(e.key, e.value!.clamp(0.0, 1.0)))
        .toList();
    if (entries.isEmpty) return [];

    entries.sort((a, b) => a.value.compareTo(b.value));
    final candidates = <MapEntry<String, double>>[];
    candidates.add(entries.first);
    if (entries.length > 2) {
      final midIndex = entries.length ~/ 2;
      candidates.add(entries[midIndex]);
    }
    candidates.add(entries.last);

    final List<Widget> markers = [];
    for (var i = 0; i < candidates.length; i++) {
      final entry = candidates[i];
      final left = (entry.value * width).clamp(0.0, width - 12.0);
      final placeAbove = i.isEven;
      final double top = placeAbove ? -24.0 - i * 4.0 : 18.0 + i * 4.0;
      markers.add(_Marker(left: left, top: top, label: entry.key));
    }
    return markers;
  }
}

class _Marker extends StatelessWidget {
  const _Marker({required this.left, required this.top, required this.label});

  final double left;
  final double top;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: top < 0
            ? [
                Container(
                  constraints: const BoxConstraints(maxWidth: 70),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, color: Colors.white54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white54,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ]
            : [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white54,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  constraints: const BoxConstraints(maxWidth: 70),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10, color: Colors.white54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
      ),
    );
  }
}



class MaltDepotManagerPage extends StatefulWidget {
  const MaltDepotManagerPage({
    super.key,
    required this.profileId,
    this.repository,
  });

  final String profileId;
  final MaltDepotRepository? repository;

  @override
  State<MaltDepotManagerPage> createState() => _MaltDepotManagerPageState();
}

class EquipmentPage extends StatefulWidget {
  const EquipmentPage({super.key, required this.profile});

  final FineTuningProfile profile;

  @override
  State<EquipmentPage> createState() => _EquipmentPageState();
}

class _EquipmentPageState extends State<EquipmentPage> {
  final BrewKettleService kettleService = BrewKettleService();
  final WaterProfileService waterService = WaterProfileService();
  final FermenterService fermenterService = FermenterService();
  final FermenterControllerService controllerService =
      FermenterControllerService();
  final MaltDepotService maltService = MaltDepotService();
  final FiningAgentsService finingService = FiningAgentsService();
  final PackagingProfileService packagingService = PackagingProfileService();
  final OpenAIService openAIService = OpenAIService();

  bool isLoading = true;
  bool isCalculating = false;
  String? error;

  List<BrewKettle> kettles = [];
  List<WaterProfile> waterProfiles = [];
  List<Fermenter> fermenters = [];
  List<FermenterControllerModel> controllers = [];
  List<MaltDepotEntryModel> maltDepots = [];
  FiningAgents? finingSettings;
  PackagingProfile? selectedPackagingProfile;

  BrewKettle? selectedKettle;
  WaterProfile? selectedWaterProfile;
  Fermenter? selectedFermenter;
  FermenterControllerModel? selectedController;
  MaltDepotEntryModel? selectedMaltDepot;
  final TextEditingController batchSizeCtrl = TextEditingController();
  final FocusNode batchSizeFocusNode = FocusNode();

  static const String profileId = UserProfileService.defaultProfileId;
  static const Map<String, Map<String, String>> finingMetadata = {
    'irish_moss': {
      'name': 'Irish Moss',
      'purpose': 'Bindet Heißtrub für klare Würze.',
      'phase': 'Letzte 10–15 min des Kochens',
    },
    'whirlfloc': {
      'name': 'Whirlfloc-Tabletten',
      'purpose': 'Schnellere Heißtrub-Flockung im Kochkessel.',
      'phase': 'Letzte 10 min des Kochens',
    },
    'gelatin': {
      'name': 'Gelatine',
      'purpose': 'Schönung nach der Gärung für klares Bier.',
      'phase': 'Nachgärung bzw. Kaltlagerung',
    },
    'biersol': {
      'name': 'Biersol (Kieselsol)',
      'purpose': 'Feinklärung vor Abfüllung.',
      'phase': 'Nach der Gärung vor Abfüllung',
    },
    'polyclar': {
      'name': 'Polyclar/PVPP',
      'purpose': 'Polyphenolbindung für geschmackliche Stabilität.',
      'phase': 'Kaltseite vor Abfüllung',
    },
    'isinglass': {
      'name': 'Isinglass',
      'purpose': 'Klassische Klärung für britische Ales.',
      'phase': 'Nachgärung/Kaltlagerung',
    },
    'bentonite': {
      'name': 'Bentonit',
      'purpose': 'Proteinbindung für klare Spezialbiere.',
      'phase': 'Nachguss oder Nachgärung je nach Stil',
    },
    'egg_whites': {
      'name': 'Eiweiß',
      'purpose': 'Traditionelle Schönung (selten genutzt).',
      'phase': 'Nachgärung',
    },
    'activated_carbon': {
      'name': 'Aktivkohle',
      'purpose': 'Spezialreinigung/zur Entfernung Fehlgeschmack.',
      'phase': 'Nachgärung oder Filtration',
    },
  };

  @override
  void initState() {
    super.initState();
    loadEquipment();
  }

  @override
  void dispose() {
    batchSizeCtrl.dispose();
    batchSizeFocusNode.dispose();
    super.dispose();
  }

  Future<void> loadEquipment() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final results = await Future.wait([
        kettleService.fetchKettles(profileId),
        waterService.fetchProfiles(profileId),
        fermenterService.fetchFermenters(profileId),
        controllerService.fetchControllers(profileId),
        maltService.fetchEntries(profileId),
        finingService.fetchSettings(profileId),
        packagingService.fetchProfiles(profileId),
      ]);
      if (!mounted) return;
      setState(() {
        kettles = results[0] as List<BrewKettle>;
        waterProfiles = results[1] as List<WaterProfile>;
        fermenters = results[2] as List<Fermenter>;
        controllers = results[3] as List<FermenterControllerModel>;
        maltDepots = results[4] as List<MaltDepotEntryModel>;
        finingSettings = results[5] as FiningAgents;
        selectedKettle = pickDefault(kettles, (k) => k.isDefault);
        selectedWaterProfile = pickDefault(waterProfiles, (p) => p.isDefault);
        selectedFermenter = pickDefault(fermenters, (f) => f.isDefault);
        selectedController = pickDefault(controllers, (c) => c.isDefault);
        selectedMaltDepot = maltDepots.isNotEmpty ? maltDepots.first : null;
        final packagingProfiles = results[6] as List<PackagingProfile>;
        if (packagingProfiles.isNotEmpty) {
          selectedPackagingProfile =
              pickDefault(packagingProfiles, (p) => p.isDefault) ??
                  packagingProfiles.first;
        } else {
          selectedPackagingProfile = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Equipment konnte nicht geladen werden:\n$error',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadEquipment,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      TextField(
                        controller: batchSizeCtrl,
                        focusNode: batchSizeFocusNode,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Ziel Menge in Liter',
                          hintText: '20',
                        ),
                      ),
                      const SizedBox(height: 16),
                      buildRecipeButton(),
                      const SizedBox(height: 24),
                      _EquipmentSection<BrewKettle>(
                        title: 'Braukessel',
                        items: kettles,
                        selected: selectedKettle,
                        onSelected: (kettle) {
                          if (kettle == null) return;
                          setState(() => selectedKettle = kettle);
                        },
                        isDefaultBuilder: (kettle) => kettle.isDefault,
                        labelBuilder: (kettle) =>
                            kettle.model?.isNotEmpty == true
                                ? '${kettle.brand} ${kettle.model}'
                                : kettle.brand,
                      ),
                      const SizedBox(height: 18),
                      _EquipmentSection<WaterProfile>(
                        title: 'Wasserprofil',
                        items: waterProfiles,
                        selected: selectedWaterProfile,
                        onSelected: (profile) {
                          if (profile == null) return;
                          setState(() => selectedWaterProfile = profile);
                        },
                        isDefaultBuilder: (profile) => profile.isDefault,
                        labelBuilder: (profile) => profile.name,
                      ),
                      const SizedBox(height: 18),
                      _EquipmentSection<Fermenter>(
                        title: 'Fermentierer',
                        items: fermenters,
                        selected: selectedFermenter,
                        onSelected: (fermenter) {
                          if (fermenter == null) return;
                          setState(() => selectedFermenter = fermenter);
                        },
                        isDefaultBuilder: (fermenter) => fermenter.isDefault,
                        labelBuilder: (fermenter) =>
                            fermenter.type?.isNotEmpty == true
                                ? '${fermenter.brand} ${fermenter.type}'
                                : fermenter.brand,
                      ),
                      const SizedBox(height: 18),
                      _EquipmentSection<FermenterControllerModel>(
                        title: 'Kontroller',
                        items: controllers,
                        selected: selectedController,
                        onSelected: (controller) {
                          if (controller == null) return;
                          setState(() => selectedController = controller);
                        },
                        isDefaultBuilder: (controller) => controller.isDefault,
                        labelBuilder: (controller) => controller.name,
                      ),
                      const SizedBox(height: 18),
                      _EquipmentSection<MaltDepotEntryModel>(
                        title: 'Brauerei Shops',
                        items: maltDepots,
                        selected: selectedMaltDepot,
                        onSelected: (entry) {
                          if (entry == null) return;
                          setState(() => selectedMaltDepot = entry);
                        },
                        labelBuilder: (entry) => entry.name,
                      ),
                      const SizedBox(height: 24),
                      const Divider(height: 24, color: Colors.white24),
                      const SizedBox(height: 12),
                      Text(
                        'Rezept-Zusammenfassung',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ...buildRecipeSummarySections(widget.profile),
                    ],
                  ),
                ),
    );
  }

  Widget buildRecipeButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: isCalculating ? null : generateRecipe,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          side: const BorderSide(color: Colors.purple),
          foregroundColor: Colors.white,
          backgroundColor: Colors.purple.withValues(alpha: 0.15),
        ),
        icon: isCalculating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.science_rounded),
        label: Text(isCalculating ? 'Berechne …' : 'Rezept erstellen'),
      ),
    );
  }

  Future<void> generateRecipe() async {
    final batchSize = batchSizeCtrl.text.trim();
    if (batchSize.isEmpty) {
      batchSizeFocusNode.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Ziel Menge eingeben')),
      );
      return;
    }
    try {
      setState(() {
        isCalculating = true;
      });
      final template = await rootBundle.loadString('prompt/rezept_basis');
      final prompt = buildPrompt(template);
      final response = await openAIService.brewRecipe(prompt);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LegacyRecipeResultPage(
            prompt: prompt,
            response: response,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rezeptberechnung fehlgeschlagen: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isCalculating = false;
        });
      }
    }
  }

  T? pickDefault<T>(List<T> items, bool Function(T item) isDefault) {
    if (items.isEmpty) return null;
    for (final item in items) {
      if (isDefault(item)) return item;
    }
    return items.first;
  }

  String buildShopListJson() {
    if (maltDepots.isEmpty) return '[]';
    final list = maltDepots.map((entry) {
      final url = (entry.url ?? '').trim();
      final map = <String, String>{'shop_name': entry.name};
      if (url.isNotEmpty) {
        map['shop_url'] = url;
      }
      return map;
    }).toList();
    return jsonEncode(list);
  }

  String buildSpecialAdditionsJson() {
    if (widget.profile.specialAdditions.isEmpty) return '[]';
    final list = widget.profile.specialAdditions.map((addition) {
      final antrunkPercent = ((1 - addition.focus) * 100).round();
      final abgangPercent = 100 - antrunkPercent;
      final intensityPercent = (addition.intensity * 100).round();
      return {
        'name': addition.title,
        'antrunk_percent': antrunkPercent,
        'abgang_percent': abgangPercent,
        'intensity_percent': intensityPercent,
      };
    }).toList();
    return jsonEncode(list);
  }

  String buildSpecialStorageJson() {
    if (widget.profile.specialStorage.isEmpty) return '[]';
    final list = widget.profile.specialStorage
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();
    if (list.isEmpty) return '[]';
    return jsonEncode(list);
  }

  String buildFiningAgentsJson() {
    final settings = finingSettings;
    if (settings == null) return '[]';
    final selections = <Map<String, String>>[];

    void addOption(String key, bool enabled) {
      if (!enabled) return;
      final meta = finingMetadata[key];
      selections.add({
        'key': key,
        'name': meta?['name'] ?? key,
        'purpose': meta?['purpose'] ?? '',
        'recommended_phase': meta?['phase'] ?? '',
      });
    }

    addOption('irish_moss', settings.irishMoss);
    addOption('whirlfloc', settings.whirlfloc);
    addOption('gelatin', settings.gelatin);
    addOption('biersol', settings.biersol);
    addOption('polyclar', settings.polyclar);
    addOption('isinglass', settings.isinglass);
    addOption('bentonite', settings.bentonite);
    addOption('egg_whites', settings.eggWhites);
    addOption('activated_carbon', settings.activatedCarbon);

    for (final extra in settings.extras) {
      final trimmed = extra.trim();
      if (trimmed.isEmpty) continue;
      selections.add({
        'key': 'custom',
        'name': trimmed,
        'purpose': 'Vom Nutzer hinterlegt',
        'recommended_phase': '',
      });
    }

    if (selections.isEmpty) return '[]';
    return jsonEncode(selections);
  }

  String buildPackagingProfileJson() {
    final profile = selectedPackagingProfile;
    if (profile == null) return '{}';
    final map = <String, dynamic>{
      'name': profile.name,
      'bottle': {
        'enabled': profile.bottleEnabled,
        'carbonation_temp_c': profile.bottleCarbonationTempC,
        'storage_temp_c': profile.bottleStorageTempC,
      },
      'keg': {
        'enabled': profile.kegEnabled,
        'carbonation_temp_c': profile.kegCarbonationTempC,
        'storage_temp_c': profile.kegStorageTempC,
        'volume_l': profile.kegVolumeLiters,
      },
    };
    return jsonEncode(map);
  }

  String buildPrompt(String template) {
    String formatScore(double value) => value.toStringAsFixed(2);
    String formatWater(double? value) => (value ?? 0).toStringAsFixed(2);
    String formatText(String? value) =>
        (value == null || value.trim().isEmpty) ? 'unbekannt' : value.trim();
    String formatBool(bool? value) => (value ?? false) ? 'true' : 'false';

    final water = selectedWaterProfile;
    final replacements = <String, String>{
      'bier_typ': widget.profile.beerType,
      'basis_bier': widget.profile.beerName,
      'hop_intensity': formatScore(widget.profile.hopIntensity),
      'hop_herbal': formatScore(widget.profile.hopHerbal),
      'hop_floral': formatScore(widget.profile.hopFloral),
      'hop_fruity': formatScore(widget.profile.hopFruity),
      'hop_nose': formatScore(widget.profile.hopNose),
      'hop_palate': formatScore(widget.profile.hopPalate),
      'hop_finish': formatScore(widget.profile.hopFinish),
      'mouthfeel': formatScore(widget.profile.mouthfeel),
      'antrunk_malt': formatScore(widget.profile.antrunkMalt),
      'antrunk_roast': formatScore(widget.profile.antrunkRoast),
      'smooth': formatScore(widget.profile.smooth),
      'full_body': formatScore(widget.profile.fullBody),
      'main_malt': formatScore(widget.profile.mainMalt),
      'main_roast': formatScore(widget.profile.mainRoast),
      'fade': formatScore(widget.profile.fade),
      'fresh': formatScore(widget.profile.fresh),
      'dry': formatScore(widget.profile.dry),
      'lasting': formatScore(widget.profile.lasting),
      'kettle_brand': formatText(selectedKettle?.brand),
      'kettle_type': formatText(selectedKettle?.model),
      'fermenter_brand': formatText(selectedFermenter?.brand),
      'fermenter_type': formatText(selectedFermenter?.type),
      'fermenter_heating': formatBool(selectedFermenter?.hasHeating),
      'fermenter_cooling': formatBool(selectedFermenter?.hasCooling),
      'special_additions': buildSpecialAdditionsJson(),
      'special_storage': buildSpecialStorageJson(),
      'fining_agents': buildFiningAgentsJson(),
      'packaging_profile': buildPackagingProfileJson(),
      'shop_list': buildShopListJson(),
      'target_volume_l':
          batchSizeCtrl.text.trim().isEmpty ? '0' : batchSizeCtrl.text.trim(),
      'calcium': formatWater(water?.calciumPpm),
      'magnesium': formatWater(water?.magnesiumPpm),
      'sodium': formatWater(water?.sodiumPpm),
      'chloride': formatWater(water?.chloridePpm),
      'sulfate': formatWater(water?.sulfatePpm),
      'bicarbonate': formatWater(water?.bicarbonatePpm),
      'ph': water?.ph?.toStringAsFixed(2) ?? '0.00',
    };

    var prompt = template;
    replacements.forEach((key, value) {
      prompt = prompt.replaceAll('{{$key}}', value);
    });
    return prompt;
  }
}

class _EquipmentSection<T> extends StatelessWidget {
  const _EquipmentSection({
    required this.title,
    required this.items,
    required this.selected,
    required this.onSelected,
    required this.labelBuilder,
    this.isDefaultBuilder,
  });

  final String title;
  final List<T> items;
  final T? selected;
  final ValueChanged<T?> onSelected;
  final String Function(T item) labelBuilder;
  final bool Function(T item)? isDefaultBuilder;
  // Detail rendering removed per latest requirements – only name shown.

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Card(
        color: const Color(0xFF0F172A),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Keine Daten für $title vorhanden.'),
        ),
      );
    }
    final T current = selected ?? defaultItem() ?? items.first;
    return Card(
      color: const Color(0xFF0F172A),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (items.length > 1)
              DropdownMenu<T>(
                initialSelection: current,
                onSelected: onSelected,
                dropdownMenuEntries: items
                    .map(
                      (item) => DropdownMenuEntry<T>(
                        value: item,
                        label: decorateLabel(item),
                      ),
                    )
                    .toList(),
              )
            else
              Text(decorateLabel(current)),
          ],
        ),
      ),
    );
  }

  String decorateLabel(T item) {
    final label = labelBuilder(item);
    final isDefault = isDefaultBuilder?.call(item) ?? false;
    return isDefault ? '$label ★' : label;
  }

  T? defaultItem() {
    final checker = isDefaultBuilder;
    if (checker == null) return null;
    for (final item in items) {
      if (checker(item)) return item;
    }
    return null;
  }
}



List<Widget> _buildSections(Map<String, dynamic> parsed) {
  final zutaten = _asMap(parsed['Zutaten'] ?? parsed['zutaten']);
  final prozess = _asMap(parsed['Prozessdaten'] ?? parsed['prozessdaten']);
  final sections = <Widget>[];

  void addSection(String title, List<_RecipeEntry> entries) {
    if (sections.isNotEmpty) {
      sections.add(const Divider(height: 32, color: Colors.white24));
    }
    sections.add(_RecipeSection(title: title, entries: entries));
  }

  addSection(
    'Zutaten – Malz',
    _formatList(zutaten['Original_Malz'] ?? zutaten['original_malz']),
  );
  addSection(
    'Zutaten – Hopfen',
    _formatList(zutaten['Original_Hopfen'] ?? zutaten['original_hopfen']),
  );
  addSection(
    'Zutaten – Hefe',
    _formatList(zutaten['Original_Hefe'] ?? zutaten['original_hefe']),
  );
  addSection(
    'Spezialzutaten',
    _formatList(zutaten['Spezialzutaten'] ?? zutaten['spezialzutaten']),
  );
  addSection(
    'Klär- & Schönungsmittel',
    _formatList(
      zutaten['Klaer_und_Schonungsmittel'] ??
          zutaten['klaer_und_schonungsmittel'],
    ),
  );
  addSection(
    'Wasseraufbereitung',
    _formatList(zutaten['Wasseraufbereitung'] ?? zutaten['wasseraufbereitung']),
  );
  addSection(
    'Maischeplan',
    _formatList(prozess['Maischeplan'] ?? prozess['maischeplan']),
  );
  addSection(
    'Kochplan',
    _formatKochplan(
      prozess['Kochzeit_und_Kochphasen'] ?? prozess['kochzeit_und_kochphasen'],
    ),
  );
  addSection(
    'Gärplan',
    _formatGaerplan(
      prozess['Gaerplan'] ?? prozess['Gärplan'] ?? prozess['gaerplan'],
    ),
  );
  addSection(
    'Abfüllung & Lagern',
    _formatList(prozess['Abfuellung_ins_Keg'] ?? prozess['abfuellung_ins_keg']),
  );
  addSection(
    'Abfüllung – Flaschen',
    _formatList(
      prozess['Abfuellung_in_Flaschen'] ?? prozess['abfuellung_in_flaschen'],
    ),
  );
  addSection(
    'Notizen',
    _formatList(parsed['Notizen'] ?? parsed['notizen']),
  );

  return sections;
}

final RegExp _urlRegExp = RegExp(r'(https?:\/\/[^\s)]+)', caseSensitive: false);

Future<void> _launchExternalUrl(String url) async {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return;
  Uri? uri = Uri.tryParse(trimmed);
  if (uri == null) return;
  if (!uri.hasScheme) {
    uri = Uri.tryParse('https://$trimmed');
    if (uri == null) return;
  }
  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    // Ignore launch errors to avoid crashing UI
  }
}

List<_LinkSegment> _segmentLine(String line) {
  final matches = _urlRegExp.allMatches(line);
  if (matches.isEmpty) {
    return [_LinkSegment(line, false)];
  }
  final segments = <_LinkSegment>[];
  var currentIndex = 0;
  for (final match in matches) {
    if (match.start > currentIndex) {
      segments.add(
        _LinkSegment(line.substring(currentIndex, match.start), false),
      );
    }
    final url = match.group(0);
    if (url != null && url.isNotEmpty) {
      segments.add(_LinkSegment(url, true));
    }
    currentIndex = match.end;
  }
  if (currentIndex < line.length) {
    segments.add(_LinkSegment(line.substring(currentIndex), false));
  }
  return segments.isEmpty ? [_LinkSegment(line, false)] : segments;
}

class _LinkSegment {
  const _LinkSegment(this.text, this.isLink);

  final String text;
  final bool isLink;
}

List<_RecipeEntry> _formatList(dynamic input) {
  if (input == null) return [const _RecipeEntry(text: 'Keine Angaben')];
  if (input is List) {
    if (input.isEmpty) return [const _RecipeEntry(text: 'Keine Angaben')];
    return input.map((e) => _formatEntry(e)).toList();
  }
  return [_formatEntry(input)];
}

List<_RecipeEntry> _formatKochplan(dynamic input) {
  if (input == null) return [const _RecipeEntry(text: 'Keine Angaben')];
  if (input is Map<String, dynamic>) {
    final lines = <_RecipeEntry>[];
    if (input['Gesamte_Kochdauer'] != null) {
      lines.add(_entry('Gesamte Kochdauer: ${input['Gesamte_Kochdauer']} min'));
    }
    if (input['Kochphasen'] != null) {
      lines.add(_entry('Kochphasen:'));
      lines.addAll(
        _prefixEntries(_formatList(input['Kochphasen']), '  - '),
      );
    }
    if (input['Hopfengaben'] != null) {
      lines.add(_entry('Hopfengaben:'));
      lines.addAll(
        _prefixEntries(_formatList(input['Hopfengaben']), '  - '),
      );
    }
    if (input['Erwartete_Gravity_nach_Kochen'] != null) {
      lines.add(_entry(
          'Erw. Gravity nach Kochen: ${input['Erwartete_Gravity_nach_Kochen']}'));
    }
    if (input['Erwarteter_pH_Wert_nach_Kochen'] != null) {
      lines.add(_entry(
          'Erw. pH nach Kochen: ${input['Erwarteter_pH_Wert_nach_Kochen']}'));
    }
    return lines.isEmpty ? [const _RecipeEntry(text: 'Keine Angaben')] : lines;
  }
  return _formatList(input);
}

List<_RecipeEntry> _formatGaerplan(dynamic input) {
  if (input == null) return [const _RecipeEntry(text: 'Keine Angaben')];
  if (input is Map<String, dynamic>) {
    final lines = <_RecipeEntry>[];
    if (input['Empfehlung'] != null) {
      lines.add(_entry('Empfehlung: ${input['Empfehlung']}'));
    }
    if (input['Gaerphase'] != null) {
      final phases = input['Gaerphase'];
      final iterable = phases is List ? phases : [phases];
      for (final phase in iterable) {
        if (phase is Map) {
          final phaseMap =
              phase.map((key, value) => MapEntry(key.toString(), value));
          final name = phaseMap.remove('Name') ?? phaseMap.remove('name');
          final details = _formatEntry(phaseMap).text;
          final label = name ?? 'Phase';
          lines.add(_entry('$label: $details'));
        } else {
          lines.add(_entry(phase.toString()));
        }
      }
    }
    return lines.isEmpty ? [const _RecipeEntry(text: 'Keine Angaben')] : lines;
  }
  return _formatList(input);
}

_RecipeEntry _formatEntry(dynamic value) {
  if (value == null) return const _RecipeEntry(text: 'Keine Angaben');
  if (value is String) {
    final trimmed = value.trim();
    return _RecipeEntry(text: trimmed.isEmpty ? 'Keine Angaben' : trimmed);
  }
  if (value is Map) {
    final normalized = value.map((key, val) => MapEntry(key.toString(), val));
    final url = _extractUrlField(normalized);
    final parts = <String>[];
    normalized.forEach((key, val) {
      if (_isUrlKey(key)) return;
      parts.add('${_beautifyKey(key)}: ${_formatSimpleValue(val)}');
    });
    final text = parts.isEmpty ? (url ?? 'Keine Angaben') : parts.join(', ');
    return _RecipeEntry(text: text, link: url);
  }
  return _RecipeEntry(text: value.toString());
}

String _formatSimpleValue(dynamic value) {
  if (value == null) return 'Keine Angaben';
  if (value is Map || value is List) {
    final entry = _formatEntry(value);
    return entry.link != null && entry.link!.isNotEmpty
        ? '${entry.text} (${entry.link})'
        : entry.text;
  }
  if (value is String && value.trim().isEmpty) return 'Keine Angaben';
  return value.toString();
}

_RecipeEntry _entry(String text) => _RecipeEntry(text: text);

List<_RecipeEntry> _prefixEntries(List<_RecipeEntry> entries, String prefix) {
  return entries
      .map(
        (entry) => entry.copyWith(text: '$prefix${entry.text}'),
      )
      .toList();
}

String? _extractUrlField(Map<String, dynamic> map) {
  for (final entry in map.entries) {
    if (_isUrlKey(entry.key)) {
      final value = entry.value;
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
  }
  return null;
}

bool _isUrlKey(String key) {
  final lower = key.toLowerCase();
  return lower == 'url' || lower.endsWith('_url') || lower.contains('link');
}

String _beautifyKey(String key) {
  return key.replaceAll('_', ' ');
}

String? _stringField(dynamic value) {
  if (value == null) return null;
  final trimmed = value.toString().trim();
  return trimmed.isEmpty ? null : trimmed;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return <String, dynamic>{};
}

String _extractJson(String raw) {
  final trimmed = raw.trim();
  if (trimmed.startsWith('```')) {
    final endFence = trimmed.lastIndexOf('```');
    if (endFence > 3) {
      final body = trimmed.substring(3, endFence).trim();
      final firstNewline = body.indexOf('\n');
      if (body.startsWith('json') && firstNewline != -1) {
        return body.substring(firstNewline + 1).trim();
      }
      return body;
    }
  }
  return trimmed;
}

class _RecipeSection extends StatelessWidget {
  const _RecipeSection({required this.title, required this.entries});

  final String title;
  final List<_RecipeEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...entries.map((entry) => _RecipeLine(entry: entry)),
      ],
    );
  }
}

class _RecipeLine extends StatelessWidget {
  const _RecipeLine({required this.entry});

  final _RecipeEntry entry;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = Theme.of(context).textTheme.bodyMedium;
    final linkStyle = defaultStyle?.copyWith(
      color: const Color(0xFF38BDF8),
      decoration: TextDecoration.underline,
    );
    final segments = _segmentLine(entry.text);
    final List<Widget> children = <Widget>[];
    for (final segment in segments) {
      final textWidget = Text(
        segment.text,
        style: segment.isLink ? linkStyle : defaultStyle,
      );
      if (!segment.isLink) {
        children.add(textWidget);
        continue;
      }
      children.add(
        GestureDetector(
          onTap: () => _launchExternalUrl(segment.text),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: textWidget,
          ),
        ),
      );
    }

    final linkText = entry.link?.trim();
    if (linkText != null && linkText.isNotEmpty) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(width: 6));
      }
      children.add(
        GestureDetector(
          onTap: () => _launchExternalUrl(linkText),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Text(
              linkText,
              style: linkStyle,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      ),
    );
  }
}

class _RecipeEntry {
  const _RecipeEntry({required this.text, this.link});

  final String text;
  final String? link;

  _RecipeEntry copyWith({String? text, String? link}) {
    return _RecipeEntry(
      text: text ?? this.text,
      link: link ?? this.link,
    );
  }
}

class _MaltDepotManagerPageState extends State<MaltDepotManagerPage> {
  late final MaltDepotRepository repository;
  bool isLoading = true;
  List<MaltDepotEntryModel> entries = [];
  String? error;

  @override
  void initState() {
    super.initState();
    repository = widget.repository ?? MaltDepotService();
    load();
  }

  Future<void> load() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final items = await repository.fetchEntries(widget.profileId);
      if (!mounted) return;
      setState(() {
        entries = items;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Brauerei Shops'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => openForm(),
              icon: const Icon(Icons.add),
              label: const Text('Neu'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: buildBody(),
      ),
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Text(
          'Konnte Brauerei Shops nicht laden:\n$error',
          textAlign: TextAlign.center,
        ),
      );
    }
    if (entries.isEmpty) {
      return const Center(child: Text('Noch keine Einträge.'));
    }
    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Card(
          color: const Color(0xFF0F172A),
          child: ListTile(
            onTap: () => openForm(editing: entry),
            title: Text(entry.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((entry.url ?? '').isNotEmpty) Text('URL: ${entry.url}'),
                if ((entry.notes ?? '').isNotEmpty)
                  Text(
                    entry.notes!,
                    style: const TextStyle(color: Colors.white70),
                  ),
              ],
            ),
            trailing: CardActions(
              onEdit: () => openForm(editing: entry),
              onDelete: () => confirmDelete(
                'Malzlieferant “${entry.name}” löschen?',
                () => deleteEntry(entry),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> openForm({MaltDepotEntryModel? editing}) async {
    final nameCtrl = TextEditingController(text: editing?.name ?? '');
    final urlCtrl = TextEditingController(text: editing?.url ?? '');
    final notesCtrl = TextEditingController(text: editing?.notes ?? '');
    String? nameError;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(editing == null
              ? 'Malzlieferant hinzufügen'
              : 'Malzlieferant bearbeiten'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    errorText: nameError,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(labelText: 'URL'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Notizen'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) {
                  setState(() => nameError = 'Name erforderlich');
                  return;
                }
                Navigator.of(dialogCtx).pop(true);
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    final entry = MaltDepotEntryModel(
      id: editing?.id,
      userProfileId: widget.profileId,
      name: nameCtrl.text.trim(),
      url: urlCtrl.text.trim().isEmpty ? null : urlCtrl.text.trim(),
      notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
    );

    try {
      final saved = await repository.saveEntry(entry);
      if (!mounted) return;
      setState(() {
        final index = entries.indexWhere((element) => element.id == saved.id);
        if (index >= 0) {
          entries[index] = saved;
        } else {
          entries.add(saved);
        }
        entries.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              editing == null ? 'Eintrag erstellt' : 'Eintrag aktualisiert',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speichern fehlgeschlagen: $e')),
      );
    }
  }

  Future<void> deleteEntry(MaltDepotEntryModel entry) async {
    if (entry.id == null) return;
    try {
      await repository.deleteEntry(entry.id!);
      setState(() {
        entries.removeWhere((item) => item.id == entry.id);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Malzlieferant "${entry.name}" gelöscht')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Löschen fehlgeschlagen: $e')));
    }
  }

  Future<void> confirmDelete(
    String title,
    Future<void> Function() onDelete,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content:
            const Text('Dieser Vorgang kann nicht rückgängig gemacht werden.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await onDelete();
    }
  }
}

class FermenterControllerManagerPage extends StatefulWidget {
  const FermenterControllerManagerPage({
    super.key,
    required this.profileId,
    this.repository,
  });

  final String profileId;
  final FermenterControllerRepository? repository;

  @override
  State<FermenterControllerManagerPage> createState() =>
      _FermenterControllerManagerPageState();
}

class FiningAgentsPage extends StatefulWidget {
  const FiningAgentsPage({
    super.key,
    required this.profileId,
    this.repository,
  });

  final String profileId;
  final FiningAgentsRepository? repository;

  @override
  State<FiningAgentsPage> createState() => _FiningAgentsPageState();
}

class _FiningAgentsPageState extends State<FiningAgentsPage> {
  late final FiningAgentsRepository repository;
  bool isLoading = true;
  bool isSaving = false;
  FiningAgents? settings;
  final Map<String, bool> values = {};
  final List<TextEditingController> extraCtrls = [];
  final TextEditingController newExtraCtrl = TextEditingController();
  String? error;
  static const List<_FiningOption> options = [
    _FiningOption(
      key: 'irish_moss',
      title: 'Irish Moss',
      subtitle: 'Carrageen/Rotalgextrakt für die Würzekochung.',
    ),
    _FiningOption(
      key: 'whirlfloc',
      title: 'Whirlfloc-Tabletten',
      subtitle: 'Praktische Tabletten auf Irish-Moss-Basis.',
    ),
    _FiningOption(
      key: 'gelatin',
      title: 'Gelatine',
      subtitle: 'Klassisches Schönungsmittel nach der Gärung.',
    ),
    _FiningOption(
      key: 'biersol',
      title: 'Biersol (Kieselsol)',
      subtitle: 'Flüssigschönung für die Endklärung.',
    ),
    _FiningOption(
      key: 'polyclar',
      title: 'Polyclar/PVPP',
      subtitle: 'Entfernt Polyphenole für klare Biere.',
    ),
    _FiningOption(
      key: 'isinglass',
      title: 'Isinglass',
      subtitle: 'Fischblasen-Schönung, typisch britisch.',
    ),
    _FiningOption(
      key: 'bentonite',
      title: 'Bentonit',
      subtitle: 'Tonerde, häufiger im Wein- und Spezialbierbereich.',
    ),
    _FiningOption(
      key: 'egg_whites',
      title: 'Egg Whites',
      subtitle: 'Selten genutzt, eher beim Wein.',
    ),
    _FiningOption(
      key: 'activated_carbon',
      title: 'Aktivkohle',
      subtitle: 'Für Spezialreinigung und besondere Effekte.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    repository = widget.repository ?? FiningAgentsService();
    load();
  }

  @override
  void dispose() {
    for (final ctrl in extraCtrls) {
      ctrl.dispose();
    }
    newExtraCtrl.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final data = await repository.fetchSettings(widget.profileId);
      if (!mounted) return;
      setState(() {
        settings = data;
        values['irish_moss'] = data.irishMoss;
        values['whirlfloc'] = data.whirlfloc;
        values['gelatin'] = data.gelatin;
        values['biersol'] = data.biersol;
        values['polyclar'] = data.polyclar;
        values['isinglass'] = data.isinglass;
        values['bentonite'] = data.bentonite;
        values['egg_whites'] = data.eggWhites;
        values['activated_carbon'] = data.activatedCarbon;
        for (final ctrl in extraCtrls) {
          ctrl.dispose();
        }
        extraCtrls
          ..clear()
          ..addAll(
            data.extras.map((extra) => TextEditingController(text: extra)),
          );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Klärmittel / Schönungsmittel')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade900.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('Fehler: $error'),
                    ),
                  ],
                  Expanded(
                    child: ListView(
                      children: [
                        ...options.map(
                          (option) => CheckboxListTile(
                            value: values[option.key] ?? false,
                            onChanged: (value) {
                              setState(() {
                                values[option.key] = value ?? false;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                            title: Text(option.title),
                            subtitle: Text(option.subtitle),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        const Text(
                          'Weitere Mittel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...extraCtrls.asMap().entries.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: entry.value,
                                        decoration: InputDecoration(
                                          labelText: 'Zusatz ${entry.key + 1}',
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => removeExtra(entry.key),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        TextField(
                          controller: newExtraCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Neues Mittel (ENTER zum Hinzufügen)',
                          ),
                          onSubmitted: (_) => addExtra(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isSaving ? null : save,
                      icon: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_alt),
                      label: Text(isSaving ? 'Speichert …' : 'Speichern'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void addExtra() {
    final value = newExtraCtrl.text.trim();
    if (value.isEmpty) return;
    setState(() {
      extraCtrls.add(TextEditingController(text: value));
      newExtraCtrl.clear();
    });
  }

  void removeExtra(int index) {
    setState(() {
      extraCtrls[index].dispose();
      extraCtrls.removeAt(index);
    });
  }

  Future<void> save() async {
    if (settings == null) return;
    setState(() {
      isSaving = true;
    });
    try {
      final updated = FiningAgents(
        userProfileId: widget.profileId,
        irishMoss: values['irish_moss'] ?? false,
        whirlfloc: values['whirlfloc'] ?? false,
        gelatin: values['gelatin'] ?? false,
        biersol: values['biersol'] ?? false,
        polyclar: values['polyclar'] ?? false,
        isinglass: values['isinglass'] ?? false,
        bentonite: values['bentonite'] ?? false,
        eggWhites: values['egg_whites'] ?? false,
        activatedCarbon: values['activated_carbon'] ?? false,
        extras: extraCtrls
            .map((ctrl) => ctrl.text.trim())
            .where((text) => text.isNotEmpty)
            .toList(),
      );
      final saved = await repository.saveSettings(updated);
      if (!mounted) return;
      setState(() {
        settings = saved;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schönungsmittel gespeichert')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speichern fehlgeschlagen: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }
}

class _FiningOption {
  const _FiningOption({
    required this.key,
    required this.title,
    required this.subtitle,
  });

  final String key;
  final String title;
  final String subtitle;
}

class PackagingProfileManagerPage extends StatefulWidget {
  const PackagingProfileManagerPage({
    super.key,
    required this.profileId,
    this.repository,
  });

  final String profileId;
  final PackagingProfileRepository? repository;

  @override
  State<PackagingProfileManagerPage> createState() =>
      _PackagingProfileManagerPageState();
}

class _PackagingProfileManagerPageState
    extends State<PackagingProfileManagerPage> {
  late final PackagingProfileRepository repository;
  bool isLoading = true;
  List<PackagingProfile> profiles = [];
  String? error;

  @override
  void initState() {
    super.initState();
    repository = widget.repository ?? PackagingProfileService();
    load();
  }

  Future<void> load() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final items = await repository.fetchProfiles(widget.profileId);
      if (!mounted) return;
      setState(() {
        profiles = items;
        profiles.sort(
          (a, b) {
            if (a.isDefault != b.isDefault) {
              return a.isDefault ? -1 : 1;
            }
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          },
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zielmenge,Abfüllen und Lagern'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => openForm(),
              icon: const Icon(Icons.add),
              label: const Text('Neu'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: buildBody(),
      ),
    );
  }

  Widget buildBody() {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: Text(
          'Konnte Profile nicht laden:\n$error',
          textAlign: TextAlign.center,
        ),
      );
    }
    if (profiles.isEmpty) {
      return const Center(
        child: Text('Noch keine Abfüll- und Lagerprofile vorhanden.'),
      );
    }
    return ListView.separated(
      itemCount: profiles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final profile = profiles[index];
        final kegInfo = <String>[];
        final bottleInfo = <String>[];
        if (profile.targetVolume != null) {
          kegInfo.add('Zielmenge: ${profile.targetVolume!.toStringAsFixed(1)} L');
        }
        if (profile.kegEnabled) {
          final carb = profile.kegCarbonationTempC != null
              ? '${profile.kegCarbonationTempC!.toStringAsFixed(1)} °C'
              : '–';
          final storage = profile.kegStorageTempC != null
              ? '${profile.kegStorageTempC!.toStringAsFixed(1)} °C'
              : '–';
          final liters = profile.kegVolumeLiters != null
              ? ', ${profile.kegVolumeLiters!.toStringAsFixed(1)} L'
              : '';
          final gases = <String>[];
          if (profile.hasCo2) gases.add('CO2');
          if (profile.hasNitro) gases.add('Nitro');
          final gasStr = gases.isNotEmpty ? ' [${gases.join(' + ')}]' : '';

          kegInfo.add('Keg: Karb $carb · Lager $storage$liters$gasStr');
        }
        if (profile.bottleEnabled) {
          final carb = profile.bottleCarbonationTempC != null
              ? '${profile.bottleCarbonationTempC!.toStringAsFixed(1)} °C'
              : '–';
          final storage = profile.bottleStorageTempC != null
              ? '${profile.bottleStorageTempC!.toStringAsFixed(1)} °C'
              : '–';
          bottleInfo.add('Flaschen: Karb $carb · Lager $storage');
        }
        final info = [...kegInfo, ...bottleInfo];
        if (info.isEmpty) {
          info.add('Keine Angaben');
        }
        return Card(
          color: const Color(0xFF0F172A),
          child: ListTile(
            onTap: () => openForm(editing: profile),
            leading: Icon(
              profile.isDefault ? Icons.star : Icons.star_border,
              color: profile.isDefault ? Colors.amber : Colors.white54,
            ),
            title: Text(profile.name),
            subtitle: info.isEmpty
                ? null
                : Text(
                    info.join(' · '),
                  ),
            trailing: CardActions(
              onEdit: () => openForm(editing: profile),
              onDelete: () => confirmDelete(
                'Profil “${profile.name}” löschen?',
                () => deleteProfile(profile),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> openForm({PackagingProfile? editing}) async {
    final nameCtrl = TextEditingController(text: editing?.name ?? '');
    final targetVolumeCtrl = TextEditingController(
      text: editing?.targetVolume?.toString() ?? '',
    );
    final bottleCarbCtrl = TextEditingController(
      text: editing?.bottleCarbonationTempC?.toString() ?? '',
    );
    final bottleStorageCtrl = TextEditingController(
      text: editing?.bottleStorageTempC?.toString() ?? '',
    );
    final kegCarbCtrl = TextEditingController(
      text: editing?.kegCarbonationTempC?.toString() ?? '',
    );
    final kegStorageCtrl = TextEditingController(
      text: editing?.kegStorageTempC?.toString() ?? '',
    );
    final volumeCtrl = TextEditingController(
      text: editing?.kegVolumeLiters?.toString() ?? '',
    );
    bool bottleEnabled = editing?.bottleEnabled ?? true;
    bool kegEnabled = editing?.kegEnabled ?? false;
    bool hasCo2 = editing?.hasCo2 ?? true;
    bool hasNitro = editing?.hasNitro ?? false;
    bool isDefault = editing?.isDefault ?? false;
    String? nameError;
    String? typeError;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title:
              Text(editing == null ? 'Profil hinzufügen' : 'Profil bearbeiten'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Profilname',
                    errorText: nameError,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: targetVolumeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Zielmenge',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                if (typeError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      typeError!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                SwitchListTile(
                  value: bottleEnabled,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Flaschen abfüllen'),
                  onChanged: (value) => setState(() => bottleEnabled = value),
                ),
                if (bottleEnabled) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: bottleCarbCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Flaschen – Karbonisierung (°C)',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bottleStorageCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Flaschen – Lagerung (°C)',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                ],
                SwitchListTile(
                  value: kegEnabled,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Kegs abfüllen'),
                  onChanged: (value) => setState(() => kegEnabled = value),
                ),
                if (kegEnabled) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: kegCarbCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Keg – Karbonisierung (°C)',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: kegStorageCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Keg – Lagerung (°C)',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: volumeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Keg Volumen (L)',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(height: 12),
                  const Text('Schankgas', style: TextStyle(fontSize: 16)),
                  CheckboxListTile(
                    value: hasCo2,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('CO2'),
                    onChanged: (val) => setState(() => hasCo2 = val ?? false),
                  ),
                  CheckboxListTile(
                    value: hasNitro,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Nitro'),
                    onChanged: (val) => setState(() => hasNitro = val ?? false),
                  ),
                  const SizedBox(height: 12),
                ],
                CheckboxListTile(
                  value: isDefault,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Als Standard markieren'),
                  onChanged: (value) =>
                      setState(() => isDefault = value ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) {
                  setState(() => nameError = 'Name erforderlich');
                  return;
                }
                if (!bottleEnabled && !kegEnabled) {
                  setState(() =>
                      typeError = 'Mindestens Flaschen oder Keg aktivieren');
                  return;
                }
                Navigator.of(dialogCtx).pop(true);
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    final profile = PackagingProfile(
      id: editing?.id,
      userProfileId: widget.profileId,
      name: nameCtrl.text.trim(),
      targetVolume:
          parseDouble(targetVolumeCtrl.text),
      bottleEnabled: bottleEnabled,
      bottleCarbonationTempC:
          bottleEnabled ? parseDouble(bottleCarbCtrl.text) : null,
      bottleStorageTempC:
          bottleEnabled ? parseDouble(bottleStorageCtrl.text) : null,
      kegEnabled: kegEnabled,
      kegCarbonationTempC: kegEnabled ? parseDouble(kegCarbCtrl.text) : null,
      kegStorageTempC: kegEnabled ? parseDouble(kegStorageCtrl.text) : null,
      kegVolumeLiters: kegEnabled ? parseDouble(volumeCtrl.text) : null,
      hasCo2: hasCo2,
      hasNitro: hasNitro,
      isDefault: isDefault,
    );

    try {
      final saved = await repository.saveProfile(profile);
      if (!mounted) return;
      setState(() {
        if (saved.isDefault) {
          profiles = profiles
              .map((existing) => existing.id == saved.id
                  ? existing
                  : existing.copyWith(isDefault: false))
              .toList();
        }
        final index = profiles.indexWhere((element) => element.id == saved.id);
        if (index >= 0) {
          profiles[index] = saved;
        } else {
          profiles.add(saved);
        }
        profiles.sort(
          (a, b) {
            if (a.isDefault != b.isDefault) {
              return a.isDefault ? -1 : 1;
            }
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          },
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              editing == null ? 'Profil erstellt' : 'Profil aktualisiert',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speichern fehlgeschlagen: $e')),
      );
    }
  }

  double? parseDouble(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned.replaceAll(',', '.'));
  }

  Future<void> deleteProfile(PackagingProfile profile) async {
    if (profile.id == null) return;
    try {
      await repository.deleteProfile(profile.id!);
      setState(() {
        profiles.removeWhere((item) => item.id == profile.id);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil "${profile.name}" gelöscht')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Löschen fehlgeschlagen: $e')));
    }
  }

  Future<void> confirmDelete(
    String title,
    Future<void> Function() onDelete,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content:
            const Text('Dieser Vorgang kann nicht rückgängig gemacht werden.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await onDelete();
    }
  }
}

class _FermenterControllerManagerPageState
    extends State<FermenterControllerManagerPage> {
  late final FermenterControllerRepository service;
  bool isLoading = true;
  List<FermenterControllerModel> controllers = [];
  String? error;

  @override
  void initState() {
    super.initState();
    service = widget.repository ?? FermenterControllerService();
    load();
  }

  Future<void> load() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final items = await service.fetchControllers(widget.profileId);
      if (!mounted) return;
      setState(() {
        controllers = items;
        sortControllers();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fermentierer-Kontroller'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: () => openForm(),
              icon: const Icon(Icons.add),
              label: const Text('Neu'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: buildBody(),
      ),
    );
  }

  Widget buildBody() {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: Text(
          'Konnte Kontroller nicht laden:\n$error',
          textAlign: TextAlign.center,
        ),
      );
    }
    if (controllers.isEmpty) {
      return const Center(child: Text('Noch keine Controller vorhanden.'));
    }
    return ListView.separated(
      itemCount: controllers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final controller = controllers[index];
        return Card(
          color: const Color(0xFF0F172A),
          child: ListTile(
            onTap: () => openForm(editing: controller),
            leading: Icon(
              controller.isDefault ? Icons.star : Icons.star_border,
              color: controller.isDefault ? Colors.amber : Colors.white54,
            ),
            title: Text(controller.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((controller.username ?? '').isNotEmpty)
                  Text('User: ${controller.username}'),
                if ((controller.apiKey ?? '').isNotEmpty)
                  Text('API Key: ${controller.apiKey}'),
                if ((controller.notes ?? '').isNotEmpty)
                  Text(
                    controller.notes!,
                    style: const TextStyle(color: Colors.white70),
                  ),
              ],
            ),
            trailing: CardActions(
              onEdit: () => openForm(editing: controller),
              onDelete: () => confirmDelete(
                'Kontroller “${controller.name}” löschen?',
                () => deleteController(controller),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> openForm({FermenterControllerModel? editing}) async {
    final nameCtrl = TextEditingController(text: editing?.name ?? '');
    final usernameCtrl = TextEditingController(text: editing?.username ?? '');
    final apiKeyCtrl = TextEditingController(text: editing?.apiKey ?? '');
    final notesCtrl = TextEditingController(text: editing?.notes ?? '');
    bool isDefault = editing?.isDefault ?? false;
    String? nameError;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(editing == null
              ? 'Kontroller hinzufügen'
              : 'Kontroller bearbeiten'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    errorText: nameError,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: usernameCtrl,
                  decoration: const InputDecoration(labelText: 'Username'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: apiKeyCtrl,
                  decoration: const InputDecoration(labelText: 'API Key'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Notizen'),
                ),
                CheckboxListTile(
                  value: isDefault,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Als Standard verwenden (★)'),
                  onChanged: (value) =>
                      setState(() => isDefault = value ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) {
                  setState(() => nameError = 'Name erforderlich');
                  return;
                }
                Navigator.of(dialogCtx).pop(true);
              },
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    final controller = FermenterControllerModel(
      id: editing?.id,
      userProfileId: widget.profileId,
      name: nameCtrl.text.trim(),
      isDefault: isDefault,
      username:
          usernameCtrl.text.trim().isEmpty ? null : usernameCtrl.text.trim(),
      apiKey: apiKeyCtrl.text.trim().isEmpty ? null : apiKeyCtrl.text.trim(),
      notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
    );

    try {
      final saved = await service.saveController(controller);
      if (!mounted) return;
      setState(() {
        if (saved.isDefault) {
          controllers = controllers
              .map((existing) => existing.id == saved.id
                  ? existing
                  : existing.copyWith(isDefault: false))
              .toList();
        }
        final index =
            controllers.indexWhere((element) => element.id == saved.id);
        if (index >= 0) {
          controllers[index] = saved;
        } else {
          controllers.add(saved);
        }
        sortControllers();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              editing == null
                  ? 'Kontroller erstellt'
                  : 'Kontroller aktualisiert',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speichern fehlgeschlagen: $e')),
      );
    }
  }

  void sortControllers() {
    controllers.sort((a, b) {
      if (a.isDefault != b.isDefault) {
        return a.isDefault ? -1 : 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }

  Future<void> deleteController(FermenterControllerModel controller) async {
    if (controller.id == null) return;
    try {
      await service.deleteController(controller.id!);
      setState(() {
        controllers.removeWhere((item) => item.id == controller.id);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kontroller "${controller.name}" gelöscht')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Löschen fehlgeschlagen: $e')));
    }
  }

  Future<void> confirmDelete(
    String title,
    Future<void> Function() onDelete,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content:
            const Text('Dieser Vorgang kann nicht rückgängig gemacht werden.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await onDelete();
    }
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay({this.message = 'Bitte warten …'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.35),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class LegacyRecipeResultPage extends StatelessWidget {
  const LegacyRecipeResultPage(
      {super.key, required this.prompt, required this.response});

  final String prompt;
  final String response;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rezept (Legacy)')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LegacyRecipeDisplayPage(
                    jsonResponse: response,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.receipt_long),
            label: const Text('Rezept darstellen'),
          ),
          const SizedBox(height: 24),
          Text(
            'Abgeschickter Prompt',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF0F172A),
              border: Border.all(color: Colors.white12),
            ),
            child: SelectableText(prompt),
          ),
          const SizedBox(height: 24),
          Text(
            'Antwort (JSON)',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF0F172A),
              border: Border.all(color: Colors.white12),
            ),
            child: SelectableText(response),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class LegacyRecipeDisplayPage extends StatelessWidget {
  const LegacyRecipeDisplayPage({super.key, required this.jsonResponse});

  final String jsonResponse;

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? parsed;
    try {
      final cleaned = _extractJson(jsonResponse);
      parsed = jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) {
      parsed = null;
    }

    final basisBier = _stringField(parsed?['basis_bier']);
    final bierTyp = _stringField(parsed?['bier_typ']);
    final title = (basisBier != null && bierTyp != null)
        ? 'Dein Bier Rezept für ein $basisBier im Stile eines $bierTyp'
        : 'Dein Bier Rezept';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: parsed == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Antwort konnte nicht als JSON gelesen werden.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                ..._buildSections(parsed),
              ],
            ),
    );
  }
}
