import 'package:flutter/material.dart';
import '../models/user_profile.dart';
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
  UserProfile? _userProfile;

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

      _userProfile = profile;

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

    if (_fermentables.isEmpty) {
      return const Center(
        child: Text('Keine fermentierbaren Zutaten in Brewfather gefunden.'),
      );
    }

    return ListView.separated(
      itemCount: _fermentables.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = _fermentables[index];
        final name = item['name'] ?? 'Unbekannt';
        final supplier = item['supplier'] ?? '';
        final amount = item['amount'] ?? 0;
        final unit = item['amountUnit'] ?? 'kg';
        final color = item['color'] ?? 0;
        final type = item['type'] ?? '';

        return ListTile(
          leading: const Icon(Icons.grain, color: Colors.amber),
          title: Text(name),
          subtitle: Text(
            '$type${supplier.isNotEmpty ? ' • $supplier' : ''} • ${color.toString()} EBC',
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
