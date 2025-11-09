import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';

import 'services/openai_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
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

  void applyPreset(Map<String, double> preset) {
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: groupValue == label ? const Color(0xFF2563EB) : Colors.white24,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Radio<String>(
              value: label,
              groupValue: groupValue,
              onChanged: (_) => onTap(),
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
                    ),
                    _FineSlider(
                      value: profile.hopIntensity,
                      onChanged: (v) =>
                          setState(() => profile.hopIntensity = v),
                    ),
                    const SizedBox(height: 12),
                    _SliderBlock(
                      label: 'Kräuterig',
                      minLabel: 'wenig',
                      maxLabel: 'stark',
                      value: profile.hopHerbal,
                    ),
                    _FineSlider(
                      value: profile.hopHerbal,
                      onChanged: (v) =>
                          setState(() => profile.hopHerbal = v),
                    ),
                    const SizedBox(height: 12),
                    _SliderBlock(
                      label: 'Blumig',
                      minLabel: 'wenig',
                      maxLabel: 'stark',
                      value: profile.hopFloral,
                    ),
                    _FineSlider(
                      value: profile.hopFloral,
                      onChanged: (v) =>
                          setState(() => profile.hopFloral = v),
                    ),
                    const SizedBox(height: 12),
                    _SliderBlock(
                      label: 'Fruchtig',
                      minLabel: 'wenig',
                      maxLabel: 'stark',
                      value: profile.hopFruity,
                    ),
                    _FineSlider(
                      value: profile.hopFruity,
                      onChanged: (v) =>
                          setState(() => profile.hopFruity = v),
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
                    ),
                    _FineSlider(
                      value: profile.hopNose,
                      onChanged: (v) =>
                          setState(() => profile.hopNose = v),
                    ),
                    const SizedBox(height: 12),
                    _SliderBlock(
                      label: 'Gaumen',
                      minLabel: 'wenig',
                      maxLabel: 'stark',
                      value: profile.hopPalate,
                    ),
                    _FineSlider(
                      value: profile.hopPalate,
                      onChanged: (v) =>
                          setState(() => profile.hopPalate = v),
                    ),
                    const SizedBox(height: 12),
                    _SliderBlock(
                      label: 'Abgang',
                      minLabel: 'wenig',
                      maxLabel: 'stark',
                      value: profile.hopFinish,
                    ),
                    _FineSlider(
                      value: profile.hopFinish,
                      onChanged: (v) =>
                          setState(() => profile.hopFinish = v),
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
            ),
            _FineSlider(
              value: profile.mouthfeel,
              onChanged: (v) => setState(() => profile.mouthfeel = v),
            ),
            const SizedBox(height: 12),
            _SliderBlock(
              label: 'Malzaroma',
              minLabel: 'leicht',
              maxLabel: 'kräftig',
              value: profile.antrunkMalt,
            ),
            _FineSlider(
              value: profile.antrunkMalt,
              onChanged: (v) => setState(() => profile.antrunkMalt = v),
            ),
            const SizedBox(height: 12),
            _SliderBlock(
              label: 'Röstmalzaroma',
              minLabel: 'leicht',
              maxLabel: 'kräftig',
              value: profile.antrunkRoast,
            ),
            _FineSlider(
              value: profile.antrunkRoast,
              onChanged: (v) => setState(() => profile.antrunkRoast = v),
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
            ),
            _FineSlider(
              value: widget.profile.smooth,
              onChanged: (v) => setState(() => widget.profile.smooth = v),
            ),
            const SizedBox(height: 12),
            _SliderBlock(
              label: 'vollmundig',
              minLabel: 'leicht',
              maxLabel: 'kräftig',
              value: widget.profile.fullBody,
            ),
            _FineSlider(
              value: widget.profile.fullBody,
              onChanged: (v) => setState(() => widget.profile.fullBody = v),
            ),
            const SizedBox(height: 12),
            _SliderBlock(
              label: 'Malzaroma',
              minLabel: 'leicht',
              maxLabel: 'kräftig',
              value: widget.profile.mainMalt,
            ),
            _FineSlider(
              value: widget.profile.mainMalt,
              onChanged: (v) => setState(() => widget.profile.mainMalt = v),
            ),
            const SizedBox(height: 12),
            _SliderBlock(
              label: 'Röstaroma',
              minLabel: 'leicht',
              maxLabel: 'kräftig',
              value: widget.profile.mainRoast,
            ),
            _FineSlider(
              value: widget.profile.mainRoast,
              onChanged: (v) => setState(() => widget.profile.mainRoast = v),
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
            ),
            _FineSlider(
              value: widget.profile.fade,
              onChanged: (v) => setState(() => widget.profile.fade = v),
            ),
            const SizedBox(height: 12),
            _SliderBlock(
              label: 'erfrischend',
              minLabel: 'leicht',
              maxLabel: 'kräftig',
              value: widget.profile.fresh,
            ),
            _FineSlider(
              value: widget.profile.fresh,
              onChanged: (v) => setState(() => widget.profile.fresh = v),
            ),
            const SizedBox(height: 12),
            _SliderBlock(
              label: 'trocken',
              minLabel: 'leicht',
              maxLabel: 'kräftig',
              value: widget.profile.dry,
            ),
            _FineSlider(
              value: widget.profile.dry,
              onChanged: (v) => setState(() => widget.profile.dry = v),
            ),
            const SizedBox(height: 12),
            _SliderBlock(
              label: 'langanhaltend',
              minLabel: 'leicht',
              maxLabel: 'kräftig',
              value: widget.profile.lasting,
            ),
            _FineSlider(
              value: widget.profile.lasting,
              onChanged: (v) => setState(() => widget.profile.lasting = v),
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
                  ..._buildSummarySections(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context)
                      .pushNamed(RecipePromptPage.routeName);
                },
                child: const Text('Freitext-Rezept erstellen'),
              ),
            )
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSummarySections() {
    final sections = [
      _SummarySection('Hopfen', [
        _SummaryEntry('Aromaintensität', profile.hopIntensity),
        _SummaryEntry('Kräuterig', profile.hopHerbal),
        _SummaryEntry('Blumig', profile.hopFloral),
        _SummaryEntry('Fruchtig', profile.hopFruity),
      ]),
      _SummarySection('Verteilung', [
        _SummaryEntry('Nase', profile.hopNose),
        _SummaryEntry('Gaumen', profile.hopPalate),
        _SummaryEntry('Abgang', profile.hopFinish),
      ]),
      _SummarySection('Antrunk', [
        _SummaryEntry('Mundgefühl', profile.mouthfeel),
        _SummaryEntry('Malzaroma', profile.antrunkMalt),
        _SummaryEntry('Röstmalzaroma', profile.antrunkRoast),
      ], dividerBefore: true),
      _SummarySection('Haupttrunk', [
        _SummaryEntry('süffig', profile.smooth),
        _SummaryEntry('vollmundig', profile.fullBody),
        _SummaryEntry('Malzaroma', profile.mainMalt),
        _SummaryEntry('Röstaroma', profile.mainRoast),
      ]),
      _SummarySection('Nachtrunk', [
        _SummaryEntry('abklingen', profile.fade),
        _SummaryEntry('erfrischend', profile.fresh),
        _SummaryEntry('trocken', profile.dry),
        _SummaryEntry('langanhaltend', profile.lasting),
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
                  padding: const EdgeInsets.only(left: 20, top: 2, bottom: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.label,
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        '${(entry.value * 100).round()}%',
                        style: const TextStyle(fontSize: 14),
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
}

class _SummarySection {
  const _SummarySection(this.title, this.entries, {this.dividerBefore = false});

  final String title;
  final List<_SummaryEntry> entries;
  final bool dividerBefore;
}

class _SummaryEntry {
  const _SummaryEntry(this.label, this.value);

  final String label;
  final double value;
}
class _SliderBlock extends StatelessWidget {
  const _SliderBlock({
    required this.label,
    required this.minLabel,
    required this.maxLabel,
    required this.value,
  });

  final String label;
  final String minLabel;
  final String maxLabel;
  final double value;

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
  const _FineSlider({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = SliderTheme.of(context).copyWith(
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 24),
      child: Align(
        alignment: Alignment.centerLeft,
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
        style: TextStyle(color: Colors.white.withOpacity(0.72)),
      ),
    );
  }
}
