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
      title: 'BrewGenius',
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
      home: const BrewHomePage(),
    );
  }
}

class BrewHomePage extends StatefulWidget {
  const BrewHomePage({super.key});

  @override
  State<BrewHomePage> createState() => _BrewHomePageState();
}

class _BrewHomePageState extends State<BrewHomePage> {
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
        title: const Text('BrewGenius'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
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
