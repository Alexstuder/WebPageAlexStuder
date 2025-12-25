import 'package:flutter/material.dart';
import '../models/brew_kettle.dart';
import '../services/brew_kettle_service.dart';
import '../widgets/card_actions.dart'; // Ensure this path is correct

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
  bool _isLoading = true;
  List<BrewKettle> _kettles = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = widget.repository ?? BrewKettleService();
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
                if (kettle.postBoilLossLiters != null)
                  Text('Prozessverlust: ${kettle.postBoilLossLiters!.toStringAsFixed(1)} L'),
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
    final postBoilLossCtrl = TextEditingController(
      text: editing?.postBoilLossLiters?.toString() ?? '',
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
                  controller: postBoilLossCtrl,
                  decoration: InputDecoration(
                    labelText: 'Post-Boil Prozessverlust (L)',
                    suffixIcon: Tooltip(
                      message: 'Volumenverlust zwischen Kochende und Gärtank durch bewusst zurückgelassenen Trub im Kessel sowie Restwürze in Gegenstromkühler, Schläuchen und Pumpe. Dieser Verlust ist qualitätsbedingt und wird nicht in den Gärtank übernommen.',
                      triggerMode: TooltipTriggerMode.tap,
                      child: const Icon(Icons.info_outline, size: 20),
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
      postBoilLossLiters: _parseDouble(postBoilLossCtrl.text),
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
