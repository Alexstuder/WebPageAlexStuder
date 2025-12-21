import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/yeast_bank_entry.dart';
import '../models/user_profile.dart'; // For UserProfile model
import '../services/yeast_bank_service.dart';
import '../services/user_profile_service.dart';
import '../services/brewfather_service.dart';
import '../widgets/card_actions.dart';
import 'integrations_page.dart'; // Assumed to be in the same directory

class YeastBankManagerPage extends StatefulWidget {
  const YeastBankManagerPage({super.key, required this.profileId});

  final String profileId;

  @override
  State<YeastBankManagerPage> createState() => _YeastBankManagerPageState();
}

class _YeastBankManagerPageState extends State<YeastBankManagerPage> {
  final YeastBankService _service = YeastBankService();
  final UserProfileService _userService = UserProfileService();
  bool _isLoading = true;
  List<YeastBankEntry> _entries = [];
  String? _error;
  bool _syncEnabled = false;
  UserProfile? _userProfile;
  final Map<String, String> _debugJsonMap = {};

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
    
    String initialProductId = editing?.productId ?? '';
    String initialForm = editing?.form ?? '';
    String initialInventory = editing?.inventory != null ? editing!.inventory.toString() : '';
    String initialUnit = editing?.unit ?? '';
    
    // If empty and we have debug map (legacy case), try to fill
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
      style: styleCtrl.text.trim().isEmpty ? null : styleCtrl.text.trim(),
      url: urlCtrl.text.trim().isEmpty ? null : urlCtrl.text.trim(),
      attenuationMin: _parseDouble(attenuationMinCtrl.text),
      attenuationMax: _parseDouble(attenuationMaxCtrl.text),
      temperatureMin: _parseDouble(tempMinCtrl.text),
      temperatureMax: _parseDouble(tempMaxCtrl.text),
      notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
      // New Fields
      productId: productIdCtrl.text.trim().isEmpty ? null : productIdCtrl.text.trim(),
      form: formCtrl.text.trim().isEmpty ? null : formCtrl.text.trim(),
      inventory: _parseDouble(inventoryCtrl.text),
      unit: unitCtrl.text.trim().isEmpty ? null : unitCtrl.text.trim(),
    );

    try {
      final saved = await _service.saveEntry(entry);
      
      // Update inventory in Brewfather if synced
      if (_syncEnabled && isSynced && saved.inventory != null && _userProfile?.brewfatherApiKey != null && _userProfile?.brewfatherUserId != null) {
          // Sync logic placeholder if implemented
      }

      if (!mounted) return;
      setState(() {
        if (editing != null) {
          final index = _entries.indexWhere((e) => e.id == saved.id);
          if (index >= 0) {
            _entries[index] = saved;
          }
        } else {
          _entries.add(saved);
        }
      });
      if (mounted) {
        if (!isSynced && _syncEnabled) {
          // New local entry popup
           showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Lokaler Eintrag'),
              content: const Text('Dieser Eintrag ist nur lokal gespeichert.\nBrewfather API unterstützt das Erstellen neuer Hefe-Einträge nicht.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))
              ],
            ),
          );
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                editing == null ? 'Hefe erstellt' : 'Hefe aktualisiert',
              ),
            ),
          );
        }
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
        SnackBar(content: Text('Hefe "${entry.brand} · ${entry.strain}" gelöscht')),
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
