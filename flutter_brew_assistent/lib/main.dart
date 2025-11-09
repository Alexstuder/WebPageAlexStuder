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
          builder: (_) => FineTuningPage(beerName: value),
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
              'welcome',
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

class FineTuningPage extends StatelessWidget {
  const FineTuningPage({super.key, required this.beerName});

  final String beerName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feintuning'),
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
              'Lass uns ein neues leckeres und einzigartiges $beerName Bier entwerfen',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 240,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(RecipePromptPage.routeName);
                },
                child: const Text('Weiter zum Rezept'),
              ),
            ),
          ],
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
