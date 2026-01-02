import 'package:flutter/material.dart';
import '../services/user_profile_service.dart';
import '../services/water_profile_service.dart';
import 'generated_recipes_list_page.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({
    super.key,
    this.profileRepository,
    this.waterRepository,
  });

  static const String routeName = '/user-profile';
  final UserProfileRepository? profileRepository;
  final WaterProfileRepository? waterRepository;

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Profil (Stub)')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.receipt_long),
            label: const Text('Generierte Rezepte'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 18),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GeneratedRecipesListPage()),
              );
            },
          ),
          const SizedBox(height: 32),
          const Center(
            child: Text(
              'User Profil (Stub)\nDiese Seite wird gerade refaktoriert.\nBitte nutze die alte Version in main.dart wenn möglich.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
