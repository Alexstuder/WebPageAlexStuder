import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenAIService {
  OpenAIService()
      : _brewEndpoint = Uri.parse(
          dotenv.env['PROXY_URL'] ?? 'http://localhost:3000/api/brew',
        ),
        _shopEndpoint = _deriveShopEndpoint(
          Uri.parse(
              dotenv.env['PROXY_URL'] ?? 'http://localhost:3000/api/brew'),
        );

  final Uri _brewEndpoint;
  final Uri _shopEndpoint;

  Future<String> brewRecipe(
    String userPrompt, {
    RecipeImageAttachment? attachment,
  }) async {
    if (userPrompt.trim().isEmpty) {
      throw Exception('Bitte gib eine Beschreibung ein.');
    }

    final payload = <String, dynamic>{
      'prompt': userPrompt,
      if (attachment != null) 'image': attachment.toJson(),
    };

    final response = await http.post(
      _brewEndpoint,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      final message =
          response.body.isNotEmpty ? response.body : 'Unbekannter Fehler';
      throw Exception('Proxy-Anfrage fehlgeschlagen: $message');
    }

    final Map<String, dynamic> decoded =
        jsonDecode(response.body) as Map<String, dynamic>;
    final result = decoded['result'];

    if (result is! String || result.trim().isEmpty) {
      throw Exception('Keine gültige Antwort vom Proxy erhalten.');
    }

    return result.trim();
  }

  Future<ShopSearchResponse> searchShops(String query) async {
    final response = await http.post(
      _shopEndpoint,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'query': query}),
    );

    if (response.statusCode != 200) {
      final message =
          response.body.isNotEmpty ? response.body : 'Unbekannter Fehler';
      throw Exception('Shopsuche fehlgeschlagen: $message');
    }

    final Map<String, dynamic> decoded =
        jsonDecode(response.body) as Map<String, dynamic>;
    return ShopSearchResponse.fromJson(decoded);
  }

  static Uri _deriveShopEndpoint(Uri brew) {
    final segments = List<String>.from(brew.pathSegments);
    if (segments.isNotEmpty) {
      segments.removeLast();
    }
    segments.add('shop-search');
    return brew.replace(pathSegments: segments);
  }
}

class RecipeImageAttachment {
  const RecipeImageAttachment({
    required this.bytes,
    required this.mimeType,
    this.fileName,
  });

  final Uint8List bytes;
  final String mimeType;
  final String? fileName;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'data': base64Encode(bytes),
        'mime_type': mimeType,
        if (fileName != null) 'file_name': fileName,
      };
}

class ShopSearchResponse {
  ShopSearchResponse({required this.query, required this.shops});

  final String query;
  final List<ShopSearchShop> shops;

  factory ShopSearchResponse.fromJson(Map<String, dynamic> json) {
    final shopsJson = json['shops'] as List<dynamic>? ?? const [];
    return ShopSearchResponse(
      query: json['query'] as String? ?? '',
      shops: shopsJson
          .map(
              (entry) => ShopSearchShop.fromJson(entry as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ShopSearchShop {
  ShopSearchShop({
    required this.shop,
    required this.url,
    required this.results,
    this.error,
  });

  final String shop;
  final String? url;
  final List<ShopSearchItem> results;
  final String? error;

  factory ShopSearchShop.fromJson(Map<String, dynamic> json) {
    final resultsJson = json['results'] as List<dynamic>? ?? const [];
    return ShopSearchShop(
      shop: json['shop'] as String? ?? '',
      url: json['url'] as String?,
      error: json['error'] as String?,
      results: resultsJson
          .map(
              (entry) => ShopSearchItem.fromJson(entry as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ShopSearchItem {
  ShopSearchItem({
    required this.title,
    this.link,
    this.price,
    this.availability,
  });

  final String title;
  final String? link;
  final String? price;
  final String? availability;

  factory ShopSearchItem.fromJson(Map<String, dynamic> json) {
    return ShopSearchItem(
      title: json['title'] as String? ?? '',
      link: json['link'] as String?,
      price: json['price'] as String?,
      availability: json['availability'] as String?,
    );
  }
}
