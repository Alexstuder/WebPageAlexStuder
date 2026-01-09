import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'pages/rapt_dashboard_page.dart';
import 'pages/user_profile_page.dart';
import 'pages/recipe_prompt_page.dart';
import 'pages/brew_entry_page.dart';
import 'pages/discovery_welcome_page.dart';

import 'services/user_profile_service.dart';
import 'services/water_profile_service.dart';
import 'services/brew_kettle_service.dart';
import 'services/fermenter_service.dart';
import 'services/fermenter_controller_service.dart';
import 'services/malt_depot_service.dart';
import 'services/packaging_profile_service.dart';
import 'services/fining_agents_service.dart';
import 'services/yeast_bank_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await initializeDateFormatting('de_DE', null);

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    postgrestOptions: const PostgrestClientOptions(schema: 'aibrewgenius'),
  );
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
      builder: (context, child) => child ?? const SizedBox.shrink(),
    );
  }
}
