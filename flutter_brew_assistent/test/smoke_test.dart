import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brew_genius/main.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class TestAssetBundle extends CachingAssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    return "{}"; // JSON map for manifests
  }
  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      final emptyMap = <Object, Object>{}; // Empty manifest
      final data = const StandardMessageCodec().encodeMessage(emptyMap);
      return data!;
    }
    
    if (key == 'AssetManifest.json') {
       return ByteData.view(Uint8List.fromList(utf8.encode('{}')).buffer);
    }
    
    // Return transparent 1x1 pixel for images
    final transparentPixel = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg==',
    );
    return ByteData.view(transparentPixel.buffer);
  }
}

void main() {
  testWidgets('Smoke Test: App starts and shows main menu', (WidgetTester tester) async {
    // We do NOT use _registerTestAsset anymore.

    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: TestAssetBundle(),
        child: const MaterialApp(
          home: BrewEntryPage(),
        ),
      ),
    );

    // Verify that the main menu buttons are present.
    expect(find.text('Users profil'), findsOneWidget);
    expect(find.text('Currently Brewing'), findsOneWidget);
    expect(find.text('Studio'), findsOneWidget);
    expect(find.text('Start, entdecken wir ein neues Bier'), findsOneWidget);
  });
}
