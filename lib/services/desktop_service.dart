import 'dart:io';
import '../models/app_info.dart';

class DesktopService {
  final String applicationsDir;
  final String binDir;

  DesktopService()
    : applicationsDir =
          '${Platform.environment['HOME']}/.local/share/applications',
      binDir = '${Platform.environment['HOME']}/.local/bin';

  Future<void> createDesktopEntry(AppInfo app) async {
    if (app.selectedVersion.isEmpty) return;

    final dir = Directory(applicationsDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final desktopFilePath = '$applicationsDir/${app.name}.desktop';
    final file = File(desktopFilePath);

    final iconPath = app.iconPath;

    final content =
        '[Desktop Entry]\n'
        'Name=${app.name}\n'
        'Comment=${app.description}\n'
        'Exec=${app.selectedFilePath}\n'
        'Icon=$iconPath\n'
        'Terminal=false\n'
        'Type=Application\n'
        'Categories=Utility;\n';

    await file.writeAsString(content);
  }

  Future<void> removeDesktopEntry(AppInfo app) async {
    final desktopFile = File('$applicationsDir/${app.name}.desktop');
    if (await desktopFile.exists()) {
      await desktopFile.delete();
    }
  }

  Future<void> updateBinLink(AppInfo app) async {
    final linkPath = '$binDir/${app.name.toLowerCase()}';
    final linkFile = File(linkPath);
    final targetFile = File(app.selectedFilePath);

    if (await linkFile.exists()) await linkFile.delete();

    if (app.generateLink && app.selectedVersion.isNotEmpty) {
      final dir = Directory(binDir);
      if (!await dir.exists()) await dir.create(recursive: true);

      await Link(linkPath).create(targetFile.path);
    }
  }
}
