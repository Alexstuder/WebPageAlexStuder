import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class RaptService {
  static const String directBaseUrl = 'https://api.rapt.io/api';
  // Use localhost:3000 for Web (Proxy) to avoid CORS
  // You must run 'node proxy/server.js' locally!
  static const String proxyBaseUrl = 'http://localhost:3000/api';
  
  final String userId;
  final String apiKey;

  RaptService({
    required this.userId,
    required this.apiKey,
  });
  
  String get baseUrl => kIsWeb ? proxyBaseUrl : directBaseUrl;

  // Helper to fetch controllers
  Future<List<dynamic>> getControllers() async {
    // If using Proxy, we hit /cache/controllers
    // If Direct, we hit /TemperatureControllers/GetTemperatureControllers
    
    final uri = kIsWeb 
        ? Uri.parse('$baseUrl/cache/controllers')
        : Uri.parse('$baseUrl/TemperatureControllers/GetTemperatureControllers');
    
    // Authorization
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    
    // Only send Auth for direct mode (Proxy handles its own auth from .env)
    if (!kIsWeb) {
      headers['Authorization'] = 'Bearer $apiKey';
    }

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Adapt parsing based on source
      if (kIsWeb) {
        // Proxy returns { controllers: [...], ... }
        if (data is Map && data.containsKey('controllers')) {
           return data['controllers'] as List;
        }
        return [];
      } else {
        // Direct API returns List
        return data as List;
      }
    } else {
       debugPrint('RAPT API Error ${response.statusCode}: ${response.body}');
       throw Exception('Failed to load controllers: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> getTelemetry(String controllerId, DateTime startDate) async {
    // Proxy: /cache/telemetry (returns object with 'rows') or /rapt/telemetry
    // Direct: /TemperatureControllers/GetTelemetry (returns List)
    
    Uri uri;
    if (kIsWeb) {
       // Using the cache endpoint is faster and structured
       uri = Uri.parse('$baseUrl/cache/telemetry'); 
       // Note: The proxy cache might not filter by specific controllerId in the GET request if it's singleton
       // But let's try the dynamic telemetry key if available?
       // The proxy has /api/rapt/telemetry which takes ?start=... 
       // but /api/cache/telemetry returns the latest cached dump for the configured user.
       // Let's rely on /api/rapt/telemetry so we can pass query params if needed, 
       // BUT note the proxy ignores dynamic params for the *cache* usually? 
       // Proxy code: handleRaptTelemetryRequest checks ?start=
       
       uri = Uri.parse('$baseUrl/rapt/telemetry').replace(queryParameters: {
         'start': startDate.toIso8601String(),
       });
    } else {
       uri = Uri.parse('$baseUrl/TemperatureControllers/GetTelemetry').replace(queryParameters: {
          'temperatureControllerId': controllerId,
          'startDate': startDate.toIso8601String(),
       });
    }

    final headers = {'Content-Type': 'application/json'};
    if (!kIsWeb) {
      headers['Authorization'] = 'Bearer $apiKey';
    }

    final response = await http.get(uri, headers: headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      if (kIsWeb) {
         // Proxy returns { rows: [...], ... }
         if (data is Map && data.containsKey('rows')) {
            return data['rows'] as List;
         }
         return [];
      } else {
         return data as List;
      }
    } else {
      debugPrint('RAPT Telemetry Error ${response.statusCode}: ${response.body}');
      throw Exception('Failed to load telemetry: ${response.statusCode}');
    }
  }
}
