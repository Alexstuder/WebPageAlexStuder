import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenAIService {
  OpenAIService();

  static final Uri _endpoint = Uri.parse('https://api.openai.com/v1/chat/completions');

  Future<String> brewRecipe(String userPrompt) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OPENAI_API_KEY fehlt. Bitte in der .env-Datei hinterlegen.');
    }

    final response = await http.post(
      _endpoint,
      headers: <String, String>{
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-4o-mini',
        'messages': [
          {
            'role': 'system',
            'content':
                'Du bist ein erfahrener Braumeister. Erstelle strukturierte Bierrezepte mit Zutatenliste, Brauschritten und optionalen Varianten.'
          },
          {
            'role': 'user',
            'content': 'Erstelle ein Bier-Rezept basierend auf: $userPrompt'
          },
        ],
        'temperature': 0.7,
      }),
    );

    if (response.statusCode != 200) {
      final message = response.body.isNotEmpty ? response.body : 'Unbekannter Fehler';
      throw Exception('OpenAI-Anfrage fehlgeschlagen: $message');
    }

    final Map<String, dynamic> decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final List<dynamic> choices = decoded['choices'] as List<dynamic>;
    if (choices.isEmpty) {
      throw Exception('Antwort enthielt keine Vorschläge.');
    }
    final Map<String, dynamic> message = choices.first['message'] as Map<String, dynamic>;
    final content = message['content'];
    if (content is! String) {
      throw Exception('Unerwartetes Antwortformat erhalten.');
    }
    return content.trim();
  }
}
