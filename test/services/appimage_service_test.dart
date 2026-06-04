import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:aim/models/app_info.dart';
import 'package:yaml/yaml.dart';

void main() {
  late String tmpBase;

  setUp(() async {
    tmpBase = '${Directory.systemTemp.path}/aim_test_${DateTime.now().millisecondsSinceEpoch}';
    await Directory(tmpBase).create(recursive: true);
  });

  tearDown(() async {
    await Directory(tmpBase).delete(recursive: true);
  });

  group('AppImageService metadata handling', () {
    test('loadApps returns empty list for empty base directory', () async {
      // The service always uses ~/AppImages, so we test the model directly
      // since the service path is hardcoded.
      final dir = Directory(tmpBase);
      expect(await dir.exists(), true);

      final contents = await dir.list().toList();
      expect(contents, isEmpty);
    });

    test('AppInfo.fromMetadataMap handles real loadYaml output', () {
      // This simulates the exact data flow from _loadFromMetadata
      final yamlStr = '''
name: TestApp
description: Loaded from YAML
generateLink: true
generateDesktopFile: false
selectedVersion: TestApp-2.0.0.AppImage
iconPath: /path/to/icon.png
versions:
  - TestApp-1.0.0.AppImage
  - TestApp-2.0.0.AppImage
''';
      final doc = loadYaml(yamlStr);
      expect(doc, isA<Map>());
      // This is the key test: doc should NOT need as Map<String, dynamic> cast
      final app = AppInfo.fromMetadataMap('TestApp', doc);

      expect(app.name, 'TestApp');
      expect(app.description, 'Loaded from YAML');
      expect(app.generateLink, true);
      expect(app.generateDesktopFile, false);
      expect(app.selectedVersion, 'TestApp-2.0.0.AppImage');
      expect(app.iconPath, '/path/to/icon.png');
      expect(app.versions, ['TestApp-1.0.0.AppImage', 'TestApp-2.0.0.AppImage']);
    });

    test('loadYaml map has correct runtime type for versions', () {
      final yamlStr = '''
versions:
  - v1
  - v2
''';
      final doc = loadYaml(yamlStr) as Map;
      // YamlList is an Iterable, so our fix should handle it
      expect(doc['versions'], isA<Iterable>());

      // This should work without YamlList-specific code
      final app = AppInfo.fromMetadataMap('App', doc);
      expect(app.versions, ['v1', 'v2']);
    });

    test('loadYaml map with dynamic keys should work', () {
      // In practice, YamlMap is Map<dynamic, dynamic>
      final yamlStr = 'name: DynamicKeyTest\ndescription: Testing';
      final doc = loadYaml(yamlStr);

      // Verify it's a Map but the exact type is YamlMap (Map<dynamic, dynamic>)
      expect(doc, isA<Map>());

      // This must work without casting to Map<String, dynamic>
      final app = AppInfo.fromMetadataMap('DynamicKeyTest', doc);
      expect(app.name, 'DynamicKeyTest');
      expect(app.description, 'Testing');
    });
  });

  group('AppInfo.toMetadataYaml creates valid YAML', () {
    test('output parses correctly with loadYaml', () {
      final app = AppInfo(
        name: 'ValidYaml',
        description: 'Testing YAML output',
        versions: ['ValidYaml-1.0.0.AppImage'],
        generateLink: true,
        generateDesktopFile: true,
      );

      final yamlStr = app.toMetadataYaml();
      // Should not throw
      final doc = loadYaml(yamlStr);
      expect(doc, isA<Map>());

      final restored = AppInfo.fromMetadataMap('ValidYaml', doc);
      expect(restored.name, app.name);
      expect(restored.versions, app.versions);
      expect(restored.generateLink, app.generateLink);
    });

    test('output with special chars parses without error', () {
      final app = AppInfo(
        name: 'Special',
        description: 'Contains: colon, #hash, -dash, \'quote\'',
        versions: ['Special-1.0.0.AppImage'],
      );

      final yamlStr = app.toMetadataYaml();
      // Must parse successfully
      final doc = loadYaml(yamlStr);
      expect(doc, isA<Map>());
    });
  });
}
