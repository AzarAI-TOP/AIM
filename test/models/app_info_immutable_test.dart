import 'package:flutter_test/flutter_test.dart';
import 'package:aim/models/app_info.dart';

void main() {
  group('AppInfo immutability', () {
    test('copyWith creates new instance with updated fields', () {
      final original = AppInfo(
        name: 'Original',
        description: 'Original description',
        versions: ['v1.AppImage', 'v2.AppImage'],
        selectedVersion: 'v1.AppImage',
        generateLink: false,
        generateDesktopFile: true,
        iconPath: '/path/to/icon.png',
      );

      final updated = original.copyWith(
        description: 'Updated description',
        generateLink: true,
        selectedVersion: 'v2.AppImage',
      );

      // Updated fields reflect new values
      expect(updated.description, 'Updated description');
      expect(updated.generateLink, true);
      expect(updated.selectedVersion, 'v2.AppImage');

      // Unchanged fields preserved
      expect(updated.name, 'Original');
      expect(updated.versions, ['v1.AppImage', 'v2.AppImage']);
      expect(updated.generateDesktopFile, true);
      expect(updated.iconPath, '/path/to/icon.png');

      // Original is unchanged (immutability)
      expect(original.description, 'Original description');
      expect(original.generateLink, false);
      expect(original.selectedVersion, 'v1.AppImage');
    });

    test('copyWith with no arguments returns equal but distinct instance', () {
      final original = AppInfo(
        name: 'Test',
        description: 'Desc',
        versions: ['v1.AppImage'],
      );

      final copy = original.copyWith();

      expect(copy.name, original.name);
      expect(copy.description, original.description);
      expect(copy.versions, original.versions);
      expect(identical(copy, original), false);
    });

    test('copyWith can clear optional fields', () {
      final original = AppInfo(
        name: 'Test',
        description: 'Has description',
        iconPath: '/some/icon.png',
      );

      final cleared = original.copyWith(description: '', iconPath: '');

      expect(cleared.description, '');
      expect(cleared.iconPath, '');
    });

    test('copyWith chaining works correctly', () {
      final app = AppInfo(name: 'Chain');

      final result = app
          .copyWith(description: 'Step 1')
          .copyWith(generateLink: true)
          .copyWith(selectedVersion: 'v2.AppImage');

      expect(result.description, 'Step 1');
      expect(result.generateLink, true);
      expect(result.selectedVersion, 'v2.AppImage');
    });

    test('copyWith preserves versions list integrity', () {
      final original = AppInfo(
        name: 'App',
        versions: ['v1.AppImage', 'v2.AppImage', 'v3.AppImage'],
      );

      final updated = original.copyWith(selectedVersion: 'v2.AppImage');

      expect(updated.versions.length, 3);
      expect(updated.versions, ['v1.AppImage', 'v2.AppImage', 'v3.AppImage']);
    });

    test('copyWith sets generateDesktopFile correctly', () {
      // Default is true, can be set to false
      final withDesktop = AppInfo(name: 'App', generateDesktopFile: true);
      expect(withDesktop.generateDesktopFile, true);

      final withoutDesktop = withDesktop.copyWith(generateDesktopFile: false);
      expect(withoutDesktop.generateDesktopFile, false);
      expect(withDesktop.generateDesktopFile, true); // original unchanged
    });
  });

  group('AppInfo data flow safety', () {
    test('modifying a copyWith result does not affect the original', () {
      final original = AppInfo(
        name: 'Safe',
        description: 'Original',
        versions: ['v1.AppImage'],
        selectedVersion: 'v1.AppImage',
      );

      // Simulate what DetailScreen does: copy, modify, return
      final modified = original.copyWith(
        description: 'Modified by detail screen',
        generateLink: true,
      );

      // Original must be untouched
      expect(original.description, 'Original');
      expect(original.generateLink, false);

      // Modified has new values
      expect(modified.description, 'Modified by detail screen');
      expect(modified.generateLink, true);
    });

    test('home screen pattern: replace app in list with returned copy', () {
      final apps = [
        AppInfo(name: 'App A', description: 'Desc A'),
        AppInfo(name: 'App B', description: 'Desc B'),
        AppInfo(name: 'App C', description: 'Desc C'),
      ];

      // Simulate DetailScreen returning updated App B
      final returned = apps[1].copyWith(description: 'Updated B');

      // HomeScreen replaces in list
      final updatedApps = List<AppInfo>.from(apps);
      updatedApps[1] = returned;

      // App B is updated
      expect(updatedApps[1].description, 'Updated B');

      // Other apps unchanged
      expect(updatedApps[0].description, 'Desc A');
      expect(updatedApps[2].description, 'Desc C');

      // Original list unchanged
      expect(apps[1].description, 'Desc B');
    });
  });

  group('AppInfo versions management via copyWith', () {
    test('copyWith can add a new version to the list', () {
      final original = AppInfo(
        name: 'App',
        versions: ['v1.AppImage'],
        selectedVersion: 'v1.AppImage',
      );

      final updated = original.copyWith(
        versions: [...original.versions, 'v2.AppImage'],
        selectedVersion: 'v2.AppImage',
      );

      expect(updated.versions, ['v1.AppImage', 'v2.AppImage']);
      expect(updated.selectedVersion, 'v2.AppImage');
      expect(original.versions, ['v1.AppImage']); // original unchanged
    });

    test('copyWith preserves selectedVersion when adding version', () {
      final original = AppInfo(
        name: 'App',
        versions: ['v1.AppImage'],
        selectedVersion: 'v1.AppImage',
      );

      final updated = original.copyWith(
        versions: [...original.versions, 'v2.AppImage'],
      );

      expect(updated.selectedVersion, 'v1.AppImage'); // preserved
    });
  });
}
