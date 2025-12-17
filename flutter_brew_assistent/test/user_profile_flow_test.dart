import 'dart:convert';
import 'package:brew_genius/main.dart';
import 'package:brew_genius/models/user_profile.dart';
import 'package:brew_genius/models/water_profile.dart';
import 'package:brew_genius/services/user_profile_service.dart';
import 'package:brew_genius/services/water_profile_service.dart';
import 'package:brew_genius/models/fermentable.dart';
import 'package:brew_genius/models/hop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    _registerTestAsset();
  });

  testWidgets('User can fill profile and water data via GUI flow', (tester) async {
    final fakeUserRepo = FakeUserProfileRepository();
    final fakeWaterRepo = FakeWaterProfileRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: const BrewEntryPage(),
        routes: {
          UserProfilePage.routeName: (_) => UserProfilePage(
                profileRepository: fakeUserRepo,
                waterRepository: fakeWaterRepo,
              ),
        },
      ),
    );

    await tester.tap(find.text('Users profil'));
    await tester.pumpAndSettle();

    await tester.enterText(find.bySemanticsLabel('Name').first, 'Brew Master');
    await tester.enterText(
      find.bySemanticsLabel('Avatar URL'),
      'https://example.com/avatar.png',
    );

    await tester.tap(find.text('Wasserprofile'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Profil anlegen'));
    await tester.pumpAndSettle();

    await tester.enterText(find.bySemanticsLabel('Profilname'), 'Hauswasser');
    await tester.enterText(find.bySemanticsLabel('pH'), '5.4');

    final wertFields = find.bySemanticsLabel('Wert');
    await tester.enterText(wertFields.at(0), '55'); // Ca
    await tester.enterText(wertFields.at(1), '12'); // Mg
    await tester.enterText(wertFields.at(2), '18'); // Na

    await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(fakeUserRepo.saveCallCount, greaterThanOrEqualTo(1));
    expect(fakeWaterRepo.lastSaved?.name, 'Hauswasser');
    expect(fakeWaterRepo.lastSaved?.ph, 5.4);
    expect(fakeWaterRepo.lastSaved?.calciumPpm, 55);
    expect(fakeWaterRepo.lastSaved?.magnesiumPpm, 12);
    expect(fakeWaterRepo.lastSaved?.sodiumPpm, 18);

    await tester.tap(find.widgetWithText(FilledButton, 'Zurück'));
    await tester.pumpAndSettle();

    expect(find.text('Brew Master'), findsWidgets);
  });
}

void _registerTestAsset() {
  const assetKey = 'assets/icon.png';
  final transparentPixel = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg==',
  );
  final iconBytes = ByteData.view(transparentPixel.buffer);
  final manifestJson = jsonEncode({assetKey: [assetKey]});
  final manifestBin = const StandardMessageCodec().encodeMessage({
    assetKey: <String>[assetKey],
  });

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('flutter/assets', (message) async {
    final String key = utf8.decode(message!.buffer.asUint8List());
    if (key == assetKey) {
      return iconBytes;
    }
    if (key == 'AssetManifest.json') {
      final data = Uint8List.fromList(utf8.encode(manifestJson));
      return ByteData.view(data.buffer);
    }
    if (key == 'AssetManifest.bin') {
      if (manifestBin == null) return null;
      return ByteData.view(
        manifestBin.buffer,
        manifestBin.offsetInBytes,
        manifestBin.lengthInBytes,
      );
    }
    return null;
  });
}

class FakeUserProfileRepository implements UserProfileRepository {
  UserProfile? stored;
  int saveCallCount = 0;

  @override
  Future<UserProfile?> fetchProfile(String id) async {
    return stored;
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    saveCallCount += 1;
    stored = profile;
  }



  @override
  Future<UserProfile?> fetchDefaultProfile({bool refresh = false}) async {
    return stored;
  }

  @override
  Future<List<Fermentable>> getFermentables(String userProfileId) async {
    return [];
  }

  @override
  Future<void> saveFermentables(List<Fermentable> fermentables) async {
    // no-op for now
  }

  @override
  Future<void> saveFermentable(Fermentable fermentable) async {
    // no-op for now
  }
  
  @override
  Future<List<Hop>> getHops(String userProfileId) async {
    return [];
  }

  @override
  Future<void> saveHops(List<Hop> hops) async {
    // no-op
  }

  @override
  Future<void> saveHop(Hop hop) async {
    // no-op
  }
}

class FakeWaterProfileRepository implements WaterProfileRepository {
  final List<WaterProfile> _profiles = [];
  WaterProfile? lastSaved;

  @override
  Future<void> deleteProfile(String id) async {
    _profiles.removeWhere((profile) => profile.id == id);
  }

  @override
  Future<List<WaterProfile>> fetchProfiles(String userProfileId) async {
    return _profiles
        .where((profile) => profile.userProfileId == userProfileId)
        .toList();
  }

  @override
  Future<WaterProfile> saveProfile(WaterProfile profile) async {
    final assignedId = profile.id ?? 'water_${_profiles.length + 1}';
    final saved = profile.copyWith(id: assignedId);
    _profiles.removeWhere((existing) => existing.id == assignedId);
    _profiles.add(saved);
    lastSaved = saved;
    return saved;
  }
}
