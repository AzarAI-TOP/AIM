import 'dart:convert';

import '../aim_command.dart';
import '../cli_context.dart';
import '../terminal.dart';

class InfoCommand extends AimCommand {
  InfoCommand(super.ctx) {
    addJsonFlag();
  }

  @override
  String get name => 'info';

  @override
  String get description => 'Show detailed information about an application.';

  @override
  List<String> get aliases => ['view'];

  @override
  String get invocation => 'aim info <name>';

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.isEmpty) {
      throw CliError('No app specified. Usage: $invocation');
    }
    final name = rest.first;
    final app = await ctx.findApp(name);
    if (app == null) {
      throw CliError("No app named '$name'. Run 'aim list' to see managed apps.");
    }

    if (jsonOutput) {
      ctx.term.out(const JsonEncoder.withIndent('  ').convert({
        'name': app.name,
        'description': app.description,
        'iconPath': app.iconPath,
        'selectedVersion': app.selectedVersion,
        'selectedFilePath': app.selectedFilePath,
        'packageDir': app.packageDir,
        'versions': app.versions,
        'generateLink': app.generateLink,
        'generateDesktopFile': app.generateDesktopFile,
      }));
      return 0;
    }

    final t = ctx.term;
    t.out(t.bold(app.name));
    if (app.description.isNotEmpty) t.out(t.gray(app.description));
    t.out('');
    _field(t, 'Active version', app.selectedVersion.isEmpty ? '-' : app.selectedVersion);
    _field(t, 'Executable', app.selectedFilePath.isEmpty ? '-' : app.selectedFilePath);
    _field(t, 'Package dir', app.packageDir);
    _field(t, 'Bin link', app.generateLink ? 'on' : 'off');
    _field(t, 'Desktop entry', app.generateDesktopFile ? 'on' : 'off');
    t.out('');
    t.out(t.bold('Versions (${app.versions.length}):'));
    for (final v in app.versions) {
      final active = v == app.selectedVersion;
      t.out('  ${active ? t.green('●') : t.gray('○')} $v');
    }
    return 0;
  }

  void _field(Terminal t, String label, String value) {
    t.out('${t.gray('${label.padRight(15)}:')} $value');
  }
}
