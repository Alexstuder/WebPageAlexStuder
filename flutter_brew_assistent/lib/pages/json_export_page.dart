
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart'; // Falls vorhanden, sonst entfernen
import '../models/ai_recipe.dart';
import '../services/brewfather_transformer_service.dart';

class JsonExportPage extends StatefulWidget {
  final AiRecipe recipe;

  const JsonExportPage({super.key, required this.recipe});

  @override
  State<JsonExportPage> createState() => _JsonExportPageState();
}

class _JsonExportPageState extends State<JsonExportPage> {
  late String _jsonString;
  late String _fileName;

  @override
  void initState() {
    super.initState();
    final map = BrewfatherTransformerService.transform(widget.recipe);
    _jsonString = const JsonEncoder.withIndent('  ').convert(map);
    
    // Generate filename: Brewfather_RECIPE_Name_Date.json
    final date = DateTime.now();
    final dateStr = "${date.year}${date.month.toString().padLeft(2,'0')}${date.day.toString().padLeft(2,'0')}";
    final cleanName = widget.recipe.basisBier.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    _fileName = "Brewfather_RECIPE_${cleanName}_$dateStr.json";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Brewfather Export'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'In Zwischenablage kopieren',
            onPressed: _copyToClipboard,
          ),
          // Download Button (Primär für Web via Data URI oder Fallback)
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download JSON',
            onPressed: _download,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.blueGrey.withOpacity(0.1),
              child: SelectableText(
                "Dateiname: $_fileName\n\nKlicke auf 'Kopieren' um den Inhalt in Brewfather > Import Recipe > Text/Paste einzufügen.",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(8),
                  child: SelectableText(
                    _jsonString,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _jsonString));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('JSON kopiert! Öffne Brewfather und füge es ein.')),
    );
  }

  Future<void> _download() async {
    try {
      // Data URI erstellen
      // encodeComponent ist wichtig für Sonderzeichen
      final dataUri = Uri.dataFromString(
        _jsonString,
        mimeType: 'application/json',
        encoding: utf8,
      );
      
      if (await canLaunchUrl(dataUri)) {
        await launchUrl(dataUri);
      } else {
        // Fallback: Clipboard info
        if(mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Download nicht unterstützt. Bitte "Kopieren" nutzen.')),
           );
        }
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler: $e')));
      }
    }
  }
}
