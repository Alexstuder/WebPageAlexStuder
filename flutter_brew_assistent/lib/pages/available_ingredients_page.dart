import 'package:flutter/material.dart';
import '../services/brewfather_service.dart';
import '../services/user_profile_service.dart';

class AvailableIngredientsPage extends StatefulWidget {
  const AvailableIngredientsPage({super.key, required this.profileId});

  final String profileId;

  @override
  State<AvailableIngredientsPage> createState() => _AvailableIngredientsPageState();
}

class _AvailableIngredientsPageState extends State<AvailableIngredientsPage> {
  final UserProfileService _userService = UserProfileService();
  bool _isLoading = true;
  String? _error;
  List<dynamic> _fermentables = [];

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
      final profile = await _userService.fetchProfile(widget.profileId);
      if (profile == null) throw Exception('Profil nicht gefunden');

      if ((profile.brewfatherUserId ?? '').isEmpty ||
          (profile.brewfatherApiKey ?? '').isEmpty) {
        throw Exception(
            'Bitte hinterlegen Sie erst Ihre Brewfather User ID und API Key in den Einstellungen.');
      }

      final bfService = BrewfatherService(
        userId: profile.brewfatherUserId!,
        apiKey: profile.brewfatherApiKey!,
      );

      // Wir holen nur die Fermentables
      final fermentables = await bfService.getFermentables();

      if (!mounted) return;

      setState(() {
        _fermentables = fermentables;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verfügbare Zutaten (Brewfather)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Fehler beim Laden: $_error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      );
    }

    final validItems = _fermentables.where((i) => (i['name'] ?? '').isNotEmpty).toList();

    if (validItems.isEmpty) {
      return const Center(
        child: Text('Keine fermentierbaren Zutaten in Brewfather gefunden.'),
      );
    }

    return ListView.separated(
      itemCount: validItems.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = validItems[index];
        final name = item['name'] ?? 'Unbekannt';
        final supplier = item['supplier'] ?? '';
        final amount = item['inventory'] ?? item['amount'] ?? 0;
        final unit = item['amountUnit'] ?? 'kg';
        final color = item['color'] ?? 0;
        final type = item['type'] ?? '';

        // Priority: potential (explicit SG) -> yield (calculated) -> attenuation (fallback)
        double sg = 1.0;
        if (item['potential'] != null) {
           sg = (item['potential'] as num).toDouble();
        } else if (item['yield'] != null) {
           // Yield is typically percentage e.g. 80
           // ~0.46 points per percent yield is a standard approximation for sucrose equivalent
           sg = 1 + ((item['yield'] as num) * 0.46) / 1000;
        } else if (item['attenuation'] != null) {
             sg = 1 + ((item['attenuation'] as num) * 0.46) / 1000;
        }

        return ListTile(
          leading: const Icon(Icons.grain, color: Colors.amber),
          title: Text(name),
          subtitle: Text(
            '$type${supplier.isNotEmpty ? ' • $supplier' : ''} • ${color.toString()} EBC • ${sg.toStringAsFixed(3)} SG',
            style: const TextStyle(color: Colors.white70),
          ),
          trailing: Text(
            '${(amount as num).toStringAsFixed(3)} $unit',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        );
      },
    );
  }
}
