import 'dart:io';
import 'package:yaml/yaml.dart';

class AppInfo {
  String name;
  String iconPath;
  String description;
  List<String> versions;
  String selectedVersion;
  bool generateLink;
  bool generateDesktopFile;

  AppInfo({
    required this.name,
    this.iconPath = '',
    this.description = '',
    List<String>? versions,
    String? selectedVersion,
    this.generateLink = false,
    this.generateDesktopFile = true,
  }) : versions = versions ?? [],
       selectedVersion = selectedVersion ?? (versions?.isNotEmpty == true ? versions!.first : '');

  String get packageDir {
    final home = Platform.environment['HOME']!;
    return '$home/AppImages/$name';
  }

  String get selectedFilePath {
    if (selectedVersion.isEmpty) return '';
    return '$packageDir/$selectedVersion';
  }

  String toMetadataYaml() {
    final buf = StringBuffer();
    buf.writeln('name: $name');
    buf.writeln('description: ${_escapeYamlValue(description)}');
    buf.writeln('generateLink: $generateLink');
    buf.writeln('generateDesktopFile: $generateDesktopFile');
    buf.writeln('selectedVersion: ${_escapeYamlValue(selectedVersion)}');
    if (iconPath.isNotEmpty) {
      buf.writeln('iconPath: ${_escapeYamlValue(iconPath)}');
    }
    buf.writeln('versions:');
    for (var v in versions) {
      buf.writeln('  - ${_escapeYamlValue(v)}');
    }
    return buf.toString();
  }

  factory AppInfo.fromMetadataMap(String appName, Map map) {
    final versions = <String>[];
    if (map['versions'] is YamlList) {
      for (var v in (map['versions'] as YamlList)) {
        versions.add(v.toString());
      }
    }

    final yamlSelected = map['selectedVersion']?.toString();
    final selectedVersion = (yamlSelected != null && yamlSelected.isNotEmpty)
        ? yamlSelected
        : (versions.isNotEmpty ? versions.first : '');

    return AppInfo(
      name: appName,
      description: map['description']?.toString() ?? '',
      iconPath: map['iconPath']?.toString() ?? '',
      versions: versions,
      selectedVersion: selectedVersion,
      generateLink: map['generateLink'] == true,
      generateDesktopFile: map['generateDesktopFile'] ?? true,
    );
  }

  static String _escapeYamlValue(String value) {
    if (value.isEmpty) return "''";
    final needsQuoting = value.contains(':') ||
        value.contains('#') ||
        value.contains('&') ||
        value.contains('*') ||
        value.contains('!') ||
        value.contains('|') ||
        value.contains('>') ||
        value.contains('%') ||
        value.contains('@') ||
        value.contains('`') ||
        value.contains('"') ||
        value.contains("'") ||
        value.contains('{') ||
        value.contains('}') ||
        value.contains('[') ||
        value.contains(']') ||
        value.contains(',') ||
        value.startsWith(' ') ||
        value.endsWith(' ') ||
        value.startsWith('-') ||
        value.startsWith('?') ||
        value.contains('\n');
    if (needsQuoting) {
      return "'${value.replaceAll("'", "''")}'";
    }
    return value;
  }
}
