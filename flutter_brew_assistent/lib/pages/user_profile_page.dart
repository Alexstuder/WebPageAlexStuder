import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;

import '../models/user_profile.dart';
import '../services/user_profile_service.dart';
import '../services/water_profile_service.dart';
import '../services/brew_kettle_service.dart';
import '../services/fermenter_service.dart';
import '../services/fermenter_controller_service.dart';
import '../services/malt_depot_service.dart';
import '../services/packaging_profile_service.dart';
import '../services/fining_agents_service.dart';
import '../services/yeast_bank_service.dart';

import 'generated_recipes_list_page.dart';
import 'water_profile_manager_page.dart';
import 'brew_kettle_manager_page.dart';
import 'fermenter_manager_page.dart';
import 'fermenter_controller_manager_page.dart';
import 'packaging_profile_manager_page.dart';
import 'fining_agents_page.dart';
import 'how_to_page.dart';
import 'malt_depot_manager_page.dart';
import 'integrations_page.dart';
import 'brewfather_menu_page.dart';
import 'yeast_bank_manager_page.dart';
import 'available_ingredients_page.dart';
import 'hops_manager_page.dart';
import 'miscs_manager_page.dart';
import 'recipes_list_page.dart';
import 'batches_list_page.dart';
import 'keezer_manager_page.dart';

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

      final jpgBytes = img.encodeJpg(resized, quality: 80);
      final base64Image = base64Encode(jpgBytes);

      setState(() {
        _newAvatarBase64 = base64Image;
      });

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

  void _openHowTo() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const HowToPage(),
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

  void _openKeezerManager() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => KeezerManagerPage(profileId: _profileId),
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
              icon: Icons.receipt_long,
              label: 'Generierte Rezepte',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GeneratedRecipesListPage()),
              ),
            ),
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
              icon: Icons.kitchen,
              label: 'Keezer',
              onPressed: _openKeezerManager,
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
              icon: Icons.help_outline,
              label: "How To's",
              onPressed: _openHowTo,
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
