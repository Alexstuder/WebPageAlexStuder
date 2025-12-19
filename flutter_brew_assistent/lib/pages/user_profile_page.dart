import 'package:flutter/material.dart';
import '../services/user_profile_service.dart';
import '../services/water_profile_service.dart';

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
      body: const Center(
        child: Text('Diese Seite wird gerade refaktoriert.\nBitte nutze die alte Version in main.dart wenn möglich.'),
      ),
    );
  }
}
