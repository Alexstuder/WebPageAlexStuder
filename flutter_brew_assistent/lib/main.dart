import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
import 'models/user_profile.dart';
import 'models/water_profile.dart';
import 'models/brew_kettle.dart';
import 'models/fermenter.dart';
import 'models/yeast_bank_entry.dart';
import 'models/malt_depot_entry.dart';
import 'models/fermenter_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  const BrewMateApp({super.key});

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
        UserProfilePage.routeName: (_) => const UserProfilePage(),
        DiscoveryWelcomePage.routeName: (_) => const DiscoveryWelcomePage(),
        RecipePromptPage.routeName: (_) => const RecipePromptPage(),
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
                'assets/icon.png',
                height: 72,
                semanticLabel: 'AiBrewGenius',
              ),
            ),
            Center(
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
              FineTuningGeneralPage(beerName: value),
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
              'assets/icon.png',
              height: 40,
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
  const UserProfilePage({super.key});

  static const String routeName = '/user-profile';

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final TextEditingController _userNameCtrl = TextEditingController();
  final TextEditingController _avatarUrlCtrl = TextEditingController();
  final TextEditingController _kettleBrandCtrl = TextEditingController();
  final TextEditingController _kettleTypeCtrl = TextEditingController();
  final TextEditingController _defaultBatchCtrl = TextEditingController();
  final TextEditingController _fermenterBrandCtrl = TextEditingController();
  final TextEditingController _fermenterTypeCtrl = TextEditingController();
  final TextEditingController _raptUserCtrl = TextEditingController();
  final TextEditingController _raptApiKeyCtrl = TextEditingController();
  final TextEditingController _waterProfileNameCtrl = TextEditingController();
  final TextEditingController _waterPhCtrl = TextEditingController();
  final TextEditingController _calciumCtrl = TextEditingController();
  final TextEditingController _magnesiumCtrl = TextEditingController();
  final TextEditingController _sodiumCtrl = TextEditingController();
  final TextEditingController _chlorideCtrl = TextEditingController();
  final TextEditingController _sulfateCtrl = TextEditingController();
  final TextEditingController _bicarbonateCtrl = TextEditingController();
  final UserProfileService _profileService = UserProfileService();
  final WaterProfileService _waterProfileService = WaterProfileService();
  List<WaterProfile> _waterProfiles = [];
  WaterProfile? _selectedWaterProfile;
  bool _isLoadingWaterProfiles = true;
  bool _isSavingWaterProfile = false;
  String? _waterProfilesError;
  bool _waterProfileIsDefault = false;

  static const List<String> _controllerOptions = [
    'Kein Controller',
    'R.A.P.T Temperature Controller',
    'Inkbird ITC-308',
  ];

  late String _selectedController;
  bool _isSaving = false;
  bool _isLoadingProfile = true;
  String? _loadError;
  static const String _profileId = UserProfileService.defaultProfileId;
  bool _hasWaterStats = false;
  double? _computedWaterPh;
  double _cationCharge = 0;
  double _anionCharge = 0;
  double? _ionBalancePercent;
  double? _so4ClRatio;
  double? _waterHardness;
  double? _waterAlkalinity;
  double? _residualAlkalinity;

  bool get _isRaptSelected =>
      _selectedController == 'R.A.P.T Temperature Controller';

  @override
  void initState() {
    super.initState();
    _selectedController = _controllerOptions.first;
    _loadProfile();
    _loadWaterProfiles();
  }

  @override
  void dispose() {
    _userNameCtrl.dispose();
    _avatarUrlCtrl.dispose();
    _kettleBrandCtrl.dispose();
    _kettleTypeCtrl.dispose();
    _defaultBatchCtrl.dispose();
    _fermenterBrandCtrl.dispose();
    _fermenterTypeCtrl.dispose();
    _raptUserCtrl.dispose();
    _raptApiKeyCtrl.dispose();
    _waterProfileNameCtrl.dispose();
    _waterPhCtrl.dispose();
    _calciumCtrl.dispose();
    _magnesiumCtrl.dispose();
    _sodiumCtrl.dispose();
    _chlorideCtrl.dispose();
    _sulfateCtrl.dispose();
    _bicarbonateCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileService.fetchProfile(_profileId);
      if (profile != null) {
        _userNameCtrl.text = profile.name;
        _avatarUrlCtrl.text = profile.avatarUrl;
        _kettleBrandCtrl.text = profile.kettleBrand;
        _kettleTypeCtrl.text = profile.kettleType;
        _defaultBatchCtrl.text =
            profile.defaultBatchLiters?.toString() ?? '';
        _fermenterBrandCtrl.text = profile.fermenterBrand;
        _fermenterTypeCtrl.text = profile.fermenterType;
        _selectedController = _controllerOptions.contains(profile.controller)
            ? profile.controller
            : _controllerOptions.first;
        if (_isRaptSelected) {
          _raptUserCtrl.text = profile.controllerUser ?? '';
          _raptApiKeyCtrl.text = profile.controllerApiKey ?? '';
        } else {
          _raptUserCtrl.clear();
          _raptApiKeyCtrl.clear();
        }
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

  Future<void> _loadWaterProfiles() async {
    setState(() {
      _isLoadingWaterProfiles = true;
      _waterProfilesError = null;
    });
    try {
      final profiles =
          await _waterProfileService.fetchProfiles(_profileId);
      if (!mounted) return;
      setState(() {
        _waterProfiles = profiles;
        _sortWaterProfiles();
      });
      if (profiles.isNotEmpty) {
        final initial = profiles.firstWhere(
          (p) => p.isDefault,
          orElse: () => profiles.first,
        );
        _applyWaterProfile(initial, recalc: true);
      } else {
        _startNewWaterProfile();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _waterProfilesError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingWaterProfiles = false;
        });
      }
    }
  }

  void _applyWaterProfile(WaterProfile profile, {bool recalc = true}) {
    setState(() {
      _selectedWaterProfile = profile;
      _waterProfileIsDefault = profile.isDefault;
      _waterProfileNameCtrl.text = profile.name;
      _waterPhCtrl.text = _doubleToText(profile.ph, emptyIfNull: true);
      _calciumCtrl.text = _doubleToText(profile.calciumPpm, emptyIfNull: true);
      _magnesiumCtrl.text =
          _doubleToText(profile.magnesiumPpm, emptyIfNull: true);
      _sodiumCtrl.text = _doubleToText(profile.sodiumPpm, emptyIfNull: true);
      _chlorideCtrl.text =
          _doubleToText(profile.chloridePpm, emptyIfNull: true);
      _sulfateCtrl.text = _doubleToText(profile.sulfatePpm, emptyIfNull: true);
      _bicarbonateCtrl.text =
          _doubleToText(profile.bicarbonatePpm, emptyIfNull: true);
    });
    if (recalc) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _recalculateWaterStats();
        }
      });
    }
  }

  void _startNewWaterProfile() {
    setState(() {
      _selectedWaterProfile = null;
      _waterProfileIsDefault = false;
      _waterProfileNameCtrl.clear();
      _waterPhCtrl.clear();
      _calciumCtrl.clear();
      _magnesiumCtrl.clear();
      _sodiumCtrl.clear();
      _chlorideCtrl.clear();
      _sulfateCtrl.clear();
      _bicarbonateCtrl.clear();
      _resetWaterStats();
    });
  }

  void _resetWaterStats() {
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

  Future<void> _handleSaveWaterProfile() async {
    final draft = _buildWaterProfileDraft();
    setState(() {
      _isSavingWaterProfile = true;
    });
    try {
      final saved = await _waterProfileService.saveProfile(draft);
      if (!mounted) return;
      setState(() {
        _upsertWaterProfile(saved);
        _selectedWaterProfile = saved;
        _waterProfileIsDefault = saved.isDefault;
      });
      _recalculateWaterStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wasserprofil gespeichert')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wasserprofil konnte nicht gespeichert werden: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingWaterProfile = false;
        });
      }
    }
  }

  WaterProfile _buildWaterProfileDraft() {
    final name = _waterProfileNameCtrl.text.trim().isEmpty
        ? 'Unbenanntes Profil'
        : _waterProfileNameCtrl.text.trim();
    return WaterProfile(
      id: _selectedWaterProfile?.id,
      userProfileId: _profileId,
      name: name,
      isDefault: _waterProfileIsDefault,
      ph: _parseOptionalDouble(_waterPhCtrl),
      calciumPpm: _parseControllerValue(_calciumCtrl),
      magnesiumPpm: _parseControllerValue(_magnesiumCtrl),
      sodiumPpm: _parseControllerValue(_sodiumCtrl),
      chloridePpm: _parseControllerValue(_chlorideCtrl),
      sulfatePpm: _parseControllerValue(_sulfateCtrl),
      bicarbonatePpm: _parseControllerValue(_bicarbonateCtrl),
    );
  }

  void _upsertWaterProfile(WaterProfile profile) {
    if (profile.isDefault) {
      _waterProfiles = _waterProfiles
          .map((p) => p.id == profile.id ? p : p.copyWith(isDefault: false))
          .toList();
    }
    final index =
        _waterProfiles.indexWhere((p) => p.id == profile.id);
    if (index >= 0) {
      _waterProfiles[index] = profile;
    } else {
      _waterProfiles.add(profile);
    }
    _sortWaterProfiles();
  }

  WaterProfile? _findWaterProfile(String? id) {
    if (id == null) return null;
    for (final profile in _waterProfiles) {
      if (profile.id == id) return profile;
    }
    return null;
  }

  void _sortWaterProfiles() {
    _waterProfiles.sort((a, b) {
      if (a.isDefault != b.isDefault) {
        return a.isDefault ? -1 : 1;
      }
      return a.name.compareTo(b.name);
    });
  }

  String? get _selectedWaterProfileId {
    final id = _selectedWaterProfile?.id;
    if (id == null) return null;
    return _waterProfiles.any((profile) => profile.id == id) ? id : null;
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
    final double? defaultBatch =
        double.tryParse(_defaultBatchCtrl.text.replaceAll(',', '.'));

    final List<YeastEntryModel> yeastEntries = const [];

    const maltEntries = <MaltDepotEntry>[];

    final profile = UserProfile(
      id: _profileId,
      name: _userNameCtrl.text.trim(),
      avatarUrl: _avatarUrlCtrl.text.trim(),
      kettleBrand: _kettleBrandCtrl.text.trim(),
      kettleType: _kettleTypeCtrl.text.trim(),
      defaultBatchLiters: defaultBatch,
      fermenterBrand: _fermenterBrandCtrl.text.trim(),
      fermenterType: _fermenterTypeCtrl.text.trim(),
      controller: _selectedController,
      controllerUser: _isRaptSelected ? _raptUserCtrl.text.trim() : null,
      controllerApiKey: _isRaptSelected ? _raptApiKeyCtrl.text.trim() : null,
      yeastEntries: yeastEntries,
      maltDepot: maltEntries,
    );

    setState(() {
      _isSaving = true;
    });

    try {
      await _profileService.saveProfile(profile);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil gespeichert')),
      );
    } catch (e) {
      if (!mounted) return;
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
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          const Icon(Icons.save_rounded),
                        const SizedBox(width: 12),
                        Text(_isSaving ? 'Speichert …' : 'Profil speichern'),
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
        builder: (_) => BrewKettleManagerPage(profileId: _profileId),
      ),
    );
  }

  void _openFermenterManager() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FermenterManagerPage(profileId: _profileId),
      ),
    );
  }

  void _openYeastBankManager() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => YeastBankManagerPage(profileId: _profileId),
      ),
    );
  }

  void _openMaltDepotManager() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MaltDepotManagerPage(profileId: _profileId),
      ),
    );
  }

  void _openFermenterControllerManager() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FermenterControllerManagerPage(profileId: _profileId),
      ),
    );
  }

  void _openWaterDialog() {
    if (_hasWaterInput) {
      _recalculateWaterStats();
    }
    final theme = Theme.of(context);
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF020617),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 760,
              minWidth: 620,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_waterProfilesError != null) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.red.shade900.withValues(alpha: 0.35),
                      ),
                      child: Text(
                        'Wasserprofile konnten nicht geladen werden: $_waterProfilesError',
                      ),
                    ),
                  ],
                  if (_isLoadingWaterProfiles)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownMenu<String>(
                          initialSelection: _selectedWaterProfileId,
                          label: const Text('Gespeichertes Profil'),
                          enabled: _waterProfiles.isNotEmpty,
                          onSelected: _waterProfiles.isEmpty
                              ? null
                              : (value) {
                                  final profile = _findWaterProfile(value);
                                  if (profile != null) {
                                    _applyWaterProfile(profile, recalc: true);
                                  }
                                },
                          dropdownMenuEntries: _waterProfiles
                              .where((profile) => profile.id != null)
                              .map(
                                (profile) => DropdownMenuEntry<String>(
                                  value: profile.id!,
                                  label:
                                      '${profile.name}${profile.isDefault ? ' ★' : ''}',
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed:
                            _isSavingWaterProfile ? null : _startNewWaterProfile,
                        icon: const Icon(Icons.add),
                        label: const Text('Neu'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _waterProfileNameCtrl,
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
                          controller: _waterPhCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'pH',
                            hintText: '7.2',
                          ),
                        ),
                      ),
                    ],
                  ),
                  CheckboxListTile(
                    value: _waterProfileIsDefault,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Als Standard verwenden (★)'),
                    onChanged: (value) {
                      setState(() {
                        _waterProfileIsDefault = value ?? false;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Icon(
                        Icons.compass_calibration,
                        color: Color(0xFFEAB308),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Wasserprofil',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white60),
                      ),
                    ],
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
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _WaterIonTile(
                          title: 'Magnesium Mg²⁺',
                          controller: _magnesiumCtrl,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _WaterIonTile(
                          title: 'Natrium Na⁺',
                          controller: _sodiumCtrl,
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
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _WaterIonTile(
                          title: 'Sulfat SO₄²⁻',
                          controller: _sulfateCtrl,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _WaterIonTile(
                          title: 'Bicarbonat HCO₃⁻',
                          controller: _bicarbonateCtrl,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
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
                            'Die endgültige Berechnung der Ionebilanz folgt '
                            'im nächsten Schritt.',
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
                              value: _formatNumber(_waterAlkalinity, fractionDigits: 0),
                            ),
                            _WaterStatTile(
                              width: tileWidth,
                              label: 'Restalkalinität',
                              value: _formatNumber(_residualAlkalinity, fractionDigits: 0),
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
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FilledButton.icon(
                        onPressed: _isSavingWaterProfile
                            ? null
                            : _handleSaveWaterProfile,
                        icon: _isSavingWaterProfile
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          _isSavingWaterProfile ? 'Speichert …' : 'Speichern',
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Zurück'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _recalculateWaterStats() {
    final double ca = _parseControllerValue(_calciumCtrl);
    final double mg = _parseControllerValue(_magnesiumCtrl);
    final double na = _parseControllerValue(_sodiumCtrl);
    final double cl = _parseControllerValue(_chlorideCtrl);
    final double so4 = _parseControllerValue(_sulfateCtrl);
    final double hco3 = _parseControllerValue(_bicarbonateCtrl);
    final double ph = _parseControllerValue(_waterPhCtrl);

    final double cationMeq = (ca / 20.0) + (mg / 12.15) + (na / 23.0);
    final double anionMeq = (cl / 35.45) + (so4 / 48.0) + (hco3 / 61.0);

    final double? ionBalance = (cationMeq > 0 && anionMeq > 0)
        ? ((cationMeq - anionMeq) / ((cationMeq + anionMeq) / 2)) * 100
        : null;

    final double? ratio = cl > 0 ? so4 / cl : null;
    final double hardness = (2.5 * ca) + (4.1 * mg);
    final double alkalinity = hco3 * (50 / 61);
    final double residual = alkalinity -
        ((2.5 * ca) / 3.5) -
        ((4.1 * mg) / 7.0);

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

  double _parseControllerValue(TextEditingController controller) {
    return double.tryParse(
          controller.text.replaceAll(',', '.'),
        ) ??
        0.0;
  }

  double? _parseOptionalDouble(TextEditingController controller) {
    final text = controller.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text.replaceAll(',', '.'));
  }

  bool get _hasWaterInput {
    final controllers = [
      _waterProfileNameCtrl,
      _waterPhCtrl,
      _calciumCtrl,
      _magnesiumCtrl,
      _sodiumCtrl,
      _chlorideCtrl,
      _sulfateCtrl,
      _bicarbonateCtrl,
    ];
    return controllers.any((c) => c.text.trim().isNotEmpty);
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

  Widget _buildUserSection() {
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
                CircleAvatar(
                  radius: 42,
                  backgroundColor: const Color(0xFF1D4ED8),
                  child: Icon(
                    Icons.person_outline,
                    size: 36,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _userNameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'z. B. Alex Studer',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _avatarUrlCtrl,
              decoration: const InputDecoration(
                labelText: 'Avatar URL',
                hintText: 'https://…/avatar.png',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceButtons() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _managerButton(
          icon: Icons.water_drop_outlined,
          label: 'Wasserprofile',
          onPressed: _openWaterDialog,
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
          icon: Icons.biotech_outlined,
          label: 'Hefedatenbank',
          onPressed: _openYeastBankManager,
        ),
        _managerButton(
          icon: Icons.warehouse_outlined,
          label: 'Malzdepot',
          onPressed: _openMaltDepotManager,
        ),
      ],
    );
  }

  Widget _managerButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
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
  });

  final String title;
  final TextEditingController controller;

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
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Wert',
              hintText: 'z. B. 50',
            ),
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

class BrewKettleManagerPage extends StatefulWidget {
  const BrewKettleManagerPage({super.key, required this.profileId});

  final String profileId;

  @override
  State<BrewKettleManagerPage> createState() => _BrewKettleManagerPageState();
}

class _BrewKettleManagerPageState extends State<BrewKettleManagerPage> {
  final BrewKettleService _service = BrewKettleService();
  bool _isLoading = true;
  List<BrewKettle> _kettles = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Neu'),
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
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _openForm(editing: kettle),
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
    String? brandError;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title:
              Text(editing == null ? 'Braukessel hinzufügen' : 'Braukessel bearbeiten'),
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
              editing == null ? 'Braukessel erstellt' : 'Braukessel aktualisiert',
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
}

class FermenterManagerPage extends StatefulWidget {
  const FermenterManagerPage({super.key, required this.profileId});

  final String profileId;

  @override
  State<FermenterManagerPage> createState() => _FermenterManagerPageState();
}

class _FermenterManagerPageState extends State<FermenterManagerPage> {
  final FermenterService _service = FermenterService();
  bool _isLoading = true;
  List<Fermenter> _fermenters = [];
  String? _error;

  @override
  void initState() {
    super.initState();
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Neu'),
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
            leading: Icon(
              fermenter.isDefault ? Icons.star : Icons.star_border,
              color: fermenter.isDefault ? Colors.amber : Colors.white54,
            ),
            title: Text(titleText.trim()),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (fermenter.volumeLiters != null)
                  Text('Volumen: ${fermenter.volumeLiters!.toStringAsFixed(1)} L'),
                Text('Heizung: ${fermenter.hasHeating ? 'Ja' : 'Nein'}'),
                Text('Kühlung: ${fermenter.hasCooling ? 'Ja' : 'Nein'}'),
                if ((fermenter.notes ?? '').isNotEmpty)
                  Text(
                    fermenter.notes!,
                    style: const TextStyle(color: Colors.white70),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _openForm(editing: fermenter),
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
    bool isDefault = editing?.isDefault ?? false;
    String? brandError;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(
              editing == null ? 'Fermentierer hinzufügen' : 'Fermentierer bearbeiten'),
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
              editing == null ? 'Fermentierer erstellt' : 'Fermentierer aktualisiert',
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
}

class YeastBankManagerPage extends StatefulWidget {
  const YeastBankManagerPage({super.key, required this.profileId});

  final String profileId;

  @override
  State<YeastBankManagerPage> createState() => _YeastBankManagerPageState();
}

class _YeastBankManagerPageState extends State<YeastBankManagerPage> {
  final YeastBankService _service = YeastBankService();
  bool _isLoading = true;
  List<YeastBankEntry> _entries = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await _service.fetchEntries(widget.profileId);
      if (!mounted) return;
      setState(() {
        _entries = items;
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
        title: const Text('Hefedatenbank'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Neu'),
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
            title: Text('${entry.brand} · ${entry.strain}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((entry.style ?? '').isNotEmpty) Text('Stil: ${entry.style}'),
                if (entry.attenuationMin != null || entry.attenuationMax != null)
                  Text(
                    'EVG: ${_rangeString(entry.attenuationMin, entry.attenuationMax, suffix: '%')}',
                  ),
                if (entry.temperatureMin != null || entry.temperatureMax != null)
                  Text(
                    'Temp: ${_rangeString(entry.temperatureMin, entry.temperatureMax, suffix: '°C')}',
                  ),
                if ((entry.url ?? '').isNotEmpty)
                  Text('URL: ${entry.url}'),
                if ((entry.notes ?? '').isNotEmpty)
                  Text(
                    entry.notes!,
                    style: const TextStyle(color: Colors.white70),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _openForm(editing: entry),
            ),
          ),
        );
      },
    );
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
    String? brandError;
    String? strainError;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(
              editing == null ? 'Hefe hinzufügen' : 'Hefe bearbeiten'),
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
                  controller: strainCtrl,
                  decoration: InputDecoration(
                    labelText: 'Stamm',
                    errorText: strainError,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: styleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Stil / Verwendung',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'URL',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: attenuationMinCtrl,
                        decoration: const InputDecoration(
                          labelText: 'EVG min %',
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: attenuationMaxCtrl,
                        decoration: const InputDecoration(
                          labelText: 'EVG max %',
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: tempMinCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Temp. min (°C)',
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: tempMaxCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Temp. max (°C)',
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Notizen',
                  ),
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
      brand: brandCtrl.text.trim(),
      strain: strainCtrl.text.trim(),
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
      if (!mounted) return;
      setState(() {
        final index = _entries.indexWhere((element) => element.id == saved.id);
        if (index >= 0) {
          _entries[index] = saved;
        } else {
          _entries.add(saved);
        }
        _entries.sort(
          (a, b) =>
              '${a.brand} ${a.strain}'.toLowerCase().compareTo('${b.brand} ${b.strain}'.toLowerCase()),
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

  double? _parseDouble(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned.replaceAll(',', '.'));
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
    _profileFuture =
        UserProfileService().fetchDefaultProfile();
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
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _requestRecipe() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _response = null;
    });

    try {
      final recipe = await _service.brewRecipe(prompt);
      setState(() => _response = recipe);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openHomepage() async {
    final uri = Uri.parse('https://alexstuder.run.place/');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konnte Hauptseite nicht öffnen.')),
      );
    }
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: _UserNameBanner(),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Image.asset(
                    'assets/icon.png',
                    height: 96,
                    semanticLabel: 'AiBrewGenius',
                  ),
                ),
                TextField(
                  controller: _promptController,
                  maxLines: 5,
                  minLines: 3,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText:
                        'Beschreibe deinen Wunsch-Sud (Stil, Aromen, ABV …)',
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _requestRecipe,
                    icon: const Icon(Icons.local_drink),
                    label: Text(
                        _isLoading ? 'Braut Rezept …' : 'Rezept erstellen'),
                  ),
                ),
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
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null
                            ? _ErrorNotice(
                                message: _error!,
                                onRetry: _requestRecipe,
                              )
                            : _response != null
                                ? _RecipeCard(text: _response!, isWide: isWide)
                                : const _Placeholder(),
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

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.text, required this.isWide});

  final String text;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Card(
        color: const Color(0xFF0F172A),
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: EdgeInsets.all(isWide ? 28 : 20),
          child: SelectableText(
            text,
            style: const TextStyle(height: 1.5, fontSize: 16),
          ),
        ),
      ),
    );
  }
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.warning_amber_rounded,
            size: 48, color: Colors.amber.shade300),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 14),
        OutlinedButton(
          onPressed: onRetry,
          child: const Text('Erneut versuchen'),
        ),
      ],
    );
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
  FineTuningProfile({required this.beerName});

  final String beerName;
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
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
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
  const FineTuningGeneralPage({super.key, required this.beerName});

  final String beerName;

  @override
  State<FineTuningGeneralPage> createState() => _FineTuningGeneralPageState();
}

class _FineTuningGeneralPageState extends State<FineTuningGeneralPage> {
  late final FineTuningProfile profile;

  @override
  void initState() {
    super.initState();
    profile = FineTuningProfile(beerName: widget.beerName);
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
              'assets/icon.png',
              height: 40,
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
                      onChanged: (v) =>
                          setState(() => profile.hopHerbal = v),
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
                      onChanged: (v) =>
                          setState(() => profile.hopFloral = v),
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
                      onChanged: (v) =>
                          setState(() => profile.hopFruity = v),
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
                      onChanged: (v) =>
                          setState(() => profile.hopNose = v),
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
                      onChanged: (v) =>
                          setState(() => profile.hopPalate = v),
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
                      onChanged: (v) =>
                          setState(() => profile.hopFinish = v),
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
              'assets/icon.png',
              height: 40,
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
              'assets/icon.png',
              height: 40,
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
              onChanged: (v) => setState(() => widget.profile.mainRoast = v),
              baselineKey: 'mainRoast',
            ),
            const Spacer(),
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
            )
          ],
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
              'assets/icon.png',
              height: 40,
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
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RecipeSummaryPage(
                        profile: widget.profile,
                      ),
                    ),
                  );
                },
                child: const Text('Weiter zu Rezept erstellen ?'),
              ),
            )
          ],
        ),
      ),
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
              'assets/icon.png',
              height: 40,
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
  const _SummarySection(this.title, this.entries,
      {this.dividerBefore = false});

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
      _SummaryEntry('Kräuterig', profile.hopHerbal,
          baselineKey: 'hopHerbal'),
      _SummaryEntry('Blumig', profile.hopFloral,
          baselineKey: 'hopFloral'),
      _SummaryEntry('Fruchtig', profile.hopFruity,
          baselineKey: 'hopFruity'),
    ]),
    _SummarySection('Verteilung', [
      _SummaryEntry('Nase', profile.hopNose,
          baselineKey: 'hopNose'),
      _SummaryEntry('Gaumen', profile.hopPalate,
          baselineKey: 'hopPalate'),
      _SummaryEntry('Abgang', profile.hopFinish,
          baselineKey: 'hopFinish'),
    ]),
    _SummarySection('Antrunk', [
      _SummaryEntry('Mundgefühl', profile.mouthfeel,
          baselineKey: 'mouthfeel'),
      _SummaryEntry('Malzaroma', profile.antrunkMalt,
          baselineKey: 'antrunkMalt'),
      _SummaryEntry('Röstmalzaroma', profile.antrunkRoast,
          baselineKey: 'antrunkRoast'),
    ], dividerBefore: true),
    _SummarySection('Haupttrunk', [
      _SummaryEntry('süffig', profile.smooth,
          baselineKey: 'smooth'),
      _SummaryEntry('vollmundig', profile.fullBody,
          baselineKey: 'fullBody'),
      _SummaryEntry('Malzaroma', profile.mainMalt,
          baselineKey: 'mainMalt'),
      _SummaryEntry('Röstaroma', profile.mainRoast,
          baselineKey: 'mainRoast'),
    ]),
    _SummarySection('Nachtrunk', [
      _SummaryEntry('abklingen', profile.fade,
          baselineKey: 'fade'),
      _SummaryEntry('erfrischend', profile.fresh,
          baselineKey: 'fresh'),
      _SummaryEntry('trocken', profile.dry,
          baselineKey: 'dry'),
      _SummaryEntry('langanhaltend', profile.lasting,
          baselineKey: 'lasting'),
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
  return widgets;
}

String _formatSummaryDiff(
    FineTuningProfile profile, _SummaryEntry entry) {
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
          final points = _markerPoints(baselineKey, width);
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

  List<Widget> _markerPoints(String key, double width) {
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
                    style:
                        const TextStyle(fontSize: 10, color: Colors.white54),
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
                    style:
                        const TextStyle(fontSize: 10, color: Colors.white54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Beschreibe dein Traum-Bier und lass den Assistenten ein komplettes Rezept entwerfen.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
      ),
    );
  }
}

class MaltDepotManagerPage extends StatefulWidget {
  const MaltDepotManagerPage({super.key, required this.profileId});

  final String profileId;

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
  final BrewKettleService _kettleService = BrewKettleService();
  final WaterProfileService _waterService = WaterProfileService();
  final FermenterService _fermenterService = FermenterService();
  final FermenterControllerService _controllerService =
      FermenterControllerService();
  final MaltDepotService _maltService = MaltDepotService();
  final OpenAIService _openAIService = OpenAIService();

  bool _isLoading = true;
  bool _isCalculating = false;
  String? _error;

  List<BrewKettle> _kettles = [];
  List<WaterProfile> _waterProfiles = [];
  List<Fermenter> _fermenters = [];
  List<FermenterControllerModel> _controllers = [];
  List<MaltDepotEntryModel> _maltDepots = [];

  BrewKettle? _selectedKettle;
  WaterProfile? _selectedWaterProfile;
  Fermenter? _selectedFermenter;
  FermenterControllerModel? _selectedController;
  MaltDepotEntryModel? _selectedMaltDepot;
  final TextEditingController _batchSizeCtrl = TextEditingController();
  final FocusNode _batchSizeFocusNode = FocusNode();

  static const String _profileId = UserProfileService.defaultProfileId;

  @override
  void initState() {
    super.initState();
    _loadEquipment();
  }

  @override
  void dispose() {
    _batchSizeCtrl.dispose();
    _batchSizeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadEquipment() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _kettleService.fetchKettles(_profileId),
        _waterService.fetchProfiles(_profileId),
        _fermenterService.fetchFermenters(_profileId),
        _controllerService.fetchControllers(_profileId),
        _maltService.fetchEntries(_profileId),
      ]);
      if (!mounted) return;
      setState(() {
        _kettles = results[0] as List<BrewKettle>;
        _waterProfiles = results[1] as List<WaterProfile>;
        _fermenters = results[2] as List<Fermenter>;
        _controllers = results[3] as List<FermenterControllerModel>;
        _maltDepots = results[4] as List<MaltDepotEntryModel>;
        _selectedKettle = _pickDefault(_kettles, (k) => k.isDefault);
        _selectedWaterProfile =
            _pickDefault(_waterProfiles, (p) => p.isDefault);
        _selectedFermenter =
            _pickDefault(_fermenters, (f) => f.isDefault);
        _selectedController =
            _pickDefault(_controllers, (c) => c.isDefault);
        _selectedMaltDepot =
            _maltDepots.isNotEmpty ? _maltDepots.first : null;
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
        title: const Text('Equipment'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Equipment konnte nicht geladen werden:\n$_error',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadEquipment,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      TextField(
                        controller: _batchSizeCtrl,
                        focusNode: _batchSizeFocusNode,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Ziel Menge in Liter',
                          hintText: '20',
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildRecipeButton(),
                      const SizedBox(height: 24),
                      _EquipmentSection<BrewKettle>(
                        title: 'Braukessel',
                        items: _kettles,
                        selected: _selectedKettle,
                        onSelected: (kettle) {
                          if (kettle == null) return;
                          setState(() => _selectedKettle = kettle);
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
                        items: _waterProfiles,
                        selected: _selectedWaterProfile,
                        onSelected: (profile) {
                          if (profile == null) return;
                          setState(() => _selectedWaterProfile = profile);
                        },
                        isDefaultBuilder: (profile) => profile.isDefault,
                        labelBuilder: (profile) => profile.name,
                      ),
                      const SizedBox(height: 18),
                      _EquipmentSection<Fermenter>(
                        title: 'Fermentierer',
                        items: _fermenters,
                        selected: _selectedFermenter,
                        onSelected: (fermenter) {
                          if (fermenter == null) return;
                          setState(() => _selectedFermenter = fermenter);
                        },
                        isDefaultBuilder: (fermenter) => fermenter.isDefault,
                        labelBuilder: (fermenter) => fermenter.type?.isNotEmpty == true
                            ? '${fermenter.brand} ${fermenter.type}'
                            : fermenter.brand,
                      ),
                      const SizedBox(height: 18),
                      _EquipmentSection<FermenterControllerModel>(
                        title: 'Kontroller',
                        items: _controllers,
                        selected: _selectedController,
                        onSelected: (controller) {
                          if (controller == null) return;
                          setState(() => _selectedController = controller);
                        },
                        isDefaultBuilder: (controller) => controller.isDefault,
                        labelBuilder: (controller) => controller.name,
                      ),
                      const SizedBox(height: 18),
                      _EquipmentSection<MaltDepotEntryModel>(
                        title: 'Malzdepot',
                        items: _maltDepots,
                        selected: _selectedMaltDepot,
                        onSelected: (entry) {
                          if (entry == null) return;
                          setState(() => _selectedMaltDepot = entry);
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

  Widget _buildRecipeButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isCalculating ? null : _generateRecipe,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          side: const BorderSide(color: Colors.purple),
          foregroundColor: Colors.white,
          backgroundColor: Colors.purple.withValues(alpha: 0.15),
        ),
        icon: _isCalculating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.science_rounded),
        label: Text(_isCalculating ? 'Berechne …' : 'Rezept erstellen'),
      ),
    );
  }

  Future<void> _generateRecipe() async {
    final batchSize = _batchSizeCtrl.text.trim();
    if (batchSize.isEmpty) {
      _batchSizeFocusNode.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Ziel Menge eingeben')),
      );
      return;
    }
    try {
      setState(() {
        _isCalculating = true;
      });
      final template = await rootBundle.loadString('prompt/rezept_basis');
      final prompt = _buildPrompt(template);
      final response = await _openAIService.brewRecipe(prompt);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RecipeResultPage(
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
          _isCalculating = false;
        });
      }
    }
  }

  T? _pickDefault<T>(List<T> items, bool Function(T item) isDefault) {
    if (items.isEmpty) return null;
    for (final item in items) {
      if (isDefault(item)) return item;
    }
    return items.first;
  }

  String _buildPrompt(String template) {
    String formatScore(double value) => value.toStringAsFixed(2);
    String formatWater(double? value) => (value ?? 0).toStringAsFixed(2);
    String formatText(String? value) =>
        (value == null || value.trim().isEmpty) ? 'unbekannt' : value.trim();
    String formatBool(bool? value) => (value ?? false) ? 'true' : 'false';

    final water = _selectedWaterProfile;
    final replacements = <String, String>{
      'bier_typ': widget.profile.beerName,
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
      'kettle_brand': formatText(_selectedKettle?.brand),
      'kettle_type': formatText(_selectedKettle?.model),
      'fermenter_brand': formatText(_selectedFermenter?.brand),
      'fermenter_type': formatText(_selectedFermenter?.type),
      'fermenter_heating': formatBool(_selectedFermenter?.hasHeating),
      'fermenter_cooling': formatBool(_selectedFermenter?.hasCooling),
      'shop_url': formatText(_selectedMaltDepot?.url),
      'target_volume_l':
          _batchSizeCtrl.text.trim().isEmpty ? '0' : _batchSizeCtrl.text.trim(),
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
    final T current = selected ?? _defaultItem() ?? items.first;
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
                        label: _decorateLabel(item),
                      ),
                    )
                    .toList(),
              )
            else
              Text(_decorateLabel(current)),
          ],
        ),
      ),
    );
  }

  String _decorateLabel(T item) {
    final label = labelBuilder(item);
    final isDefault = isDefaultBuilder?.call(item) ?? false;
    return isDefault ? '$label ★' : label;
  }

  T? _defaultItem() {
    if (isDefaultBuilder == null) return null;
    for (final item in items) {
      if (isDefaultBuilder!(item)) return item;
    }
    return null;
  }
}

class RecipeResultPage extends StatelessWidget {
  const RecipeResultPage({super.key, required this.prompt, required this.response});

  final String prompt;
  final String response;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rezept')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RecipeDisplayPage(
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

class RecipeDisplayPage extends StatelessWidget {
  const RecipeDisplayPage({super.key, required this.jsonResponse});

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

List<Widget> _buildSections(Map<String, dynamic> parsed) {
  final zutaten = _asMap(parsed['Zutaten'] ?? parsed['zutaten']);
  final prozess = _asMap(parsed['Prozessdaten'] ?? parsed['prozessdaten']);
  final malzdepot =
      _asMap(parsed['Malzdepot_Einkauf'] ?? parsed['malzdepot_einkauf']);

  final sections = <Widget>[
    _RecipeSection(
      title: 'Zutaten – Original Malz',
      entries: _formatList(zutaten['Original_Malz'] ?? zutaten['original_malz']),
    ),
    const Divider(height: 32, color: Colors.white24),
    _RecipeSection(
      title: 'Zutaten – Original Hopfen',
      entries:
          _formatList(zutaten['Original_Hopfen'] ?? zutaten['original_hopfen']),
    ),
    const Divider(height: 32, color: Colors.white24),
    _RecipeSection(
      title: 'Zutaten – Original Hefe',
      entries:
          _formatList(zutaten['Original_Hefe'] ?? zutaten['original_hefe']),
    ),
    const Divider(height: 32, color: Colors.white24),
    _RecipeSection(
      title: 'Spezialzutaten',
      entries:
          _formatList(zutaten['Spezialzutaten'] ?? zutaten['spezialzutaten']),
    ),
    const Divider(height: 32, color: Colors.white24),
    _RecipeSection(
      title: 'Wasseraufbereitung',
      entries: _formatList(
        zutaten['Wasseraufbereitung'] ?? zutaten['wasseraufbereitung'],
      ),
    ),
    const Divider(height: 32, color: Colors.white24),
    _RecipeSection(
      title: 'Malzdepot – Shops',
      entries: _formatMalzdepotShops(malzdepot['Shops'] ?? malzdepot['shops']),
    ),
    const Divider(height: 32, color: Colors.white24),
    _RecipeSection(
      title: 'Malzdepot – Empfehlung',
      entries:
          _formatList(malzdepot['Empfehlung'] ?? malzdepot['empfehlung']),
    ),
    const Divider(height: 32, color: Colors.white24),
    _RecipeSection(
      title: 'Maischeplan',
      entries: _formatList(prozess['Maischeplan'] ?? prozess['maischeplan']),
    ),
    const Divider(height: 32, color: Colors.white24),
    _RecipeSection(
      title: 'Kochplan',
      entries: _formatKochplan(
        prozess['Kochzeit_und_Kochphasen'] ?? prozess['kochzeit_und_kochphasen'],
      ),
    ),
    const Divider(height: 32, color: Colors.white24),
    _RecipeSection(
      title: 'Gärplan',
      entries: _formatGaerplan(
        prozess['Gaerplan'] ?? prozess['Gärplan'] ?? prozess['gaerplan'],
      ),
    ),
    const Divider(height: 32, color: Colors.white24),
    _RecipeSection(
      title: 'Abfüllung & Lagern',
      entries: _formatList(
        prozess['Abfuellung_ins_Keg'] ?? prozess['abfuellung_ins_keg'],
      ),
    ),
    const Divider(height: 32, color: Colors.white24),
    _RecipeSection(
      title: 'Notizen',
      entries: _formatList(parsed['Notizen'] ?? parsed['notizen']),
    ),
  ];
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

List<_RecipeEntry> _formatMalzdepotShops(dynamic input) {
  if (input == null) return [const _RecipeEntry(text: 'Keine Angaben')];
  final shops = input is List ? input : [input];
  if (shops.isEmpty) return [const _RecipeEntry(text: 'Keine Angaben')];
  final entries = <_RecipeEntry>[];

  for (final shop in shops) {
    if (shop is! Map) {
      entries.add(_entry(shop.toString()));
      continue;
    }
    final shopMap = shop.map((key, val) => MapEntry(key.toString(), val));
    final shopName =
        _stringField(shopMap['Shop_Name'] ?? shopMap['shop_name']) ??
            'Shop';
    final shopUrl =
        _stringField(shopMap['Shop_URL'] ?? shopMap['shop_url']);

    entries.add(
      _RecipeEntry(
        text: shopUrl != null ? '$shopName ($shopUrl)' : shopName,
        link: shopUrl,
      ),
    );

    void addCategory(String label, dynamic data) {
      final formatted = _formatList(data);
      entries.add(_entry('$label:'));
      entries.addAll(_prefixEntries(formatted, '  - '));
    }

    addCategory('Malz', shopMap['Malz'] ?? shopMap['malz']);
    addCategory('Hopfen', shopMap['Hopfen'] ?? shopMap['hopfen']);
    addCategory('Hefe', shopMap['Hefe'] ?? shopMap['hefe']);

    final abdeckung = shopMap['Abdeckung'] ?? shopMap['abdeckung'];
    if (abdeckung != null) {
      entries.add(_entry('Abdeckung:'));
      entries.addAll(_prefixEntries(_formatList(abdeckung), '  - '));
    }

    final bewertung =
        shopMap['Gesamtbewertung'] ?? shopMap['gesamtbewertung'];
    if (bewertung != null) {
      entries.add(_entry('Bewertung: ${_formatSimpleValue(bewertung)}'));
    }

    entries.add(const _RecipeEntry(text: ''));
  }

  return entries.isEmpty ? [const _RecipeEntry(text: 'Keine Angaben')] : entries;
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
      lines.add(_entry(
          'Gesamte Kochdauer: ${input['Gesamte_Kochdauer']} min'));
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
    final text =
        parts.isEmpty ? (url ?? 'Keine Angaben') : parts.join(', ');
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
  final MaltDepotService _service = MaltDepotService();
  bool _isLoading = true;
  List<MaltDepotEntryModel> _entries = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await _service.fetchEntries(widget.profileId);
      if (!mounted) return;
      setState(() {
        _entries = items;
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
      appBar: AppBar(title: const Text('Malzdepot')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Neu'),
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
          'Konnte Malzdepot nicht laden:\n$_error',
          textAlign: TextAlign.center,
        ),
      );
    }
    if (_entries.isEmpty) {
      return const Center(child: Text('Noch keine Einträge.'));
    }
    return ListView.separated(
      itemCount: _entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = _entries[index];
        return Card(
          color: const Color(0xFF0F172A),
          child: ListTile(
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
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _openForm(editing: entry),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openForm({MaltDepotEntryModel? editing}) async {
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
      final saved = await _service.saveEntry(entry);
      if (!mounted) return;
      setState(() {
        final index = _entries.indexWhere((element) => element.id == saved.id);
        if (index >= 0) {
          _entries[index] = saved;
        } else {
          _entries.add(saved);
        }
        _entries.sort(
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
}


class FermenterControllerManagerPage extends StatefulWidget {
  const FermenterControllerManagerPage({super.key, required this.profileId});

  final String profileId;

  @override
  State<FermenterControllerManagerPage> createState() =>
      _FermenterControllerManagerPageState();
}

class _FermenterControllerManagerPageState
    extends State<FermenterControllerManagerPage> {
  final FermenterControllerService _service = FermenterControllerService();
  bool _isLoading = true;
  List<FermenterControllerModel> _controllers = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await _service.fetchControllers(widget.profileId);
      if (!mounted) return;
      setState(() {
        _controllers = items;
        _sortControllers();
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
      appBar: AppBar(title: const Text('Fermentierer-Kontroller')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Neu'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Text(
          'Konnte Kontroller nicht laden:\n$_error',
          textAlign: TextAlign.center,
        ),
      );
    }
    if (_controllers.isEmpty) {
      return const Center(child: Text('Noch keine Controller vorhanden.'));
    }
    return ListView.separated(
      itemCount: _controllers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final controller = _controllers[index];
        return Card(
          color: const Color(0xFF0F172A),
          child: ListTile(
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
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _openForm(editing: controller),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openForm({FermenterControllerModel? editing}) async {
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
      final saved = await _service.saveController(controller);
      if (!mounted) return;
      setState(() {
        if (saved.isDefault) {
          _controllers = _controllers
              .map((existing) => existing.id == saved.id
                  ? existing
                  : existing.copyWith(isDefault: false))
              .toList();
        }
        final index =
            _controllers.indexWhere((element) => element.id == saved.id);
        if (index >= 0) {
          _controllers[index] = saved;
        } else {
          _controllers.add(saved);
        }
        _sortControllers();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              editing == null ? 'Kontroller erstellt' : 'Kontroller aktualisiert',
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

  void _sortControllers() {
    _controllers.sort((a, b) {
      if (a.isDefault != b.isDefault) {
        return a.isDefault ? -1 : 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
  }
}
