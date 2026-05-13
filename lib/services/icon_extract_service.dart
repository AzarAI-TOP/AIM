import 'dart:io';
import 'package:path/path.dart' as p;

class IconExtractService {
  IconExtractService._();

  static const _iconFileName = 'icon.png';

  /// Extract the icon from [appimagePath] into [packageDir]/icon.png.
  /// Returns the path to the extracted icon file, or null if extraction fails.
  /// Skips extraction when the icon already exists in the package directory.
  static Future<String?> extractIcon(String appimagePath, String packageDir) async {
    final iconFile = File(p.join(packageDir, _iconFileName));
    if (await iconFile.exists()) return iconFile.path;

    final file = File(appimagePath);
    if (!await file.exists()) return null;
    if (!await _isValidAppImageType2(file)) return null;

    await Process.run('chmod', ['+x', appimagePath]);

    final tempDir = await Directory.systemTemp.createTemp('aim_icon_');
    try {
      final result = await Process.run(
        appimagePath,
        ['--appimage-extract'],
        workingDirectory: tempDir.path,
      );
      if (result.exitCode != 0) return null;

      final root = Directory(p.join(tempDir.path, 'squashfs-root'));
      if (!await root.exists()) return null;

      final iconName = await _parseIconName(root);
      if (iconName == null) return null;

      final real = await _findIconFile(root, iconName);
      if (real == null) return null;

      await Directory(packageDir).create(recursive: true);
      await real.copy(iconFile.path);
      return iconFile.path;
    } catch (_) {
      return null;
    } finally {
      await tempDir.delete(recursive: true);
    }
  }

  static Future<bool> _isValidAppImageType2(File file) async {
    final raf = await file.open(mode: FileMode.read);
    try {
      await raf.setPosition(8);
      final bytes = await raf.read(3);
      return bytes.length == 3 &&
          bytes[0] == 0x41 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x02;
    } finally {
      await raf.close();
    }
  }

  static Future<String?> _parseIconName(Directory root) async {
    final desktopFiles = await root
        .list()
        .where((e) => e is File && e.path.endsWith('.desktop'))
        .cast<File>()
        .toList();

    if (desktopFiles.isEmpty) return null;

    for (var file in desktopFiles) {
      final lines = await file.readAsLines();
      var inSection = false;

      for (var line in lines) {
        final trimmed = line.trim();
        if (trimmed == '[Desktop Entry]') {
          inSection = true;
          continue;
        }
        if (trimmed.startsWith('[') && inSection) break;
        if (inSection && trimmed.startsWith('Icon=')) {
          final value = trimmed.substring(5).trim();
          if (value.isNotEmpty) return value;
        }
      }
    }

    return null;
  }

  static Future<File?> _findIconFile(Directory root, String iconName) async {
    for (var ext in ['png', 'svg', 'xpm']) {
      final linkPath = p.join(root.path, '$iconName.$ext');
      final file = await _resolveSymlink(linkPath, root.path);
      if (file != null) return file;
    }
    return null;
  }

  static Future<File?> _resolveSymlink(String linkPath, String rootPath) async {
    final type = await FileSystemEntity.type(linkPath, followLinks: false);

    if (type == FileSystemEntityType.file) return File(linkPath);

    if (type == FileSystemEntityType.link) {
      final target = await Link(linkPath).target();
      final realPath = p.isAbsolute(target) ? target : p.join(rootPath, target);
      final real = File(realPath);
      if (await real.exists()) return real;
    }

    return null;
  }
}
