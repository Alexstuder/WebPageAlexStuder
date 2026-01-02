import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ai_recipe.dart';
import '../services/openai_service.dart';
import 'package:url_launcher/url_launcher.dart';

class RecipeCompletionPage extends StatefulWidget {
  final AiRecipe recipe;

  const RecipeCompletionPage({super.key, required this.recipe});

  @override
  State<RecipeCompletionPage> createState() => _RecipeCompletionPageState();
}

class _RecipeCompletionPageState extends State<RecipeCompletionPage> {
  late final TextEditingController _promptController;
  final OpenAIService _openAIService = OpenAIService();
  bool _isGenerating = false;
  String? _generatedImageUrl;
  bool _useSourceImage = false;

  @override
  void initState() {
    super.initState();
    _promptController = TextEditingController(text: _buildInitialPrompt());
    _useSourceImage = widget.recipe.sourceImage != null;
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  String _buildInitialPrompt() {
    final style = widget.recipe.bierTyp;
    final name = widget.recipe.basisBier;
    
    String prompt = 'Erstelle eine kreative, atmosphärische Beschreibung meines Bieres für ein Bildgenerierungsprogramm. ';
    prompt += 'Es ist ein \'$name\' im Stil eines \'$style\'. ';
    prompt += 'WICHTIG: Das Bild soll eine stilvolle, gut lesbare Beschriftung oder ein Etikett mit dem Namen des Bieres enthalten (NUR der Name \'$style\' oder kurz \'$name\', ohne lange Zutatenliste oder Beschreibungen). ';
    prompt += 'Die Umgebung und der Hintergrund sollen passend zum Bierstil gewählt werden. ';
    prompt += 'Die Beschreibung soll bildhaft, einladend und professionell sein.';
    
    return prompt;
  }

  Future<void> _generateImage() async {
    if (_promptController.text.trim().isEmpty) return;

    setState(() {
      _isGenerating = true;
      _generatedImageUrl = null;
    });

    try {
      final result = await _openAIService.generateImage(
        _promptController.text,
        attachment: _useSourceImage ? widget.recipe.sourceImage : null,
      );
      if (mounted) {
        setState(() {
          _generatedImageUrl = result;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler bei der Generierung: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rezept abschließen'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Dein Rezept ist bereit!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            const Text(
              'Bild-Prompt anpassen:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _promptController,
              maxLines: 4,
              enabled: !_isGenerating,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'Vorgeschlagener Prompt...',
                fillColor: Colors.grey.withValues(alpha: 0.1),
                filled: true,
              ),
            ),
            if (widget.recipe.sourceImage != null) ...[
              const SizedBox(height: 8),
              CheckboxListTile(
                title: const Text(
                  'Soll das hochgeladene Foto als Vorlage an ChatGPT mitgeliefert werden?',
                  style: TextStyle(fontSize: 14),
                ),
                value: _useSourceImage,
                onChanged: _isGenerating 
                    ? null 
                    : (val) => setState(() => _useSourceImage = val ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ],
            const SizedBox(height: 16),
            

            const SizedBox(height: 16),
            
            if (_generatedImageUrl != null) ...[
              const Text(
                'Generiertes Bild:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 500),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
                  ),
                  child: Image.network(
                    '${_openAIService.proxyBaseUrl}/proxy-image?url=${Uri.encodeComponent(_generatedImageUrl!)}',
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return SizedBox(
                        height: 300,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(
                                'Lade Bild: ${loadingProgress.cumulativeBytesLoaded ~/ 1024} KB',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.red.withValues(alpha: 0.1),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 48),
                              const SizedBox(height: 8),
                              const Text('Bild konnte nicht geladen werden.'),
                              TextButton(
                                onPressed: _generateImage,
                                child: const Text('Erneut versuchen'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final url = Uri.parse(_generatedImageUrl!);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Bild öffnen / Download'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.withValues(alpha: 0.8),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _generatedImageUrl!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link in Zwischenablage kopiert!')),
                      );
                    },
                    icon: const Icon(Icons.link),
                    label: const Text('Link kopieren'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            _CompletionButton(
              label: _isGenerating ? 'Generiere...' : 'Bild generieren',
              icon: Icons.auto_awesome,
              onPressed: _isGenerating ? null : _generateImage,
              isLoading: _isGenerating,
            ),
            
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            
            _CompletionButton(
              label: 'Rezept abspeichern',
              icon: Icons.save,
              onPressed: _isGenerating ? null : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rezept wird gespeichert...')),
                );
              },
            ),
            const SizedBox(height: 16),
            _CompletionButton(
              label: 'In Brewfather.json transformieren',
              icon: Icons.code,
              onPressed: _isGenerating ? null : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('In Brewfather.json transformieren...')),
                );
              },
            ),
            const SizedBox(height: 16),
            _CompletionButton(
              label: 'In BeerXML transformieren',
              icon: Icons.description,
              onPressed: _isGenerating ? null : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('In BeerXML transformieren...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _CompletionButton({
    required this.label,
    required this.icon,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: isLoading 
          ? const SizedBox(
              width: 18, 
              height: 18, 
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ) 
          : Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 16),
      ),
    );
  }
}
