import 'package:flutter_test/flutter_test.dart';
import 'package:aim/models/app_info.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('AppInfo.fromMetadataMap', () {
    test('parses typed Map<String, dynamic> correctly', () {
      final map = <String, dynamic>{
        'name': 'TestApp',
        'description': 'A test application',
        'generateLink': true,
        'generateDesktopFile': true,
        'selectedVersion': 'TestApp-2.0.0.AppImage',
        'iconPath': '/home/user/AppImages/TestApp/icon.png',
        'versions': ['TestApp-1.0.0.AppImage', 'TestApp-2.0.0.AppImage'],
      };

      final app = AppInfo.fromMetadataMap('TestApp', map);

      expect(app.name, 'TestApp');
      expect(app.description, 'A test application');
      expect(app.generateLink, true);
      expect(app.generateDesktopFile, true);
      expect(app.selectedVersion, 'TestApp-2.0.0.AppImage');
      expect(app.iconPath, '/home/user/AppImages/TestApp/icon.png');
      expect(app.versions, ['TestApp-1.0.0.AppImage', 'TestApp-2.0.0.AppImage']);
    });

    test('parses untyped Map<dynamic, dynamic> correctly (YamlMap scenario)', () {
      // This simulates what loadYaml() returns — keys and values can be dynamic
      final map = <dynamic, dynamic>{
        'name': 'TestApp',
        'description': 'A test app',
        'generateLink': true,
        'generateDesktopFile': true,
        'selectedVersion': 'TestApp-1.0.0.AppImage',
        'versions': <dynamic>['TestApp-1.0.0.AppImage'],
      };

      final app = AppInfo.fromMetadataMap('TestApp', map);

      expect(app.name, 'TestApp');
      expect(app.description, 'A test app');
      expect(app.generateLink, true);
      expect(app.generateDesktopFile, true);
      expect(app.selectedVersion, 'TestApp-1.0.0.AppImage');
      expect(app.versions, ['TestApp-1.0.0.AppImage']);
    });

    test('handles missing optional fields with defaults', () {
      final map = <String, dynamic>{
        'name': 'MinimalApp',
      };

      final app = AppInfo.fromMetadataMap('MinimalApp', map);

      expect(app.name, 'MinimalApp');
      expect(app.description, '');
      expect(app.iconPath, '');
      expect(app.versions, isEmpty);
      expect(app.selectedVersion, '');
      expect(app.generateLink, false);
      expect(app.generateDesktopFile, true); // default true
    });

    test('handles generateDesktopFile explicitly set to false', () {
      final map = <String, dynamic>{
        'name': 'NoDesktopApp',
        'generateDesktopFile': false,
      };

      final app = AppInfo.fromMetadataMap('NoDesktopApp', map);

      expect(app.generateDesktopFile, false);
    });

    test('handles null selectedVersion by defaulting to first version', () {
      final map = <String, dynamic>{
        'name': 'App',
        'versions': ['v1.AppImage', 'v2.AppImage'],
      };

      final app = AppInfo.fromMetadataMap('App', map);

      expect(app.selectedVersion, 'v1.AppImage');
    });

    test('handles empty string selectedVersion by defaulting to first version', () {
      final map = <String, dynamic>{
        'name': 'App',
        'versions': ['v1.AppImage', 'v2.AppImage'],
        'selectedVersion': '',
      };

      final app = AppInfo.fromMetadataMap('App', map);

      expect(app.selectedVersion, 'v1.AppImage');
    });

    test('handles generateLink from various truthy/falsy sources', () {
      // Only explicit true should set generateLink to true
      final trueMap = <String, dynamic>{'name': 'App', 'generateLink': true};
      expect(AppInfo.fromMetadataMap('App', trueMap).generateLink, true);

      // null / absent should be false
      final absentMap = <String, dynamic>{'name': 'App'};
      expect(AppInfo.fromMetadataMap('App', absentMap).generateLink, false);
    });

    test('handles YamlList for versions field', () {
      final yamlStr = '''
name: YamlApp
versions:
  - v1.AppImage
  - v2.AppImage
  - v3.AppImage
''';
      final doc = loadYaml(yamlStr) as Map;

      final app = AppInfo.fromMetadataMap('YamlApp', doc);

      expect(app.versions.length, 3);
      expect(app.versions[0], 'v1.AppImage');
      expect(app.versions[1], 'v2.AppImage');
      expect(app.versions[2], 'v3.AppImage');
    });

    test('handles non-YamlList iterable for versions gracefully', () {
      final map = <String, dynamic>{
        'name': 'App',
        'versions': ['v1.AppImage', 'v2.AppImage'],
      };

      final app = AppInfo.fromMetadataMap('App', map);

      expect(app.versions, ['v1.AppImage', 'v2.AppImage']);
    });
  });

  group('AppInfo.toMetadataYaml round-trip', () {
    test('serializes and deserializes back to equivalent AppInfo', () {
      final original = AppInfo(
        name: 'RoundTrip',
        description: 'Testing round trip',
        versions: ['RoundTrip-1.0.0.AppImage', 'RoundTrip-2.0.0.AppImage'],
        selectedVersion: 'RoundTrip-2.0.0.AppImage',
        generateLink: true,
        generateDesktopFile: true,
        iconPath: '/some/path/icon.png',
      );

      final yamlStr = original.toMetadataYaml();
      final doc = loadYaml(yamlStr) as Map;
      final restored = AppInfo.fromMetadataMap('RoundTrip', doc);

      expect(restored.name, original.name);
      expect(restored.description, original.description);
      expect(restored.versions, original.versions);
      expect(restored.selectedVersion, original.selectedVersion);
      expect(restored.generateLink, original.generateLink);
      expect(restored.generateDesktopFile, original.generateDesktopFile);
      expect(restored.iconPath, original.iconPath);
    });

    test('round-trip preserves empty fields', () {
      final original = AppInfo(name: 'Empty');

      final yamlStr = original.toMetadataYaml();
      final doc = loadYaml(yamlStr) as Map;
      final restored = AppInfo.fromMetadataMap('Empty', doc);

      expect(restored.name, 'Empty');
      expect(restored.description, '');
      expect(restored.versions, isEmpty);
      expect(restored.selectedVersion, '');
    });

    test('round-trip with special characters in description', () {
      final original = AppInfo(
        name: 'Special',
        description: 'Contains: colon, # hash, & ampersand',
      );

      final yamlStr = original.toMetadataYaml();
      final doc = loadYaml(yamlStr) as Map;
      final restored = AppInfo.fromMetadataMap('Special', doc);

      expect(restored.description, 'Contains: colon, # hash, & ampersand');
    });
  });

  group('AppInfo YAML value escaping', () {
    test('escapes values containing colon', () {
      final app = AppInfo(name: 'App', description: 'Key: value');
      final yaml = app.toMetadataYaml();
      expect(yaml, contains("description: 'Key: value'"));
    });

    test('escapes values containing hash', () {
      final app = AppInfo(name: 'App', description: 'Not a # comment');
      final yaml = app.toMetadataYaml();
      expect(yaml, contains("description: 'Not a # comment'"));
    });

    test('escapes values containing leading dash', () {
      final app = AppInfo(name: 'App', description: '- bullet point');
      final yaml = app.toMetadataYaml();
      expect(yaml, contains("description: '- bullet point'"));
    });

    test('escapes values with single quotes by doubling them', () {
      final app = AppInfo(name: 'App', description: "It's working");
      final yaml = app.toMetadataYaml();
      expect(yaml, contains("description: 'It''s working'"));
    });

    test('does not quote simple values', () {
      final app = AppInfo(name: 'App', description: 'Simple description');
      final yaml = app.toMetadataYaml();
      expect(yaml, contains('description: Simple description'));
    });
  });

  group('AppInfo computed getters', () {
    test('packageDir returns correct path', () {
      final app = AppInfo(name: 'MyApp');
      expect(app.packageDir, endsWith('/AppImages/MyApp'));
    });

    test('selectedFilePath returns correct path', () {
      final app = AppInfo(
        name: 'MyApp',
        versions: ['MyApp-1.0.0.AppImage'],
        selectedVersion: 'MyApp-1.0.0.AppImage',
      );
      expect(app.selectedFilePath, endsWith('/AppImages/MyApp/MyApp-1.0.0.AppImage'));
    });

    test('selectedFilePath returns empty string when no version selected', () {
      final app = AppInfo(name: 'MyApp');
      expect(app.selectedFilePath, '');
    });
  });

  group('AppInfo constructor', () {
    test('defaults selectedVersion to first version when not provided', () {
      final app = AppInfo(
        name: 'App',
        versions: ['v2.AppImage', 'v1.AppImage'],
      );
      expect(app.selectedVersion, 'v2.AppImage');
    });

    test('defaults selectedVersion to empty when no versions', () {
      final app = AppInfo(name: 'App');
      expect(app.selectedVersion, '');
    });

    test('accepts explicit selectedVersion', () {
      final app = AppInfo(
        name: 'App',
        versions: ['v1.AppImage', 'v2.AppImage'],
        selectedVersion: 'v2.AppImage',
      );
      expect(app.selectedVersion, 'v2.AppImage');
    });
  });
}
