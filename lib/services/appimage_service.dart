import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import '../models/app_info.dart';
import 'icon_extract_service.dart';

class AppImageService {
  final String basePath;

  AppImageService() : basePath = '${Platform.environment['HOME']}/AppImages';

  Future<List<AppInfo>> loadApps() async {
    final List<AppInfo> apps = [];
    final dir = Directory(basePath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      return apps;
    }

    await for (var entity in dir.list()) {
      if (entity is Directory) {
        final appName = p.basename(entity.path);
        final metadataFile = File('${entity.path}/metadata.yaml');

        if (await metadataFile.exists()) {
          apps.add(await _loadFromMetadata(appName, metadataFile));
        } else {
          apps.add(await _migrateFromDirScan(appName, entity, metadataFile));
        }
      }
    }

    return apps;
  }

  Future<AppInfo> _loadFromMetadata(String appName, File metadataFile) async {
    final yamlString = await metadataFile.readAsString();
    final doc = loadYaml(yamlString);
    if (doc is! Map) {
      throw Exception("Invalid metadata.yaml for '$appName'");
    }
    return AppInfo.fromMetadataMap(appName, doc);
  }

  Future<AppInfo> _migrateFromDirScan(
    String appName,
    Directory dir,
    File metadataFile,
  ) async {
    final versions = <String>[];
    String iconPath = '';

    await for (var file in dir.list()) {
      if (file is File && file.path.endsWith('.AppImage')) {
        final fileName = p.basename(file.path);
        versions.add(fileName);
        if (iconPath.isEmpty) iconPath = file.path;
      }
    }

    String description = '';
    final descFile = File('${dir.path}/.description');
    if (await descFile.exists()) {
      description = await descFile.readAsString();
    }

    final app = AppInfo(
      name: appName,
      iconPath: iconPath,
      description: description,
      versions: versions,
      selectedVersion: versions.isNotEmpty ? versions.first : '',
    );

    await metadataFile.writeAsString(app.toMetadataYaml());

    return app;
  }

  Future<void> addAppImage(String sourcePath) async {
    final file = File(sourcePath);
    if (!await file.exists()) throw Exception("添加的AppImage文件不存在");

    final fileName = p.basename(file.path);
    final nameWithoutExt = fileName.endsWith('.AppImage')
        ? fileName.substring(0, fileName.length - 9)
        : p.basenameWithoutExtension(fileName);
    final baseName = nameWithoutExt.split('-').first;

    final targetDir = Directory('$basePath/$baseName');
    if (!await targetDir.exists()) await targetDir.create(recursive: true);

    final targetPath = '${targetDir.path}/$fileName';
    await file.copy(targetPath);

    final metadataFile = File('${targetDir.path}/metadata.yaml');
    final AppInfo existingApp;
    if (await metadataFile.exists()) {
      final yamlString = await metadataFile.readAsString();
      final doc = loadYaml(yamlString);
      if (doc is! Map) throw Exception("Invalid metadata.yaml for '$baseName'");
      existingApp = AppInfo.fromMetadataMap(baseName, doc);
    } else {
      existingApp = await _migrateFromDirScan(baseName, targetDir, metadataFile);
    }

    // Use copyWith to add the new version immutably
    final updatedVersions = List<String>.from(existingApp.versions);
    if (!updatedVersions.contains(fileName)) {
      updatedVersions.add(fileName);
    }
    final selectedVersion = existingApp.selectedVersion.isEmpty
        ? updatedVersions.first
        : existingApp.selectedVersion;

    final extractedIcon = await IconExtractService.extractIcon(targetPath, targetDir.path);
    final iconPath = extractedIcon ??
        (existingApp.iconPath.isNotEmpty ? existingApp.iconPath : targetPath);

    final app = existingApp.copyWith(
      versions: updatedVersions,
      selectedVersion: selectedVersion,
      iconPath: iconPath,
    );

    await metadataFile.writeAsString(app.toMetadataYaml());
  }

  Future<void> deletePackage(AppInfo app) async {
    final dir = Directory(app.packageDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  Future<void> saveMetadata(AppInfo app) async {
    final dir = Directory(app.packageDir);
    if (!await dir.exists()) await dir.create(recursive: true);
    final metadataFile = File('${app.packageDir}/metadata.yaml');
    await metadataFile.writeAsString(app.toMetadataYaml());
  }
}
