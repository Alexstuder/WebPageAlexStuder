import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenAIService {
  OpenAIService()
      : _endpoint = Uri.parse(
          dotenv.env['PROXY_URL'] ?? 'http://localhost:3000/api/brew',
        );

  final Uri _endpoint;

  Future<String> brewRecipe(String userPrompt) async {
    if (userPrompt.trim().isEmpty) {
      throw Exception('Bitte gib eine Beschreibung ein.');
    }

    final response = await http.post(
      _endpoint,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'prompt': userPrompt}),
    );

    if (response.statusCode != 200) {
      final message = response.body.isNotEmpty ? response.body : 'Unbekannter Fehler';
      throw Exception('Proxy-Anfrage fehlgeschlagen: $message');
    }

    final Map<String, dynamic> decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final result = decoded['result'];

    if (result is! String || result.trim().isEmpty) {
      throw Exception('Keine gültige Antwort vom Proxy erhalten.');
    }

    return result.trim();
  }
}
