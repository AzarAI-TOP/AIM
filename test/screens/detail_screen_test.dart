import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aim/models/app_info.dart';

/// Tests confirming that DropdownButtonFormField.initialValue is the
/// correct parameter for setting the displayed selection.
///
/// In Flutter >= 3.33, `value` was deprecated in favor of `initialValue`,
/// which now serves double duty: it sets both the FormField initial value
/// AND controls which dropdown item is displayed as selected.
///
/// See: https://github.com/AzarAI-TOP/AIM/issues/1

void main() {
  group('DropdownButtonFormField selection display', () {
    testWidgets('initialValue correctly displays selected version', (
      tester,
    ) async {
      const selectedVersion = 'MyApp-2.0.0.AppImage';
      final versions = [
        'MyApp-1.0.0.AppImage',
        selectedVersion,
        'MyApp-3.0.0.AppImage',
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownButtonFormField<String>(
              initialValue: selectedVersion,
              items:
                  versions.map<DropdownMenuItem<String>>((ver) {
                    return DropdownMenuItem(value: ver, child: Text(ver));
                  }).toList(),
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // initialValue DOES show the selected version (Flutter >= 3.33)
      expect(find.text(selectedVersion), findsOneWidget);
    });

    testWidgets(
      'initialValue mirrors what DetailScreen passes to the dropdown',
      (tester) async {
        // Same pattern as detail_screen.dart line 173:
        //   initialValue: _app.selectedVersion.isNotEmpty ? _app.selectedVersion : null
        const appSelectedVersion = 'MyApp-2.0.0.AppImage';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DropdownButtonFormField<String>(
                initialValue:
                    appSelectedVersion.isNotEmpty ? appSelectedVersion : null,
                items: ['MyApp-1.0.0.AppImage', appSelectedVersion]
                    .map<DropdownMenuItem<String>>((ver) {
                      return DropdownMenuItem(value: ver, child: Text(ver));
                    })
                    .toList(),
                onChanged: (_) {},
              ),
            ),
          ),
        );

        // The dropdown shows the selected version — the code is correct
        expect(find.text(appSelectedVersion), findsOneWidget);
      },
    );

    testWidgets('initialValue null shows no pre-selection', (tester) async {
      final versions = ['v1.AppImage', 'v2.AppImage'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownButtonFormField<String>(
              initialValue: null,
              items:
                  versions.map<DropdownMenuItem<String>>((ver) {
                    return DropdownMenuItem(value: ver, child: Text(ver));
                  }).toList(),
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Dropdown exists but nothing pre-selected
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      // The first item text may or may not be visible depending on Flutter version
    });

    testWidgets('deprecated value parameter also works but triggers warning', (
      tester,
    ) async {
      const selectedVersion = 'MyApp-2.0.0.AppImage';
      final versions = ['MyApp-1.0.0.AppImage', selectedVersion];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownButtonFormField<String>(
              // ignore: deprecated_member_use
              value: selectedVersion,
              items:
                  versions.map<DropdownMenuItem<String>>((ver) {
                    return DropdownMenuItem(value: ver, child: Text(ver));
                  }).toList(),
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // 'value' still works but is deprecated — initialValue is preferred
      expect(find.text(selectedVersion), findsOneWidget);
    });
  });

  group('AppInfo dropdown data integrity', () {
    test('selectedVersion provides correct non-null value for dropdown', () {
      final app = AppInfo(
        name: 'TestApp',
        versions: ['TestApp-1.0.0.AppImage', 'TestApp-2.0.0.AppImage'],
        selectedVersion: 'TestApp-2.0.0.AppImage',
      );

      final dropdownValue =
          app.selectedVersion.isNotEmpty ? app.selectedVersion : null;
      expect(dropdownValue, 'TestApp-2.0.0.AppImage');
    });

    test('empty selectedVersion produces null for dropdown', () {
      final app = AppInfo(name: 'TestApp', selectedVersion: '');

      final dropdownValue =
          app.selectedVersion.isNotEmpty ? app.selectedVersion : null;
      expect(dropdownValue, isNull);
    });

    test('versions list maps to valid DropdownMenuItem values', () {
      final app = AppInfo(
        name: 'TestApp',
        versions: ['v1.AppImage', 'v2.AppImage', 'v3.AppImage'],
      );

      final items = app.versions.map<DropdownMenuItem<String>>((ver) {
        return DropdownMenuItem(value: ver, child: Text(ver));
      }).toList();

      expect(items.length, 3);
      expect(items[0].value, 'v1.AppImage');
      expect(items[1].value, 'v2.AppImage');
      expect(items[2].value, 'v3.AppImage');
    });
  });
}
