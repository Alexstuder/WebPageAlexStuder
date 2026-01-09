import 'package:flutter/material.dart';
import '../models/water_profile.dart';
import '../services/water_profile_service.dart';
import '../widgets/card_actions.dart';

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
